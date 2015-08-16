// game world update routines

main.update =
| $world.update

world.new_game =
| for K,V $main.params.world: $params.K <= V
| for ActName,Act $main.params.acts: Act.enabled <= #FFFFFF
| $player <= $players.($players.size-1)
| $turn <= 0
| $end_turn // hack to begin turns from 1
| less $params.explored: $explore{0}
| for P $players:
  | for U P.units: U.moved <= 0
| $human <= $players.1
| when got!it $players.find{?human}: $human <= it

EndTurnDepth = 0

world.end_turn =
| P = $player
| for U P.units: when U.health>0:
  | for V $units_at{U.xyz}: when V.trigger: V.effect{V.trigger U U.xyz}
| ResearchIncome = P.income-P.upkeep
| when ResearchIncome > 0: P.reasearch_boost{0 ResearchIncome}
| P.params.view.init{$view.center}
| P.params.cursor.init{$view.cursor}
| NextPlayer = P.id+1
| less NextPlayer < $players.size
  | NextPlayer <= 0
  | !$turn + 1
| P = $players.NextPlayer
| $player <= P
| when P.human
  | $view.center_at{$player.params.view}
  | $view.cursor.init{$player.params.cursor}
| PID = P.id
| Units = $player.active
| less Units.size /*or $player.human*/:
  | when EndTurnDepth>16
    | EndTurnDepth<=0
    | leave
  | !EndTurnDepth+1
  | $end_turn
  | EndTurnDepth <= 0
  | leave
| for U P.units: U.handled <= 0
| P.recalc
| less $turn><1: !P.mana+$player.income
| Leader = P.leader
| when P.mana < $params.defeat_threshold and Leader and Units.size:
  | $main.show_message{'Wizard has Lost Too Much Mana'
       "[P.name] is too exhausted and cannot continue his life."}
  | Leader.harm{Leader 1000}
  | $effect{Leader.xyz electrical}
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
    [eq VarName Value] | $params.VarName >< Value
    [peq Player VarName Value] | $players.Player.params.VarName >< Value
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
  | Effect = EventActions^pop
  | case Effect
    [`{}` EffectName Args @Rest]
      | if Rest.size then Args <= [Args @Rest]
        else case Args [`,` @_]
             | Args <= Args^|@r [`,` X Y]=>[@(r X) Y]; X => [X]
      | $nil.effect{[EffectName,Args] $nil [0 0 0]}
      | when EffectName >< msg: leave //hack to show message before victory
    Else | bad "bad event effect ([Effect])"
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
  | when $anim >< attack and $anim_step+1 >< $anim_seq.size:
    | $animate{idle}
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
  | Cost = $next_action.cost
  | if     $next_action.type and $next_action.valid
       and (not $next_action.speed
            or ($moved < $world.turn and (not Cost or $owner.mana>>Cost)))
    then | less Path:
           | !$owner.mana-$next_action.cost
           | when Speed: $moved <= $world.turn-Speed-1
         | less $owner.human: when $seen:
           | $world.view.center_at{$xyz cursor/1}
    else
    | if not $next_action.type
        then
      else if not $moved < $world.turn
        then $owner.notify{'Unit is not ready to move.'}
      else if Cost and not $owner.mana>>Cost
        then $owner.notify{'Not enough mana.'}
      else if not $next_action.valid
        then $owner.notify{'Cant perform action.'}
      else
    | $next_action.init{type/idle at/$xyz}
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