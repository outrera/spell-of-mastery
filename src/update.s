// game world update routines
use util

main.update =
| $world.update


player.reset_counters =
| Param = $params
| Param.item_gold <= 0
| Param.item_wood <= 0
| Param.item_stone <= 0
| Param.item_iron <= 0
| Param.item_houses <= 0
| for K,V Param: when K.size>5 and K.take{5}><item_:
  | Param.K <= 0

count_flag_resources Me =
| Param = $owner.params
| for K,V $cell.items: Param.K <= Param.K^~{0} + V

player.recount =
| $reset_counters
| for U $units: when U.ai><flag: less U.removed: count_flag_resources U

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
  [cycle N] | N><$cycle
  [got_unit Player UnitType]
    | Units = $players.Player.units
    | got Units.find{?type><UnitType}
  [researched Player ActName]
    | Act = $main.params.acts.ActName
    | less got ActName: "World events references unknown act [ActName]"
    | ResearchSpent = $players.Player.research.(Act.name)
    | ResearchRemain = Act.lore - ResearchSpent
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

update_units_effects Me Units =
| Cycle = $cycle
| for U Units: less U.removed:
  | less U.empty: when U.class.hp>0:
    | for V $units_get{U.xyz}: less V.effects.end:
      | V.run_effects{(X=>case X [`.`tenant_cycle N] Cycle%N><0) U U.xyz}
  | less U.effects.end:
    | U.run_effects{(X=>case X [`.`cycle N] Cycle%N><0) U U.xyz}
    | when U.idle: U.run_effects{(X=>case X [`.`idle N] Cycle%N><0) U U.xyz}
    | Remove = 0
    | RunEs = []
    | for E U.effects: when E.amount>0:
      | E.amount--
      | less E.amount > 0:
        | when E.when >< timeout: push [E.name E.params.unheap] RunEs
        | Remove <= 1
        | E.amount <= No
    | when Remove: U.strip_effect{No} //strip effects with zero duration
    | for Name,Params RunEs: U.run_effect{Name Params U U.xyz}

update_units Me =
| ActiveList = $active.list
| update_units_effects Me ActiveList
| NextActive = []
| for U ActiveList: U.update
| while $active.used
  | U = $active.pop
  | when U.active: push U NextActive
| for U NextActive: $active.push{U}

world.update =
| $main.music{playlist_advance}
| when $blink.0>0 and not $cycle%12:
  | $blink.0--
  | when $blink.1: $blink.1.picked <= not $blink.1.picked
  | less $blink.0:
    | $blink.1.picked <= 0
    | $blink.1<=0
    | for U $human.picked: U.picked <= 1
| when EventActions.end: $process_events
| when update_events Me: leave
| for Player $players: when Player.total_units: //reset counters
  | Player.reset_counters
| update_units Me
| for Player $players: when Player.total_units: Player.update
| $cycle++
| $view.ui.update

update_anim Me =
| $anim_wait--
| less $anim_wait > 0:
  | when $anim_step+1 >< $anim_seq.size:
    | when $anim >< death: leave
    | when $anim >< attack or $anim><hit:
      | $animate{idle}
  | $anim_step <= ($anim_step+1)%$anim_seq.size
  | Step = $anim_seq.$anim_step
  | when Step.0><impact:
    | when $anim><attack: $action.impact
    | update_anim Me
    | leave
  | $pick_facing{$facing}
  | $anim_wait <= Step.1

find_path_around_busy_units Me XYZ = //Me is unit
| OID = $owner.id
| Target = $world.cell{@XYZ}
| check Dst =
  | if Dst><Target then 1
    else | Us = Dst.units.skip{?empty}
         | R = 0
         | when Us.size
           | U = Us.0
           | when U.owner.id><OID:
             | when not U.path.end or U.action.type><attack:
               | R <= \block
         | R
| Found = $pathfind{10 &check}
| if Found
  then | Path = Found.path
       | $set_path{Path}
       | $path_life <= Path.size
  else | $set_path{[]}
       | $path_life <= 0

UpdatePathHangTrap = 0


unit_check_move Me Dst =
| less $speed: leave 0
| Src = $xyz
| when Src >< Dst: leave 0
| SX,SY,SZ = Src
| X,Y,Z = Dst
| when (X-SX).abs>1 or (Y-SY).abs>1: leave 0
| Tile = $world.at{X Y Z}
| less Tile.empty
  | when $worker:
    | when Tile.dig: leave dig
    | when Tile.unit
      | B = $world.block_at{X,Y,Z}
      | when B and B.ai><remove: leave dig
  | leave 0
| Below = $world.at{X Y $world.floor{X,Y,Z}-1}
| when Below.type><water:
  | less $flyer or $amphibian or $swimmer: leave 0
| B = $world.block_at{Dst}
| less B: leave move
| if $owner.id <> B.owner.id
  then when B.alive and $combat: leave attack
  else when B.speed and B.can_move{}{B Dst.cell Src.cell}:
       | leave swap
| 0

update_path_move Me XYZ =
| M = unit_check_move Me XYZ
| less M: leave 0
| Us = $world.units_get{XYZ}.skip{?empty}
| Target = if Us.end then 0 else Us.0
| when Target and Target.owner.id >< $owner.id
       // good idea would be pushing ranged unit forward, so other rangers
       // get a chance to attack too
       and (not $flyer or Target.flyer) //flyer has precedence over non-flyer
       and (not Target.idle
            or ($range><Target.range
                and Target.goal and Target.path.end)):
  | when Target.xyz<>$goal.xyz:
    | when UpdatePathHangTrap>0: leave
    | Stuck = $get_effect_value{stuck}
    | Cycle = $world.cycle
    | less Stuck and Stuck.0.list><$xyz and Stuck.1.list><$goal.xyz:
      | when got Stuck: $strip_effect{stuck}
      | $add_effect{stuck 0 [$xyz $goal.xyz Cycle 4]}
      | Stuck <= $get_effect_value{stuck}
    | [Src Dst Wait Tries] = Stuck
    | when Tries<<0:
      | $strip_effect{stuck}
      | $goal <= 0 //FIXME: let AI know that we cant reach the goal
      | $set_path{[]}
      | leave
    | when Wait>Cycle: leave
    | find_path_around_busy_units Me $goal.xyz
    | less $path.end:
      | UpdatePathHangTrap++
      | update_path Me
    | $strip_effect{stuck}
    | $add_effect{stuck 0 [$xyz $goal.xyz Cycle+12 Tries-1]}
    | leave
| $order.init{M | Target or XYZ}


goal_in_range Me =
| Act = $goal_act
| $order.init{Act $goal}
| less Act.repeat><1: $goal <= 0

update_path Me =
| when not $goal or $goal.serial <> $goal_serial or $goal.removed
       or not $goal.alive:
  | $goal <= 0
  | $set_path{[]}
  | leave
| Act = $goal_act
| R = $goal_act.range
| when R:
  | when R><user: R <= $range
  | GXYZ = $goal.xyz
  | Reach = if R><neib
              then (GXYZ-$xyz).take{2}{?abs}.sum><1 and (GXYZ.2-$xyz.2).abs<<1
            else if R><cross then (GXYZ-$xyz).take{2}{?abs}.sum><1
            else (GXYZ-$xyz).take{2}.abs.int<<R
                 and (| T = $goal_act.targets
                      | if T><seen then $world.seen_from{$xyz $goal.xyz}
                        else if T><any then 1
                        else 0)
  | when Reach:
    | $set_path{[]}
    | goal_in_range Me
    | leave
| Path = $path
| $path_life--
| when $path_life<<0 or Path.end:
  | when $xyz >< $goal.xyz:
    | goal_in_range Me
    | leave
  | Path = $path_to{$goal.xyz}
  | when Path.end:
    | $goal <= 0
    | leave 0
  | LastPathLife = $path_life
  | $set_path{Path}
  | when Path.last.xyz<>$goal.xyz: //cant reach goal from here?
    | when LastPathLife>0: //got stuck?
      | $goal <= 0
      | leave 0
    | $path_life <= Path.size+1 //ensure it gets as close as possible
| Path = $path
| when Path.end: leave
| XYZ = Path.head.xyz
| $path <= Path.heapfree1
| update_path_move Me XYZ

update_order Me =
| when $ordered.type
  | when $ordered.valid and $ordered.priority >> $next_action.priority:
    | swap $ordered $next_action
  | $ordered.type <= 0

update_fade Me =
| less $delta: leave
| $alpha+=$delta
| when $alpha > 255:
  | $alpha <= 255
  | $delta <= 0
| when $alpha < 0:
  | $alpha <= 0
  | $delta <= 0

update_next_action Me =
| less $next_action.type: less $path.end:
  | update_path Me
  | update_order Me
| Cost = $next_action.cost
| if     $next_action.type and $next_action.valid
     and (not Cost or $owner.mana>>Cost)
  then | $owner.mana -= $next_action.cost
  else
  | if not $next_action.type
      then
    else if Cost and not $owner.mana>>Cost
      then $owner.notify{'Not enough mana.'}
    else if not $next_action.valid
      then //$owner.notify{'Cant perform action.'}
    else
  | $next_action.init{idle $xyz}
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
    | $cooldown--
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

find_in_circle CX CY R F =
| for PX,PY points_in_circle{R}
  | X = CX + PX
  | Y = CY + PY
  | when X > 0 and Y > 0:
    | Found = F X Y
    | when Found: leave Found
| 0

attack_nearby_enemy Me =
| O = $owner
| SightF = $sight
| UXY = $xyz.take{2}
| check X Y =
  | R = 0
  | for B $world.column_units_get{X Y}.skip{?empty}
    | when O.is_enemy{B.owner}
           and B.health
           and (UXY-[X Y]).abs.int << SightF
           and not B.invisible
           and $world.seen_from{$xyz B.xyz}:
      | R <= B
  | R
| Found = find_in_circle $xyz.0 $xyz.1 $sight &check
| less Found: leave
| $order_at{Found.xyz}
| $backtrack <= $xyz

GravAcc = 9.807*0.2
update_fall Me =
| $velocity.2 -= GravAcc
| FZ = $floor.z
| FDst = $fxyz+$velocity{}{?int}
| if FDst.2 > FZ*$world.c then $fine_move{FDst}
  else $move{[$xyz.0 $xyz.1 FZ]}

unit_sink Me =
| $sound{sink}
| $world.effect{$xyz sink}
| $move{[$world.w+1 $world.h+1 1]} //move it out of sight
| $harm{Me 6000}

unit.update =
| when $removed or $active<>1:
  | $active <= 0
  | leave
| when $host:
  | if $host.serial >< $host_serial and not $host.removed
    then | when $xyz<>$host.xyz: $move{$host.xyz}
         | $fxyz.init{$host.fxyz}
    else $die
| if $cell > $floor then | update_fall Me; leave
  else when $velocity.2<0.0:
  | $velocity.2 <= 0.0
  | when $world.at{$xyz.0 $xyz.1 $xyz.2-1}.liquid and not $flyer: 
    | unit_sink Me
    | leave
| when $paralyzed and $alive: leave
| update_anim Me
| when $ai><flag: count_flag_resources Me
| when $idle:
  | less $empty:
    | B = $world.units_get{$xyz}.skip{U => U.empty or U.id><$id}
    | less B.end: when B.0.idle:
      | Found = $world.find{100 Me $cell | Dst => not Dst.block}
      | when Found: $order_at{Found.xyz}
  | UpdatePathHangTrap <= 0
  | update_path Me
| update_order Me
| update_fade Me
| update_action Me
| when $removed: leave //unit can be removed as a result of an action
| when $combat and $action.type><idle and not $goal:
  | when not $invisible or not $owner.human:
    | attack_nearby_enemy Me
| 1 // 1 means we are still alive
