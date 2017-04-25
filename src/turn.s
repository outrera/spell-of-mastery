use util

unit.end_turn =
| $steps <= $class.steps
| $handled <= 0

unit.new_turn =
| Turn = $world.turn
| when not $empty and $class.hp>0:
  | for V $world.units_get{$xyz}: less V.effects.end:
    | V.run_effects{(X=>case X [`.`tenant_turn N] Turn%N><0) Me $xyz}
| $run_effects{(X=>case X [`.`turn N] Turn%N><0) Me $xyz}

world.new_turn =
| for U $active.list: less U.removed: U.new_turn

world.end_turn =
| for U $active: U.end_turn
| $player++
| when $player >< $players.size:
  | $player <= 0
  | $turn++
  | $new_turn
| $players.$player.new_turn
