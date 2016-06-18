use util macros unit_flags

type cell_goal xyz/[0 0 0] serial

CellSize =

init_unit_module CS =
| CellSize <= CS

cell_goal.id = -1
cell_goal.type = \goal
cell_goal.fxyz = [$xyz.0*CellSize $xyz.1*CellSize $xyz.2*CellSize]
cell_goal.damage = 0
cell_goal.leader = 0
cell_goal.removed = 0
cell_goal.alive = 1
cell_goal.empty = 1
cell_goal.harm Attacker Damage =

type unit.$class{Id World}
  world/World //FIXME: get rid of it, we wont be using several world
  id/Id //id could be reused, when this unit is freed
  serial //seral cant be reused, when this unit is freed
  class //data shared between all units of that class
  owner // player controlling this unit
  fxyz/[0 0 0] // fine X,Y,Z
  xyz/[0 0 -1] // world cell X,Y,Z
  cell/0 //cell this unit resides in
  floor/0 // ground cell under this unit
  from/[0 0 0] //where this unit moved from
  facing // direction this unit faces
  velocity/[0.0 0.0 0.0] //when unit falls down or gets kicked
  sprite //sprite used by this unit
  colors //colors for the sprite
  alpha //how transparent is the sprite of this unit
  delta //change of transparency per cycle
  anim // animation id
  anim_step // frame index inside of current animation
  anim_seq // current animation sequence
  anim_wait // cycles till the next animation frame
  frame //gfx of current animation frame
  mirror // true, if drawing code should mirror the sprite
  action // currently executing action
  next_action // action to be taken after the current one
  ordered // what owner of this unit has ordered
  cooldown //cooldown before the unit can attack again
  ai_wait //cycles for ai to wait
  active // true if this unit resides in the list of active units
  path/[] // path to goal
  path_life //cycles before updating path
  goal
  goal_serial //in case goal gets killed
  goal_act //what to do with the goal
  host //what unit hosts this sprite
  host_serial //when host dies, its serial changes
  unit_goal/cell_goal{}
  hp // hit points
  kills //how many enemies this unit has killed
  flags //various flags (mostly effects)
  effects/[] //active effects
  mod //set by various effects to modify some contextual behavior
  can_move //movement function
| $action <= $world.action{Me}
| $next_action <= $world.action{Me}
| $ordered <= $world.action{Me}

unit.enheap = Me
unit.unheap = Me

unit.as_text = "#unit{[$type] [$id]}"

unit.main = $world.main

unit.attacker = $flags^get_bit{0}
unit.`!attacker` State = $flags <= $flags^set_bit{0 State}

unit.picked = $flags^get_bit{1}
unit.`!picked` State = $flags <= $flags^set_bit{1 State}

unit.nonguard = $flags^get_bit{2}
unit.`!nonguard` State = $flags <= $flags^set_bit{2 State}

unit.hasted = $flags^get_bit{3}

unit.flyer = $flags^get_bit{5}
unit.`!flyer` State = $flags <= $flags^set_bit{5 State}

unit.swimmer = $flags^get_bit{10}
unit.amphibian = $flags^get_bit{11}
unit.invisible = $flags^get_bit{12}
unit.paralyzed = $flags^get_bit{13}
unit.slowed = $flags^get_bit{14}

// this unit is a temporary mark (i.e. cursor); dont save it
unit.mark = $flags^get_bit{16}
unit.`!mark` State = $flags <= $flags^set_bit{16 State}

unit.child Type =
| $world.units_get{$xyz}
        .find{(?host and ?type><Type and ?host.serial><$serial)}

unit.is_enemy Target = $owner.is_enemy{Target.owner}

unit.size =
| S = $sprite.size
| if $height then S else [S.0 S.1 0]

unit.alive = $hp > 0
unit.health =
| CHP = $class.hp
| less CHP: leave 0
| UHP = $hp
| when UHP << 0: leave 0 
| R = UHP%CHP
| less R: R <= CHP
| R

land_can_move Me Src Dst =
| H = Dst.z-Src.z
| when H > 1 or H < -1: leave 0
| Dst.tile.empty and not (Dst-1).tile.liquid

amphibian_can_move Me Src Dst =
| H = Dst.z-Src.z
| when H > 1 or H < -1: leave 0
| Dst.tile.empty

swimmer_can_move Me Src Dst =
| H = Dst.z-Src.z
| when H > 1 or H < -1: leave 0
| Dst.tile.empty and (Dst-1).tile.type><water

flyer_can_move Me Src Dst =
| less Dst.tile.empty: leave 0
| SZ = Src.z
| DZ = Dst.z
| if SZ<DZ
  then | when DZ > $world.d-3: leave 0
       | times I DZ-SZ: less (Src+I).tile.empty: leave 0
  else times I SZ-DZ: less (Dst+I).tile.empty: leave 0
| 1

unit.update_move_method =
| $can_move <= if $flyer then &flyer_can_move
               else if $amphibian then &amphibian_can_move
               else if $swimmer then &swimmer_can_move
               else &land_can_move

//FIXME: when serials get exhausted, compress serial space
unit.init Class =
| $class <= Class
| $sprite <= if $show or $world.editor
             then $default_sprite
             else $world.nil.sprite
| $facing <= 3
| $mirror <= 0
| $serial <= $world.serial
| !$world.serial + 1
| $animate{idle}
| $hp <= $class.hp
| $flags <= 0
| $alpha <= 0
| $delta <= 0
| $kills <= 0
| $cooldown <= 0
| $from.init{0,0,-1}
| when $class.active
  | less $active
    | $world.active.push{Me}
  | $active <= 1
  | $ordered.type <= 0
  | $next_action.type <= 0
  | $action.init{idle 0,0,0}
  | $velocity.init{[0.0 0.0 0.0]}
  | $action.cycles <= 0
  | $unit_goal.serial <= $serial
  | $path_life <= 0
  | $ai_wait <= 0
  | for E $inborn: case E
      [`{}` Name Duration @Args] | $add_effect{Name Duration Args}
      Else | $add_effect{E 0 []}
  | $update_move_method

unit.morph Class =
| $owner.lost_unit{Me}
| $hp <= Class.hp + $hp - $class.hp
| $class <= Class
| $sprite <= if $show or $world.editor
             then $default_sprite
             else $world.nil.sprite
| $animate{idle}
| $owner.got_unit{Me}

get_named_effect Me Name Params =
| Effect = $main.params.effect.Name
| when no Effect:
  | E = Params.find{P => case P [effect @_] 1}
  | when no E: E <= [effect [on never]] // supply dummy
  | Effect <= E.tail.unheap //do unheap because Params could reside on heap
| Effect

unit.add_effect Name Duration Params =
| Effect = get_named_effect Me Name Params
| less Effect: leave
| On = Effect.0
| when On.0 <> `on`:
  | $world.notify{"unit.add_effect: missing `on{When}` for effect [Name]"}
  | leave
| Flag = getUnitFlagsTable{}.Name
| when got Flag:
  | when $flags^get_bit{Flag}: leave //already got this effect
  | when Name><invisible: $alpha <= 127
  | $flags <= $flags^set_bit{Flag 1}
  | $update_move_method
| When = On.1
| $effects <= $effects.cons{$world.new_effect{When Name Duration Params}}

unit.has Name = got $effects.find{?name><Name}

unit.cooldown_of ActName =
| E = $effects.find{E => E.name><cool and E.params.0.1.0><ActName}
| if got E then [E.amount E.params.0.1.1] else 0

unit.get_effect Name = $effects.find{?name><Name}

unit.get_effect_value Name =
| E = $effects.find{?name><Name}
| if got E then E.params else 0

unit.strip_effect Name =
| FreeEs =
| Es =
| if got Name
  then | FreeEs <= $effects.keep{?name><Name}
       | when FreeEs.end: leave
       | Es <= $effects.skip{?name><Name}
  else | FreeEs <= $effects.keep{?amount><No}
       | Es <= $effects.skip{?amount><No}
| for E FreeEs: $world.free_effect{E}
| $effects.heapfree
| $effects <= Es.enheap
| Flag = getUnitFlagsTable{}.Name
| when got Flag:
  | when Name><invisible: $alpha <= 0
  | $flags <= $flags^set_bit{Flag 0}
  | $update_move_method

unit.add_item Name Amount =
| less Amount: leave
| for E $effects: when E.name><Name:
  | !E.amount-Amount
  | when E.amount >> 0:
    | $strip_effect{Name}
    | leave
  | leave
| $add_effect{Name -Amount []}

unit.get_item Name =
| for E $effects: when E.name><Name: leave -E.amount
| 0

unit.items =
| Items = []
| for E $effects: when E.amount<0: push [E.name -E.amount] Items
| Items

unit.drop_item ItemType Amount =
| A = min $get_item{ItemType} Amount
| $add_item{ItemType -A}
| $cell.add_item{ItemType A}

unit.drop_all =
| for K,V $items: $drop_item{K V}

unit.acts =
| Param = $main.params
| ItemDefs = Param.iacts
| ItemActs = []
| for Name,Count $items:
  | Item = ItemDefs.Name
  | when got Item: for ActName Item: push Param.acts.ActName ItemActs
| [@$class.acts @ItemActs]

unit.run_effects Selector Target TargetXYZ =
| Es = []
| for E $effects: when Selector E.when:
  | Effect = get_named_effect Target E.name E.params
  | when Effect:
    | push Effect Es //cuz invoking it right here may clobber $effects
| for Effect Es: $effect{Effect Target TargetXYZ}

unit.run_effect Name Params Target TargetXYZ =
| Es = []
| Effect = get_named_effect Target Name Params
| when Effect: $effect{Effect Target TargetXYZ}

unit.`!backtrack` XYZ =
| less XYZ:
  | $strip_effect{btrack}
  | leave
| when $has{btrack}: leave
| $add_effect{btrack 0 [[effect [on [`.` cycle 24]] [btrack XYZ]]]}

unit.change_owner NewOwner =
| FXYZ = 0
| less $removed:
  | FXYZ <= $fxyz
  | $remove
| $owner.lost_unit{Me}
| $owner <= NewOwner
| when FXYZ: $fine_move{FXYZ}
| NewOwner.got_unit{Me}

unit.idle = not $ordered.type and
           [$action $next_action].all{?type^~{0 idle} >< idle}

//FIXME: move these into sprite loading code
AngleReplacements = [6,1 6,1 3,0 -1,0 3,1 3,1 3,1 6,0]

missing_frame Me =
| Index = $anim_seq.$anim_step.0
| bad "[$type] is missing frame `[Index]` of `[$anim]` at angle [$facing]"

unit.pick_facing F =
| $facing <= F
| AS = $anim_seq
| FrameIndex = AS.($anim_step%AS.size).0
| Frame = $sprite.frames.FrameIndex
| less Frame.is_list
  | $frame <= Frame
  | when no $frame: missing_frame Me
  | when $facing <> 3: $mirror <= 1
  | leave
| $mirror <= 0
| Angle = $facing
| till Frame.Angle
  | $mirror <= AngleReplacements.Angle.1
  | Angle <= AngleReplacements.Angle.0
| $frame <= Frame.Angle
| when no $frame: missing_frame Me

unit.animate Anim =
| $anim <= Anim
| $anim_seq <= $sprite.anims.$anim
| when no $anim_seq:
  | $anim_seq <= $sprite.anims.idle
  | less got $anim_seq: bad "unit [$type] is missing `idle` anim"
| $anim_step <= 0
| $pick_facing{$facing}
| $anim_wait <= $anim_seq.$anim_step.1

unit.free =
| when $picked: $owner.picked <= $owner.picked.skip{?id><$id}
| when $owner: $owner.lost_unit{Me}
| when $leader><1:
  | $owner.leader <= 0
| when $active: $active <= 2 //request removal from active list
| less $path.end: $set_path{[]}
| $goal <= 0
| $host <= 0
| $colors <= 0
| for E $effects: $world.free_effect{E}
| $effects.heapfree
| $effects <= []
| $world.free_unit{Me}

unit.reset_goal =
| less $path.end: $set_path{[]}
| $goal <= 0

//a faster solution would be keeping the linked list of all targeters
unit.reset_followers =
| for U $world.active: when U.goal and U.goal.id><$id:
  | U.reset_goal

unit.removed = $xyz.2 >< -1

unit.order = $ordered

unit.order_act Act target/0 =
| less Target: Target <= Me
| $order.init{Act Target}

// order taking over any other order
unit.forced_order Act Target =
| O = $order.init{Act Target}
| O.priority <= 1000
| O.cycles <= 0
| O

unit.die =
| Effect = $class.death
| when Effect: $effect{Effect Me $xyz}
| $forced_order{die 0}
| $order.priority <= 2000
| $cooldown <= 0

unit.set_path Path =
| $path_life <= max 2 Path.size/4
| P = Path.enheap
| $path.heapfree
| $path <= P

normalize_act Me Act =
| if Act.is_text then $main.params.acts.Act
  else if Act then Act
  else $main.params.acts.move

set_goal Me Act Target =
| if Target.is_unit then $goal <= Target
  else | $unit_goal.xyz.init{Target}
       | $goal <= $unit_goal
       | $goal_serial <= $goal.serial
| $goal_act <= normalize_act Me Act
| $set_path{[]}

unit.order_at XYZ act/0 =
| when $xyz >< XYZ:
  | when Act and normalize_act{Me Act}.type<>move:
    | Ms = $list_moves{$cell -1}
    | less Ms.end:
      | set_goal Me Act $xyz
      | $set_path{[Ms.0 $cell]}
      | leave
  | $goal <= 0
  | $goal_act <= 0 //if Act then Act else $main.params.acts.idle
  | $set_path{[]}
  | leave
| $unit_goal.xyz.init{XYZ}
| $goal <= $world.block_at{XYZ}
| if not $goal or ($worker and $goal.ai><remove and $owner.excavate_mark{@XYZ})
  then | $goal <= $unit_goal
       | less Act: when $worker:
         | X,Y,Z = XYZ
         | when $owner.excavate_mark{X Y Z}: Act <= \excavate
         | when $owner.work_at{XYZ}: Act <= \build
  else | Enemy = $owner.is_enemy{$goal.owner}
       | less Act or Enemy: $goal <= $unit_goal
       | when Enemy: Act <= $main.params.acts.attack
| $goal_act <= normalize_act Me Act
| $goal_serial <= $goal.serial
| $set_path{$path_to{$goal.xyz}}

in_range Me XYZ =
| less (XYZ.take{2}-$xyz.take{2}).abs<<$range.float: leave 0
| $world.seen_from{$xyz $goal.xyz}

unit.targets_in_range Range = $world.targets_in_range{Me.xyz Range}

retaliate Me Enemy Range =
| when $owner.human and not $idle: leave
| when Enemy.empty: leave
| when Range:
  | for U $targets_in_range{Range}:
    | when U.id<>$id and U.damage and U.owner.id><$owner.id:
      | retaliate U Enemy 0
| when $goal and ($goal.damage or $goal.leader):
  | when ($goal.xyz-Me.xyz).abs << (Enemy.xyz-Me.xyz).abs:
    | leave
| less $damage: leave
| $order_at{Enemy.xyz}
| $backtrack <= $xyz
| leave

heal_unit Me Amount =
| less $class.hp: leave
| !$hp + | min Amount $class.hp-$health

unit.assault Combat Target =
| Hit = 0
| Magic = 0
| Damage = No
| while Combat.is_list:
  | case Combat
    [_ unavoid C]
      | Damage <= C
      | Hit <= 1
    [_ magic C]
      | Damage <= C
      | Hit <= 1
      | Magic <= 1
    [_ damage C]
      | Combat <= C.0
      | Damage <= C.1
| less Hit
  | when Combat<<0: leave
  | Roll = $world.rand{Combat+Target.armor*2}
  | Hit <= Roll<Combat
| less Hit: leave
| when no Damage: Damage <= max 1 $health/2
| less Magic:
  | $run_effects{?><attack Me $xyz}
  | Mod = $mod
  | $mod <= 0
  | case Mod [`.` boost [N M]]: Damage <= max 1 Damage*N/M
| if Magic then Target.harm{Me Damage 1} else Target.harm{Me Damage}

unit.harm Attacker Damage @Magic =
| when $removed: leave
| less $alive: leave
| when Attacker and $leader><1 and $owner.id<>0:
  | when not $owner.human and Attacker.owner.id><0:
    | Attacker.harm{Me 1000}
    | leave //roaming neutral units wont harm AI leader
| when Damage << 0:
  | heal_unit Me -Damage
  | leave
| Mg = not Magic.end
| when Damage>0:
  | $run_effects{?><harm Me $xyz}
  | if Mg then $run_effects{?><magic_harm Me $xyz}
    else $run_effects{?><phys_harm Me $xyz}
| Mod = $mod
| $mod <= 0
| case Mod
  [`.` block [N M]]
     | when Damage>1: Damage <= max 1 | Damage - | max 1 Damage*N/M
  [`.` block N] | when Damage>1: Damage <= max 1 Damage-N
| !$hp - Damage
| less $owner.human: $owner.ai.harm{Attacker Me}
| when $hp > 0:
  | Effect = $class.hit
  | when Effect: $effect{Effect Me $xyz}
  | when $anim><idle or $anim><move: $animate{hit}
  | when Attacker and $owner.is_enemy{Attacker.owner}:
    | retaliate Me Attacker 5
  | leave
| when Attacker:
  | AO = Attacker.owner
  | when $owner.id <> AO.id: !AO.lore+$tier
  | !$owner.params.lossage+$tier
  | !Attacker.kills+1
| $die
| $action.cycles <= 1

unit_moved_in Me =
| C = $cell
| for U C.units: when U.item.is_list:
  | U.effect{U.item Me Me.xyz}
| when (C-1).tile.storage: $owner.capture{C-1}

unit.fine_move FXYZ =
| C = $world.c
| XYZ = [FXYZ.0/C FXYZ.1/C FXYZ.2/C]
| $from.init{$xyz}
| $remove
| $xyz.init{XYZ}
| C = $world.c
| $fxyz.init{FXYZ}
| $world.place_unit{Me}
| $floor <= $cell.floor
| $environment_updated
| when $ai >< unit: unit_moved_in Me
| Me

unit.move XYZ =
| C = $world.c
| $fine_move{[XYZ.0*C XYZ.1*C XYZ.2*C]}
| when $class.active: $run_effects{?><move Me $xyz}
| Me

unit.remove =
| when $removed: leave
| $world.remove_unit{Me}
| $xyz.2 <= -1

unit.environment_updated =

unit.face XYZ =
| XY = (XYZ-$xyz).take{2}{?sign}
| less XY >< [0 0]: $facing <= Dirs.locate{(XYZ-$xyz).take{2}{?sign}}

unit.sound SoundName =
| when not $id or (not $removed and $world.human.explored{$xyz}>1):
  | CXYZ = $main.ui.view.center
  | V = 1.0 / | max 1.0 (CXYZ - $xyz).abs*0.5
  | when V>0.01: $main.sound{SoundName volume/V}

export unit init_unit_module
