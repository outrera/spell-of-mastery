// game world update routines


main.update =
| $world.update

world.update =
| $active <= $active^uncons{active}.keep{?update}^cons{active}
| !$cycle + 1

unit.can_move_to XYZ = 1

unit.update =
| when $ordered.valid
  | when $ordered.priority << $next_action.priority
    | swap $ordered $next_action
  | $ordered.class <= 0
| less $action.cycles // action is done?
  | less $next_action.valid: $next_action.init{still $xyz}
  | swap $action $next_action
  | $next_action.class <= 0
  | $action.start
| $action.update

