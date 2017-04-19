use util

unit.new_turn =
| $ap <= $movement

world.new_turn =
| for U $active: U.new_turn
| $turn++ 