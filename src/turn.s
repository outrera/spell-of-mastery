use util

unit.end_turn =
| $ap <= $movement
| $handled <= 0

world.new_turn =
| Units = $active.list
| Turn = $turn
| for U Units: less U.removed:
  | less U.empty: when U.class.hp>0:
    | for V $units_get{U.xyz}: less V.effects.end:
      | V.run_effects{(X=>case X [`.`tenant_turn N] Turn%N><0) U U.xyz}
  | U.run_effects{(X=>case X [`.`turn N] Turn%N><0) U U.xyz}

world.end_turn =
| for U $active: U.end_turn
| $player++
| when $player >< $players.size:
  | $player <= 0
  | $turn++
  | $new_turn
| $players.$player.new_turn
