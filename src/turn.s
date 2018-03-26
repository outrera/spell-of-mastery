use util

unit.new_turn =
| Remove = 0
| RunEs = []
| for E $genes: when E.amount>0:
  | E.amount--
  | less E.amount > 0:
    | when E.when >< timeout: push [E.name E.params.unheap] RunEs
    | Remove <= 1
    | E.amount <= No
| when Remove: $strip{?amount><No} //strip genes with zero duration
| for Name,Params RunEs: $run_gene{Name Params Me $xyz}
| $mov <= $class.mov
| $fatigue <= max 0: min $fatigue-$stamina $mov-1
| $will <= $class.will

unit.end_turn =
| Resting = $def >< $class.def and not $engaged
| when $threatened: $engaged <= 1 //ended its turn near enemy?
| less $engaged:
  | DefInc = max 0: min $moves $class.def-$def
  | $def += DefInc
  | $mov -= DefInc
| when $charging:
  | CAct, Charge, CCost, TId = $get{charge}
  | CInc = min $will CCost-Charge
  | Charge += CInc
  | $set{charge [CAct Charge CCost TId]}
| when not $empty and $class.hp>0:
  | for V $world.units_get{$xyz}: V.run_genes{tenant_endturn}
| $run_genes{endturn}
| $resting <= Resting
| $handled <= 0
| $engaged <= 0

world.new_turn =

EndTurnLoop = 0
player.new_turn =
| less $total_units:
  | if EndTurnLoop++ > 16
    then | say "caught in end turn loop"
    else | $world.end_turn //no units, skip his turn
         | leave
| EndTurnLoop <= 0
| say "[$name] ([$color]) begins turn [$world.turn]"
| for U $units: U.new_turn

player.end_turn =
| for U $units: U.end_turn

world.end_turn =
| $players.$player.end_turn
| $player++
| when $player >< $players.size:
  | $player <= 0
  | $turn++
  | $new_turn
| $players.$player.new_turn
