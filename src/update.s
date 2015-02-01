// game world update routines


main.update =
| $world.update

world.update =
| NextActive = []
| while $active.used
  | U = $active.pop
  | U.update
  | when U.active: push U NextActive
| for U NextActive: $active.push{U}
| !$cycle + 1

unit.update =
| when $removed
  | $active <= 0
  | leave 0
| when $ordered.class
  | when $ordered.valid and $ordered.priority >> $next_action.priority:
    | swap $ordered $next_action
  | $ordered.class <= 0
| till $action.cycles // action is done?
  | $action.finish
  | less $next_action.valid: $next_action.init{still $xyz}
  | swap $action $next_action
  | $next_action.class <= 0
  | $next_action.priority <= 0
  | $action.start
| $action.update
| 1