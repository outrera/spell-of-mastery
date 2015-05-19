// game world update routines

main.update =
| $world.update

world.new_game =
| $player <= $players.($players.size-1)
| $turn <= 0
| $end_turn // hack to begin turns from 1
| for P $players
  | for S P.sight: S.clear{0}
  | for U P.units: U.explore
| $human <= $players.1
| when got!it $players.find{?human}: $human <= it

EndTurnDepth = 0

world.end_turn =
| Researching = $player.researching
| when Researching: !$player.research.Researching + $player.power
| $player.params.view.init{$view.center}
| $player.params.cursor.init{$view.cursor}
| NextPlayer = $player.id+1
| less NextPlayer < $players.size
  | NextPlayer <= 0
  | !$turn + 1
| P = $players.NextPlayer
| $player <= P
| when P.human
  | $view.center_at{$player.params.view}
  | $view.cursor.init{$player.params.cursor}
| P.power <= 1
| PID = P.id
| P.pentagram <= 0
| P.leader <= 0
| Units = $player.active
| less Units.size /*or $player.human*/:
  | when EndTurnDepth>16
    | EndTurnDepth<=0
    | leave
  | !EndTurnDepth+1
  | $end_turn
  | EndTurnDepth <= 0
  | leave
| for U P.units
  | when U.bank >< pentagram: P.pentagram <= U
  | when U.leader: P.leader <= U
  | when U.level: for V $units_at{U.xyz}
    | when V.type >< special_node
      | !P.power+1
| P.moves <= min $player.power P.moves+$player.power
| less $turn><1: !P.mana+$player.power
| when $turn><1 and P.leader and P.human: $view.center_at{P.leader.xyz cursor/1}
| $on_player_change P


EventActions = []

world.process_events =
| DisabledEvents = have $params.disabled_events []
| for [Id [When @Actions]] $events: when no DisabledEvents.find{Id}:
  | Repeat = 0
  | case When [repeat @RealWhen]
    | When <= RealWhen
    | Repeat <= 1
  | Negate = 0
  | case When [not @RealWhen]
    | When <= RealWhen
    | Negate <= 1
  | True = case When
    [turn N] | N><$turn
    [got_unit Player UnitType]
      | Units = $players.Player.units
      | got Units.find{?type><UnitType}
    [researched Player ActName]
      | Act = $main.params.acts.ActName
      | less got ActName: "World events references unknown act [ActName]"
      | ResearchSpent = $players.Player.research.(Act.type)
      | ResearchRemain = Act.research - ResearchSpent
      | ResearchRemain << 0
  | when Negate: True <= not True
  | less True: Repeat <= 1
  | less Repeat: push Id $params.disabled_events
  | when True: push Actions EventActions
| EventActions <= EventActions.flip.join

world.update =
| when EventActions.end: $process_events
| when not $picked or $picked.idle: less $waiting: till EventActions.end
  | case EventActions^pop
    [msg Title @Body]
      | $main.show_message{Title Body.text{' '}}
      | leave
    [victory Player Reason]
      | $params.winner <= Player
      | $params.victory_type <= Reason
| times I 2
  | NextActive = []
  | for U $active.list: U.update
  | while $active.used
    | U = $active.pop
    | when U.active: push U NextActive
  | for U NextActive: $active.push{U}
  | !$cycle + 1
  | ($on_update){}

unit.update =
| when $turn and ($world.turn - $turn) > $ttl and $action.class_name <> die:
  | DeathOrder = $order.init{act/die}
  | DeathOrder.speed <= 0
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
  | when $ranged and $next_action.class_name >< attack:
    | Path^uncons{path}{?free}
    | Path <= 0
    | $next_action.path <= 0
  | when Path
    | swap $ordered $next_action
    | $ordered.path <= Path.path
    | $next_action.init{act/move at/Path.xyz}
    | Path.free
  | less $anim >< idle: $animate{idle}
  | MoveAction = $next_action.class_name >< move
  | Speed = if MoveAction then $speed else $next_action.speed
  | if     $next_action.valid
       and (not $next_action.speed
            or ($moved < $world.turn and $owner.mana>>$next_action.cost))
    then | less Path:
           | !$owner.mana-$next_action.cost
           | when Speed: $moved <= $world.turn-Speed-1
         | less $owner.human
           | X,Y = $xyz.take{2}
           | when $world.human.sight.Y.X
             | $world.view.center_at{$xyz cursor/1}
    else $next_action.init{act/idle at/$xyz}
  | swap $action $next_action
  | $next_action.class <= 0
  | $next_action.priority <= 0
  | when Path
    | swap $ordered $next_action
    | $ordered.class <= 0
    | when Speed: $moved <= $world.turn+Speed+1 // restore it back
    | $next_action.priority <= 1000
  | $action.start
| $action.update
| 1