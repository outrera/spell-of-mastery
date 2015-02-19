// game world update routines

main.update =
| $world.update

world.init_game =
| $player <= $players.($players.size-1)
| $turn <= 0
| $end_turn

world.end_turn =
| NextPlayer = $player.id+1
| less NextPlayer < $players.size
  | NextPlayer <= 0
  | !$turn + 1
| $player <= $players.NextPlayer

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
  | leave
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