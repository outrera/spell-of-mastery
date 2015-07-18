// game world update routines

main.update =
| $world.update

world.new_game =
| for K,V $main.params.world: $params.K <= V
| $player <= $players.($players.size-1)
| $turn <= 0
| $end_turn // hack to begin turns from 1
| when $params.unexplored
  | for P $players
    | for S P.sight: S.clear{0}
    | for U P.units: U.explore
| for P $players:
  | P.mana <= 2000
  | for U P.units: U.moved <= 0
| $human <= $players.1
| when got!it $players.find{?human}: $human <= it

world.explore =
| for P $players: for S P.sight: S.clear{1}

EndTurnDepth = 0

world.end_turn =
| for U $player.units: when U.health:
  | for V $units_at{U.xyz}: case V.heal Amount,Effect:
    | U.world.effect{U.xyz Effect}
    | U.harm{V -Amount}
| Researching = $player.researching
| when Researching and $player.power > 0:
  | !$player.research.Researching + $player.power
  | ActName = $main.params.acts.Researching
  | less $player.research_remain{ActName} > 0:
    | $player.researching <= 0
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
| P.power <= 0
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
  | U.handled <= 0
  | when U.bank >< pentagram: P.pentagram <= U
  | when U.leader: P.leader <= U
  | !P.power + U.income
  | U.extort
| less $turn><1: !P.mana+$player.power
| when P.mana < 0: P.mana <= 0
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
      | ResearchSpent = $players.Player.research.(Act.name)
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
    [guards_to_attackers PlayerId]
      | for U $players.PlayerId.units: U.attacker <= 1
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
| when $turn and ($world.turn - $turn) >> $ttl and $action.type <> die:
  | $die
| when $removed
  | $active <= 0
  | leave
| !$anim_wait - 1
| less $anim_wait > 0
  | $anim_step <= ($anim_step+1)%$anim_seq.size
  | $pick_facing{$facing}
  | $anim_wait <= $anim_seq.$anim_step.1
| when $ordered.type
  | when ($ordered.path or $ordered.valid)
         and $ordered.priority >> $next_action.priority:
    | swap $ordered $next_action
  | $ordered.type <= 0
| till $action.cycles > 0 // action is done?
  | when $anim<>idle and $anim<>move and
         ($anim_step <> $anim_seq.size-1 or $anim_wait > 1):
    | leave 1
  | $action.finish
  | Path = $next_action.path
  | when $ranged and $next_action.type >< attack:
    | Path^uncons{path}{?free}
    | Path <= 0
    | $next_action.path <= 0
  | when Path
    | swap $ordered $next_action
    | $ordered.path <= Path.path
    | $next_action.init{type/move at/Path.xyz}
    | Path.free
  | less $anim >< idle: $animate{idle}
  | MoveAction = $next_action.type >< move
  | Speed = if MoveAction then $speed else $next_action.speed
  | if     $next_action.type and $next_action.valid
       and (not $next_action.speed
            or ($moved < $world.turn and $owner.mana>>$next_action.cost))
    then | less Path:
           | !$owner.mana-$next_action.cost
           | when Speed: $moved <= $world.turn-Speed-1
         | less $owner.human: when $seen:
           | $world.view.center_at{$xyz cursor/1}
    else $next_action.init{type/idle at/$xyz}
  | swap $action $next_action
  | $next_action.type <= 0
  | $next_action.priority <= 0
  | when Path
    | swap $ordered $next_action
    | $ordered.type <= 0
    | $next_action.priority <= 1000
  | $action.start
| $action.update
| 1