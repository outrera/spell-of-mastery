use util

unit.new_turn =

unit.end_turn =
| Turn = $world.turn
| $steps <= $class.steps
| when not $empty and $class.hp>0:
  | for V $world.units_get{$xyz}: V.run_genes{tenant_endturn}
| $run_genes{endturn}
| $safe <= 1
| $handled <= 0
| Remove = 0
| RunEs = []
| for E $genes: when E.amount>0:
  | E.amount--
  | less E.amount > 0:
    | when E.when >< timeout: push [E.name E.params.unheap] RunEs
    | Remove <= 1
    | E.amount <= No
| when Remove: $strip_gene{?amount><No} //strip genes with zero duration
| for Name,Params RunEs: $run_gene{Name Params Me $xyz}


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
