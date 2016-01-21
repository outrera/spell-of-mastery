use util macros unit_flags

type cell_goal xyz/[0 0 0] serial

cell_goal.type = \goal
cell_goal.removed = 0
cell_goal.alive = 1

type unit.$class{Id World}
  id/Id
  world/World
  name
  serial
  class
  fxyz/[0 0 0] // fine X,Y,Z
  xyz/[0 0 -1] // world cell X,Y,Z
  fix_z/0
  from/[0 0 0]
  anim // animation id
  anim_step // frame index inside of current animation
  anim_seq // current animation sequence
  anim_wait // cycles till the next animation frame
  frame
  facing // direction this unit faces
  owner // player controlling this unit
  action // currently executing action
  next_action // action to be taken after the current one
  ordered // what owner of this unit has ordered
  cooldown
  sprite
  mirror // true, if drawing code should mirror the sprite
  mark // next mark in the map marks chain
  active // true if this unit resides in the list of active units
  slope // unit is standing on a sloped terrain
  path/[] // path to goal
  path_life
  goal
  goal_serial
  goal_act
  unit_goal/cell_goal{}
  hp // hit points
  flags
  alpha //how transparent is this unit
  delta //change of transparency per cycle
  kills //how many enemies this unit has killed
  effects/[] //active effects
  mod //set by various effects to modify some contextual behavior
  host //what unit hosts this sprite
  host_serial
  colors/0
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

unit.flyer = $flags^get_bit{5}
unit.`!flyer` State = $flags <= $flags^set_bit{5 State}

unit.alive = $hp > 0
unit.health =
| CHP = $class.hp
| less CHP: leave 0
| UHP = $hp
| when UHP << 0: leave 0 
| R = UHP%CHP
| less R: R <= CHP
| R


unit.move_in State =
| when $item <> pickup: leave
| for U $world.units_at{$xyz}: when U.item and U.item <> pickup:
  | Add = if U.show then [effect,pickup sound,pickup remove,self] else []
  | U.effect{[@Add @U.item] Me Me.xyz}

//FIXME: when serials get exhausted, compress serial space
unit.init Class =
| $class <= Class
| $sprite <= if $show or $world.mode <> play
             then $default_sprite
             else $world.nil.sprite
| $facing <= 3
| $mirror <= 0
| $serial <= $world.serial
| !$world.serial + 1
| $animate{idle}
| $mark <= 0
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
  | $action.cycles <= 0
  | $unit_goal.serial <= $serial
  | $path_life <= 0
  | for E $inborn: case E
      [`{}` Name Duration @Args] | $add_effect{Name Duration [inborn @Args]}
      Else | $add_effect{E 0 [inborn]}

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
| When = On.1
| Es = @enheap [[When Name Duration Params] @$effects.list]
| $effects.heapfree
| $effects <= Es
| Flag = getUnitFlagsTable{}.Name
| when got Flag: $flags <= $flags^set_bit{Flag 1}

unit.has Name = got $effects.find{?1><Name}

unit.cooldown_of ActName =
| E = $effects.find{E => E.1><cool and E.3.1.1.0><ActName}
| if got E then [E.2 E.3.1.1.1] else 0

unit.strip_effect Name =
| less $has{Name}: leave
| Es = @enheap $effects.skip{?1><Name}
| $effects.heapfree
| $effects <= Es
| Flag = getUnitFlagsTable{}.Name
| when got Flag: $flags <= $flags^set_bit{Flag 0}

unit.add_item Amount Name =
| when Amount > 0:
  | $add_effect{Name -Amount []}
  | leave
| for E $effects: case E [When EName Duration Params]: when EName><Name:
  | !Duration-Amount
  | when Duration >> -1:
    | $strip_effect{Name}
    | leave
  | E.2 <= Duration
  | leave

unit.run_effects Selector Target TargetXYZ =
| Es = []
| for [When Name Duration Params] $effects: when Selector When:
  | Effect = get_named_effect Target Name Params
  | when Effect:
    | push Effect Es //cuz invoking it here may clobber $effects
| for Effect Es: $effect{Effect Target TargetXYZ}

unit.`!backtrack` XYZ =
| less XYZ:
  | $strip_effect{btrack}
  | leave
| when $has{btrack}: leave
| $add_effect{btrack 0 [inborn [effect [on [`.` cycle 24]] [btrack XYZ]]]}

unit.change_owner NewOwner =
| $owner.lost_unit{Me}
| $owner <= NewOwner
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

player_lost_leader Me Leader =
| Leaders = []
| RemainingUnits = []
| for U $world.active.list: when U.id <> Leader.id:
  | when U.leader><1: push U Leaders
  | when U.owner.id >< $id: push U RemainingUnits
| case Leaders [L@Ls]: when Ls.all{?owner.id><L.owner.id}:
  | $world.params.winner <= L.owner.id
  | $world.params.victory_type <= 'Victory by defeating other leaders.'
| when Leader.owner.human: less Leaders.any{?owner.human}:
  | $world.params.winner <= 0
  | $world.params.victory_type <= 'Defeat by losing your leader.'
| less RemainingUnits.any{?leader><1}: for U RemainingUnits: U.free

respawn_leader Me XYZ =
| Block = $world.block_at{XYZ}
| when got Block and $owner.is_enemy{Block.owner}: leave 0
| when $owner.mana << 0: leave 0
| Cost = $main.params.world.death_cost
| !$owner.mana - Cost
| $owner.notify{"death cost you [Cost] mana"}
| S = $owner.alloc_unit{$type}
| S.nonguard <= 0
| S.alpha <= 255
| S.delta <= -25
| S.move{XYZ}
| S.main.ui.view.center_at{XYZ}
| S.owner.leader <= S
| $world.effect{XYZ teleport}
| 1

unit.free =
| when $picked: $owner.picked <= $owner.picked.skip{?id><$id}
| when $owner: $owner.lost_unit{Me}
| when $leader><1:
  | $owner.leader <= 0
  | when $hp << 0:
    | P = $owner.pentagram
    | less P and respawn_leader Me P.xyz: player_lost_leader $owner Me
| when $active: $active <= 2 //request removal from active list
| less $path.end: $set_path{[]}
| $goal <= 0
| $host <= 0
| $colors <= 0
| $effects.heapfree
| $effects <= []
| $world.free_unit{Me}

unit.remove =
| when $xyz.2 <> -1:
  | when $passable and $block: $world.clear_tile{$xyz $world.void}
  | $move_in{0}
| $world.remove_unit{Me}
| $xyz.2 <= -1

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
| $cooldown <= 0

unit.set_path Path =
| $path_life <= Path.size/4
| P = Path.enheap
| $path.heapfree
| $path <= P

unit.order_at XYZ act/0 =
| when $xyz >< XYZ:
  | $goal <= 0
  | $goal_act <= 0 //if Act then Act else $main.params.acts.idle
  | $set_path{[]}
  | leave
| $unit_goal.xyz.init{XYZ}
| $goal <= $world.block_at{XYZ}
| if no $goal
  then | $goal <= $unit_goal
  else | Enemy = $owner.is_enemy{$goal.owner}
       | less Act or Enemy: $goal <= $unit_goal
       | when Enemy: Act <= $main.params.acts.attack
| $goal_act <= if Act.is_text then $main.params.acts.Act
               else if Act then Act
               else $main.params.acts.move
| $goal_serial <= $goal.serial
| $set_path{$path_to{$goal.xyz}}

in_range Me XYZ =
| less (XYZ.take{2}-$xyz.take{2}).abs<<$range.float: leave 0
| $world.seen_from{$xyz $goal.xyz}

retaliate Me Enemy =
| less $idle: leave
| when $goal and ($goal.xyz-Me.xyz).abs << (Enemy.xyz-Me.xyz).abs:
  | leave
| less $damage: leave
| when $action.type><idle:
  | $order_at{Enemy.xyz}
  | $backtrack <= $xyz
  | leave
| less $action.type><attack: leave
| less $range:
  | when (Enemy.xyz-Me.xyz){?abs}.sum><1:
    | when $goal and ($goal.xyz-Me.xyz){?abs}.sum><1: leave
    | $order.init{attack Enemy}
    | leave
| when $range and in_range Me Enemy.xyz:
  | $order.init{attack Enemy}
  | leave

heal_unit Me Amount =
| less $class.hp: leave
| !$hp + | min Amount $class.hp-$health

unit.harm Attacker Damage =
| when Attacker and $leader><1 and $owner.id<>0:
  | when not $owner.human and Attacker.owner.id><0:
    | Attacker.harm{Me 1000}
    | leave //roaming neutral units wont harm AI leader
| less $alive: leave
| Piercing = 0
| case Damage [_ piercing D]
  | Damage <= D
  | Piercing <= 1
| $run_effects{?><attacked Me $xyz}
| Mod = $mod
| $mod <= 0
| when Damage << 0:
  | heal_unit Me -Damage
  | leave
| less Piercing: Damage <= max 1 Damage-$armor
| when Mod >< block: leave
| !$hp - Damage
| when!it $blood:
  | E = $world.effect{$xyz it}
  | E.fxyz.init{$fxyz}
| less $owner.human: $owner.ai.harm{Attacker Me}
| when $hp > 0:
  | Effect = $class.hit
  | when Effect: $effect{Effect Me $xyz}
  | when $anim><idle or $anim><move: $animate{hit}
  | when Attacker and $owner.is_enemy{Attacker.owner}:
    | retaliate Me Attacker
  | leave
| when Attacker:
  | AO = Attacker.owner
  | when $owner.id <> AO.id: !AO.lore+$tier
  | !$owner.params.lossage+$tier
  | !Attacker.kills+1
| $die
| $action.cycles <= 1

unit.fine_move FXYZ =
| C = $world.c
| XYZ = [FXYZ.0/C FXYZ.1/C FXYZ.2/8]
| $from.init{$xyz}
| $remove
| $xyz.init{XYZ}
| $fix_z <= $world.fix_z{XYZ}
| C = $world.c
| $fxyz.init{FXYZ}
| $world.place_unit{Me}
| when $passable and $block:
  | $world.set{@$xyz $block}
| $environment_updated
| $move_in{1}
| Me

unit.move XYZ =
| C = $world.c
| $fine_move{[XYZ.0*C XYZ.1*C XYZ.2*8]}

unit.seen = $world.seen{$xyz.0 $xyz.1}

unit.environment_updated =
| UX,UY,UZ = $xyz
| $slope <= $world.slope_at{UX UY UZ-1}^|$1 #@1111 => 0

unit.face XYZ =
| XY = (XYZ-$xyz).take{2}{?sign}
| less XY >< [0 0]: $facing <= Dirs.locate{(XYZ-$xyz).take{2}{?sign}}

export unit