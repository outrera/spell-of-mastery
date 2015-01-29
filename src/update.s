// game world update routines


main.update =
| $world.update

world.update =
| $active <= $active^uncons{active}.keep{?update}^cons{active}
| !$cycle + 1

unit.can_move_to XYZ = 1

unit.update =
| when $action: leave $action.update
| less $ordered and $ordered.valid: leave 0
| $action <= $ordered
| $ordered <= 0
| $action.run
| $action.update
