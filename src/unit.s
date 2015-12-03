use util action macros unit_flags

type unit.$class{Id World}
  id/Id
  world/World
  name
  serial
  class
  xyz/[0 0 -1] // world coordinates
  fix_z/0
  from/[0 0 0]
  xy/[0 0] // fine X,Y
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
  sprite
  moved // last turn, this unit moved, number of move points (when negative)
  mirror // true, if drawing code should mirror the sprite
  mark // next mark in the map marks chain
  active // true if this unit resides in the list of active units
  slope // unit is standing on a sloped terrain
  path/[] // path to goal
  goal
  hits // how damaged is this unit
  turn // turn it was created
  flags
  alpha //how transparent is this unit
  delta //change of transparency per cycle
  kills //how many enemies this unit has killed
  effects/[] //active effects
  mod //set by various effects to modify some contextual behavior
| $action <= action Me
| $next_action <= action Me
| $ordered <= action Me

unit.enheap = Me
unit.unheap = Me

unit.as_text = "#unit{[$type] [$id]}"

unit.main = $world.main

unit.attacker = $flags^get_bit{0}
unit.`!attacker` State = $flags <= $flags^set_bit{0 State}

unit.picked = $flags^get_bit{1}
unit.`!picked` State = $flags <= $flags^set_bit{1 State}

unit.summoned = $flags^get_bit{2}
unit.`!summoned` State = $flags <= $flags^set_bit{2 State}

unit.flyer = $flags^get_bit{5}
unit.`!flyer` State = $flags <= $flags^set_bit{5 State}

unit.alive = $hits < $health

world.income_at XYZ =
| for U $units_at{XYZ}:
  | when U.empty and U.income and U.owner.id >< 0:
    | leave U.income
| 0

// extort income from the territory occupied by the unit
unit.move_in State =
| when $item <> pickup: leave
| Income = $world.income_at{$xyz}
| if State then $owner.got_income{Income} else $owner.lost_income{Income}
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
| $hits <= 0
| $moved <= 0
| $turn <= $world.turn
| $flags <= 0
| $alpha <= 0
| $delta <= 0
| $kills <= 0
| $from.init{0,0,-1}
| when $starts
  | less $active
    | $world.active.push{Me}
  | $active <= 1
  | $ordered.type <= 0
  | $next_action.type <= 0
  | $action.init{idle 0,0,0}
  | $action.cycles <= 0
  | for E $inborn: case E
      [`{}` Name Duration @Args] | $add_effect{Name Duration [inborn @Args]}
      Else | $add_effect{E 0 [inborn]}

unit.add_effect Name Duration Params =
| Effect = $main.params.effect.Name
| when no Effect:
  | $world.notify{"unit.add_effect: missing effect [Name]"}
  | leave
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

unit.strip_effect Name =
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
  | Effect = Target.main.params.effect.Name
  | push Effect Es //because invoking effect here may clobber $effects
| for Effect Es: $effect{Effect Target TargetXYZ}

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
| when RemainingUnits.any{?leader}: for U RemainingUnits: U.free

respawn_leader Me XYZ =
| when $owner.mana << 0 or got $world.block_at{XYZ}: leave 0
| Cost = $main.params.world.death_cost
| !$owner.mana - Cost
| $owner.notify{"death cost you [Cost] mana"}
| S = $world.alloc_unit{$type owner/$owner}
| S.summoned <= 1
| S.alpha <= 255
| S.delta <= -25
| S.move{XYZ}
| S.main.ui.view.center_at{XYZ}
| S.owner.leader <= S
| $world.effect{XYZ teleport}
| 1

unit.free =
| when $picked: $owner.picked <= $owner.picked.skip{?id><$id}
| when $id >< $world.waiting: $world.waiting <= 0
| when $owner: $owner.lost_unit{Me}
| when $leader><1 and $hits >> $health:
  | P = $owner.pentagram
  | less P and respawn_leader Me P.xyz: player_lost_leader $owner Me
| when $active: $active <= 2 //request removal from active list
| $path.heapfree
| $path <= []
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
| $order.init{target Target @Act.list.join}

unit.guess_order_at XYZ =
| Ms = $list_moves{$xyz}.keep{?xyz><XYZ}
| when Ms.end: leave 0
| M = Ms.0
| Us = $world.units_at{XYZ}.skip{?empty}
| Target = if Us.end then 0 else Us.0
| $order.init{type/M.type at/XYZ target/Target}
| M

unit.move XYZ =
| $from.init{$xyz}
| $remove
| $xyz.init{XYZ}
| $fix_z <= $world.fix_z{XYZ}
| $xy.init{0,0}
| $world.place_unit{Me}
| when $passable and $block:
  | $world.set{@$xyz $block}
  | XY = $xyz.take{2}
  | $world.update_move_map{XY}
| $environment_updated
| $move_in{1}
| Me

unit.seen = $world.seen{$xyz.0 $xyz.1}

unit.environment_updated =
| UX,UY,UZ = $xyz
| $slope <= $world.slope_at{UX UY UZ-1}^|$1 #@1111 => 0

unit.face XYZ =
| XY = (XYZ-$xyz).take{2}{?sign}
| less XY >< [0 0]: $facing <= Dirs.locate{(XYZ-$xyz).take{2}{?sign}}

type move{type xyz}
move.as_text = "#move{[$type] [$xyz]}"

Dir4 = [[0 -1] [1 0] [0 1] [-1 0]]

unit.list_moves Src =
| less $moves: leave []
| Ms = []
| SX,SY,SZ = Src
| for DX,DY Dir4
  | X = SX+DX
  | Y = SY+DY
  | Z = SZ
  | less $world.at{X Y Z}.type >< border:
    | Z <= $world.fix_z{X,Y,Z}
    | Dst = [X Y Z]
    | B = $world.block_at{Dst}
    | if got B then
        | if $owner.id <> B.owner.id
          then when B.hits < B.health and $attack>0 and (SZ-Z).abs<<4:
               | push move{attack Dst} Ms
          else when B.moves and $can_move{Src Dst} and B.can_move{Dst Src}:
               | push move{swap Dst} Ms //when B cant move to Src, ask B to move back
      else when $can_move{Src Dst}: push move{move Dst} Ms
| Ms

unit.list_attack_moves XYZ =
| less $attack: leave []
| $list_moves{XYZ}.keep{?type><attack}

// order taking over any other order
unit.forced_order @As =
| O = $order.init{@As}
| O.priority <= 1000
| O.speed <= 0
| O

unit.die =
| $sound{die}
| $world.waiting <= $id
| $forced_order{type/die}

unit.harm Attacker Damage =
| when Attacker and $leader><1 and Me.owner.id<>0:
  | when not $owner.human and Attacker.owner.id><0:
    | Attacker.harm{Me 1000}
    | leave //roaming neutral units wont harm AI wizard
| less $hits < $health: leave
| case Damage
  [_ piercing D] | Damage <= D
  Else | when Damage > 0: Damage <= max 1 Damage-$defense
| $run_effects{?><attacked Me $xyz}
| Mod = $mod
| $mod <= 0
| when Mod >< block: leave
| !$hits + Damage
| less $owner.human: $owner.ai.harm{Attacker Me}
| when $hits < $health:
  | if Damage >> 0
    then | $sound{hit}
         | $animate{hit}
    else when $hits << 0: $hits <= 0
  | leave
| when Attacker:
  | AO = Attacker.owner
  | when $owner.id <> AO.id: !AO.lore+$tier
  | !$owner.params.lossage+$tier
  | !Attacker.kills+1
| $die
| $action.cycles <= 1

unit.sound Type =
| less $world.human.explored{$xyz}>1: leave
| when got!it $sounds.Type: $main.sound{it.rand}


export unit