use util

unit.end_turn =
| $ap <= $movement
| $handled <= 0

world.end_turn =
| for U $active: U.end_turn
| $player++
| when $player >< $players.size:
  | $player <= 0
  | $turn++
| $players.$player.new_turn
