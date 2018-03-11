// game world update routines
use util

main.update =
| $world.update

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

update_units_genes Me Units =
| Cycle = $cycle
| for U Units: less U.removed:
  | less U.empty: when U.class.hp>0:
    | for V $units_get{U.xyz}: less V.genes.end:
      | V.run_genes{E=>case E.when [`.`tenant_cycle N] Cycle%N><0}
  | less U.genes.end:
    | U.run_genes{E=>case E.when [`.`cycle N] Cycle%N><0}

update_units Me =
| ActiveList = $active.list
| update_units_genes Me ActiveList
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
| update_units Me
| for Player $players: when Player.total_units: Player.update
| $actors.set{$actors.get.skip{A=>A.idle or not A.health}}
| less $actors.get.size or $paused:
  | $players.$player.make_move
| $cycle++
| $view.ui.update

update_anim Me =
| when $anim_wait-- > 1: leave
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

unit_check_move Me Dst =
| less $speed: leave 0
| Src = $xyz
| when Src >< Dst: leave 0
| SX,SY,SZ = Src
| X,Y,Z = Dst
| when (X-SX).abs>1 or (Y-SY).abs>1: leave 0
| Tile = $world.at{X Y Z}
| less Tile.empty: leave 0
| Below = $world.at{X Y $world.floor{X,Y,Z}-1}
| when Below.type><water:
  | less $flyer or $amphibian or $swimmer: leave 0
| B = $world.block_at{Dst}
| less B: leave move
| if $is_enemy{B}
  then //when B.alive and $combat: leave attack
  else when B.speed and B.can_move{}{B Dst.cell Src.cell}:
       | leave swap
| 0

update_path_move Me XYZ =
| M = unit_check_move Me XYZ
| less M: leave 0
| Us = $world.units_get{XYZ}.skip{?empty}
| Target = if Us.end then 0 else Us.0
| when M<>attack and $nearby_enemies_at{XYZ}.size: $engaged <= 1
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
| R = Act.range
| when R:
  | when R><user: R <= $range
  | GXYZ = $goal.xyz
  | Reach = if R><1 //FIXME: use points_in_diamond
              then (GXYZ-$xyz).take{2}{?abs}.sum><1 and (GXYZ.2-$xyz.2).abs<<1
            else if R><cross then (GXYZ-$xyz).take{2}{?abs}.sum><1
            else (GXYZ-$xyz).take{2}.abs.int<<R
  | when Reach:
    | $set_path{[]}
    | goal_in_range Me
    | leave
| Path = $path
| when Path.end:
  | when $xyz >< $goal.xyz:
    | goal_in_range Me
    | leave
  | Path = $path_near{$goal.xyz}
  | when Path.end: //cant reach goal from here?
    | $goal <= 0
    | leave 0
  | $set_path{Path}
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

LastMovedUnit = -1
LastMovedTurn = -1

unit.seen_by_human = $world.human.seen{$xyz}
unit.observe = $main.ui.view.center_at{$xyz+[-3 -3 0] cursor/1}

center_on_actor Me =
| less $owner.human: when $action.type<>idle and $health and $seen_by_human:
  | when LastMovedUnit <> $serial or LastMovedTurn <> $world.turn:
    | $observe
  | LastMovedUnit = $serial
  | LastMovedTurn = $world.turn

update_next_action Me =
| when $order.type: update_order Me
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
| $steps -= $action.act.steps
| center_on_actor Me
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

GravAcc = 9.807*0.2
update_fall Me =
| when $velocity.2>>0.0:
  | $sound{fall}
  | $add_gene{fallheight 0 $cell-$floor}
| $velocity.2 -= GravAcc
| FZ = $floor.z
| FDst = $fxyz+$velocity{}{?int}
| if FDst.2 > (FZ*$world.c+31) then $fine_move{FDst}
  else $move{[$xyz.0 $xyz.1 FZ]}

unit_landed Me =
| $velocity.2 <= 0.0
| $sound{land}
| FH = $gene_param{fallheight}
| $strip_gene{fallheight}
| $harm{Me FH*3-2}

unit.sink =
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
| when $cell > $floor:
  | update_fall Me
  | leave
| when $velocity.2<0.0: unit_landed Me
| when $class.hp and ($cell-1).tile.liquid and not $can_stand_on_water:
  | $sink
  | leave

| update_anim Me
| when $idle: update_path Me
| update_order Me
| update_fade Me
| update_action Me
| when $removed: leave //unit can be removed as a result of update_action
| 1 // 1 means we are still alive
