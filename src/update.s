// game world update routines

main.update =
| $world.update

world.new_game =
| $player <= $players.($players.size-1)
| $turn <= 0
| $end_turn // hack to begin turns from 1

world.end_turn =
| Researchng = $player.researching
| when Researchng and $player.moves > 0:
  | !$player.research.Researchng + $player.moves
| NextPlayer = $player.id+1
| less NextPlayer < $players.size
  | NextPlayer <= 0
  | !$turn + 1
| P = $players.NextPlayer
| $player <= P
| P.power <= 1
| P.pentagram <= 0
| PID = P.id
| for U $units.keep{U => not U.removed and U.owner.id >< PID}
  | when U.type >< special_pentagram: P.pentagram <= U
  | when U.leader: P.leader <= U
  | when U.level: for V $units_at{U.xyz}
    | when V.type >< special_node
      | !P.power+1
| P.moves <= min $player.power P.moves+$player.power
| less $player.active.size
  | $end_turn
  | leave
| $on_player_change P

world.update =
| NextActive = []
| while $active.used
  | U = $active.pop
  | U.update
  | when U.active: push U NextActive
| for U NextActive: $active.push{U}
| !$cycle + 1
| ($on_update){}

unit.update =
| when $removed
  | $active <= 0
  | leave
| !$anim_wait - 1
| less $anim_wait > 0
  | $anim_step <= ($anim_step+1)%$anim_seq.size
  | $pick_facing{$facing}
  | $anim_wait <= $anim_seq.$anim_step.1
| when $ordered.class
  | when ($ordered.path or $ordered.valid)
         and $ordered.priority >> $next_action.priority:
    | swap $ordered $next_action
  | $ordered.class <= 0
| till $action.cycles > 0 // action is done?
  | when $anim<>idle and $anim<>move and
         ($anim_step <> $anim_seq.size-1 or $anim_wait > 1):
    | leave 1
  | $action.finish
  | Path = $next_action.path
  | when Path
    | swap $ordered $next_action
    | $ordered.path <= Path.path
    | $next_action.init{act/move at/Path.xyz}
    | Path.free
  | less $anim >< idle: $animate{idle}
  | if     $next_action.valid
       and ($owner.moves > 0 or not $next_action.cost)
       and $moved <> $world.turn
    then | less Path: !$owner.moves - $next_action.cost
         | $moved <= $world.turn
    else $next_action.init{act/idle at/$xyz}
  | swap $action $next_action
  | $next_action.class <= 0
  | $next_action.priority <= 0
  | when Path
    | swap $ordered $next_action
    | $ordered.class <= 0
    | $moved <= $world.turn-1
    | $next_action.priority <= 1000
  | $action.start
| $action.update
| 1