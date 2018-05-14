use util

unit.new_turn =
| Remove = 0
| RunEs = []
| for E $genes: when E.amount>0:
  | E.amount--
  | less E.amount > 0:
    | when E.when >< timeout: push [E.name E.data.unheap] RunEs
    | Remove <= 1
    | E.amount <= No
| when Remove: $strip{?amount><No} //strip genes with zero duration
| for Name,Data RunEs: $run_gene{Name Data Me $xyz}
| $mov <= $class.mov
| $fatigue <= max 0: min $fatigue-$stamina $mov-1
| when $will < $class.will: $will <= $class.will

unit.end_turn_invisibility_check =
| less $invisible: leave
| for E $nearby_enemies_at{$xyz}
  | when E.infov{$xyz}:
    | $strip{invisible}
    | leave

unit.end_turn =
| $end_turn_invisibility_check
| Resting = $def >< $class.def and not $engaged
| when $threatened: $engaged <= 1 //ended its turn near enemy?
| less $engaged:
  | DefInc = max 0: min $moves $class.def-$def
  | $def += DefInc
  | $mov -= DefInc
| when $ai><unit:
  | for V $site.units_get{$xyz}: V.run_genes{tenant_endturn}
| $run_genes{endturn}
| $resting <= Resting
| $handled <= 0
| $engaged <= 0

site.new_turn =

EndTurnLoop = 0
player.new_turn =
| less $total_units:
  | if EndTurnLoop++ > 16
    then | say "caught in end turn loop"
    else | $site.end_turn //no units, skip his turn
         | leave
| EndTurnLoop <= 0
| say "[$name] ([$color]) begins turn [$site.turn]"
| for U $units: U.new_turn

player.end_turn =
| for U $units: U.end_turn

site.end_turn =
| $last_picked <= 0
| $players.$player.end_turn
| $player++
| when $player >< $players.size:
  | $player <= 0
  | $turn++
  | $new_turn
| $players.$player.new_turn
