// game world update routines
use pathfind

main.update =
| $world.update

// force reset of all unit effects and health
reinit_units Us =
| for U Us: less U.removed
  | Type = U.type
  | Owner = U.owner
  | Facing = U.facing
  | XYZ = U.xyz.deep_copy
  | U.free
  | U = Owner.alloc_unit{Type}
  | U.move{XYZ}
  | U.pick_facing{Facing}

world.new_game =
| for K,V $main.params.world: $params.K <= V
| for ActName,Act $main.params.acts: Act.enabled <= #FFFFFF
| $human <= $players.1
| $human.human <= 1
| $cycle <= 0
| if $params.explored then $explore{1} else $explore{0}
| ActNames = $main.params.acts{}{?0}
| StartMana = $main.params.world.start_mana
| reinit_units $active
| for P $players:
  | P.lore <= 10
  | P.mana <= StartMana
  | Us = P.units
  | less P.human: when Us.size:
    | for ActName ActNames: P.research_item{ActName}
| when got!it $players.find{?human}: $human <= it

EventActions = []

check_event_condition Me When =
| case When
  [N<eq+atleast Var Value]
    | V = case Var
        [`.` Player Var]
          | P = $players.Player
          | if Var >< mana then P.mana else P.params.Var
        Else | $params.Var
    | if got V then if N><eq then V >< Value else V >> Value
      else 0
  [always] | 1
  [turn N] | N><$turn and $new_turn
  [got_unit Player UnitType]
    | Units = $players.Player.units
    | got Units.find{?type><UnitType}
  [researched Player ActName]
    | Act = $main.params.acts.ActName
    | less got ActName: "World events references unknown act [ActName]"
    | ResearchSpent = $players.Player.research.(Act.name)
    | ResearchRemain = Act.research - ResearchSpent
    | ResearchRemain << 0
  [`not` X] | not: check_event_condition Me X
  [`and` A B] | check_event_condition Me A and check_event_condition Me B
  [`or` A B] | check_event_condition Me A or check_event_condition Me B
  Else | bad "unexpected event condition [When]"

world.process_events =
| DisabledEvents = have $params.disabled_events []
| for [Id [When @Actions]] $events: when no DisabledEvents.find{Id}:
  | Repeat = 0
  | case When [repeat @RealWhen]
    | When <= RealWhen
    | Repeat <= 1
  | True = check_event_condition Me When
  | less True: Repeat <= 1
  | less Repeat: push Id $params.disabled_events
  | when True: push Actions EventActions
| EventActions <= EventActions.flip.join

update_events Me =
| till EventActions.end
  | Effect = EventActions^pop
  | case Effect
    [`{}` EffectName Args @Rest]
      | if Rest.size then Args <= [Args @Rest]
        else case Args [`,` @_]
             | Args <= Args^|@r [`,` X Y]=>[@(r X) Y]; X => [X]
      | $nil.effect{[EffectName,Args] $nil [0 0 0]}
      | when EffectName >< msg: leave 1 //hack to show message before victory
    Else | bad "bad event effect ([Effect])"
| 0

update_units Me =
| NextActive = []
| for U $active.list: U.update
| while $active.used
  | U = $active.pop
  | when U.active: push U NextActive
| for U NextActive: $active.push{U}

world.update =
| $main.music{playlist_advance}
| when EventActions.end: $process_events
| when update_events Me: leave
| update_units Me
| !$cycle + 1
| ($on_update){}

update_anim Me =
| !$anim_wait - 1
| less $anim_wait > 0:
  | when $anim_step+1 >< $anim_seq.size:
    | when $anim >< death: leave
    | when $anim >< attack:
      | $animate{idle}
  | $anim_step <= ($anim_step+1)%$anim_seq.size
  | Step = $anim_seq.$anim_step
  | when Step.0><impact:
    | when $action.type><attack: $anim_hit <= 1
    | update_anim Me
    | leave
  | $pick_facing{$facing}
  | $anim_wait <= Step.1


find_path_around_busy_units Me XYZ =
| OID = $owner.id
| check Dst =
  | DXYZ = Dst.xyz
  | if DXYZ><XYZ then 1
    else | Us = $world.units_at{DXYZ}.skip{?empty}
         | when Us.size
           | U = Us.0
           | when U.owner.id><OID:
             | when not U.path.end or U.action.type><attack:
               | Dst.type <= 0
         | 0
| Found = $pathfind{10 &check}
| if Found
  then | Path = Found^node_to_path
       | $set_path{Path}
       | $path_life <= Path.size
  else | $set_path{[]}
       | $path_life <= 0

UpdatePathHangTrap = 0

update_path_move Me XYZ =
| Ms = $list_moves{$xyz}.keep{?xyz><XYZ}
| when Ms.end: leave 0
| M = Ms.0
| Us = $world.units_at{XYZ}.skip{?empty}
| Target = if Us.end then 0 else Us.0
| when Target and Target.owner.id >< $owner.id and Target.goal:
  | when Target.xyz<>$goal.xyz:
    | when UpdatePathHangTrap>0: leave
    | find_path_around_busy_units Me $goal.xyz
    | less $path.end:
      | !UpdatePathHangTrap+1
      | update_path Me
    | leave
| $order.init{type/M.type at/XYZ target/Target}

update_path Me =
| when not $goal or $goal.serial <> $goal_serial or $goal.removed
       or not $goal.alive:
  | $goal <= 0
  | $set_path{[]}
  | leave
| when $goal.is_unit and $goal.owner.is_enemy{$owner}:
  | when $range and ($goal.xyz.take{2}-$xyz.take{2}).abs<<$range.float:
    | when $world.seen_from{$xyz $goal.xyz}:
      | $order.init{type/attack at/$goal.xyz target/$goal}
      | leave
| Path = $path
| !$path_life-1
| when $path_life<<0 or Path.end:
  | when $xyz >< $goal.xyz:
    | $goal <= 0
    | leave
  | $set_path{$path_to{$goal.xyz}}
| Path = $path
| when Path.end: leave
| XYZ = Path.head.unheap
| $path <= Path.heapfree1
| update_path_move Me XYZ

update_order Me =
| when $ordered.type
  | when $ordered.valid and $ordered.priority >> $next_action.priority:
    | swap $ordered $next_action
  | when $ordered.type<>idle: $moved <= $world.cycle
  | $ordered.type <= 0

update_fade Me =
| less $delta: leave
| !$alpha+$delta
| when $alpha > 255:
  | $alpha <= 255
  | $delta <= 0
| when $alpha < 0:
  | $alpha <= 0

update_next_action Me =
| less $next_action.type: less $path.end:
  | update_path Me
  | update_order Me
| Cost = $next_action.cost
| if     $next_action.type and $next_action.valid
     and (not Cost or $owner.mana>>Cost)
  then | !$owner.mana-$next_action.cost
  else
  | if not $next_action.type
      then
    else if Cost and not $owner.mana>>Cost
      then $owner.notify{'Not enough mana.'}
    else if not $next_action.valid
      then $owner.notify{'Cant perform action.'}
    else
  | $next_action.init{type/idle at/$xyz}
| swap $action $next_action
| $next_action.type <= 0
| $next_action.priority <= 0
| $action.start
| when $anim><move: $pick_facing{$facing}

update_action Me =
| T = $action.target
| when T and (T.removed or not T.alive): $action.cycles <= 0
| till $action.cycles > 0 // action is done?
  | when $cooldown>0:
    | !$cooldown-1
    | leave
  | when $anim<>idle and $anim<>move and $next_action.type <> die and
         and $anim<>hit and
         ($anim_step <> $anim_seq.size-1 or $anim_wait > 1):
    | leave // ensure animation finishes
  | $action.finish
  | update_next_action Me
  | when $action.type><attack:
    | $cooldown <= $class.cooldown
| $action.update

attack_nearby_enemy Me =
| O = $owner
| SightF = $sight.float
| check Dst =
  | B = $world.block_at{Dst.xyz}
  | got B and O.is_enemy{B.owner} and ($xyz-Dst.xyz).abs<SightF
| Found = $pathfind{$sight-1 &check}
| when Found: $order_at{Found.1}

unit.update =
| when $removed or $active<>1:
  | $active <= 0
  | leave
| update_anim Me
| when $idle:
  | UpdatePathHangTrap <= 0
  | update_path Me
| update_order Me
| update_fade Me
| update_action Me
| when $removed: leave //unit can be removed as a result of an action
| when $attack and $action.type><idle: attack_nearby_enemy Me
| 1 // 1 means we are still alive