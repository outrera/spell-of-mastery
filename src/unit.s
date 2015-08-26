use util action macros

type unit.$class{Id World}
  id/Id
  world/World
  name
  serial
  class
  xyz/[0 0 -1] // world coordinates
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
  moved // last turn, this unit moved
  mirror // true, if drawing code should mirror the sprite
  picked // cons of the next unit in the selection
  mark // next mark in the map marks chain
  active // true if this unit resides in the list of active units
  slope // unit is standing on a sloped terrain
  movement_render_hack
  path // next unit in path
  hits // how damaged is this unit
  turn // turn it was created
  flags
| $action <= action Me
| $next_action <= action Me
| $ordered <= action Me

unit.as_text = "#unit{[$type] [$id]}"

unit.main = $world.main

unit.attacker = $flags.get{0}
unit.`!attacker` State = $flags <= $flags.set{0 State}

unit.handled = $flags.get{1}
unit.`!handled` State = $flags <= $flags.set{1 State}

unit.summoned = $flags.get{2}
unit.`!summoned` State = $flags <= $flags.set{2 State}

unit.haste = $flags.get{3}
unit.`!haste` State = $flags <= $flags.set{3 State}

unit.shell = $flags.get{4}
unit.`!shell` State = $flags <= $flags.set{4 State}

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
| $picked <= 0
| $mark <= 0
| $path <= 0
| $hits <= 0
| $moved <= 0
| $turn <= $world.turn
| $flags <= 0
| $from.init{0,0,-1}
| when $starts
  | less $active
    | $world.active.push{Me}
    | $active <= 1
  | $ordered.type <= 0
  | $next_action.type <= 0
  | $action.init{idle 0,0,0}
  | $action.cycles <= 0

unit.change_owner NewOwner =
| $owner.lost_unit{Me}
| $owner <= NewOwner
| NewOwner.got_unit{Me}

unit.idle = not $ordered.type and
           [$action $next_action].all{?type^~{0 idle} >< idle}

//FIXME: move these into sprite loading code
AngleReplacements = [6,1 6,1 3,0 -1,0 3,1 3,1 3,1 6,0]

unit.pick_facing F =
| $facing <= F
| FrameIndex = $anim_seq.$anim_step.0
| Frame = $sprite.frames.FrameIndex
| less Frame.is_list
  | $frame <= Frame
  | when $facing <> 3: $mirror <= 1
  | leave
| $mirror <= 0
| Angle = $facing
| till Frame.Angle
  | $mirror <= AngleReplacements.Angle.1
  | Angle <= AngleReplacements.Angle.0
| $frame <= Frame.Angle

unit.animate Anim =
| $anim <= Anim
| $anim_seq <= $sprite.anims.$anim
| less got $anim_seq: $anim_seq <= $sprite.anims.idle
| $anim_step <= 0
| $pick_facing{$facing}
| $anim_wait <= $anim_seq.$anim_step.1

unit.free =
| when $id >< $world.waiting: $world.waiting <= 0
| when $owner: $owner.lost_unit{Me}
| when $leader><1 and $hits >> $health:
  | O = $owner
  | Leaders = []
  | for U $world.active.list:
    | if U.owner.id >< O.id
      then when U.id <> $id: U.free
      else when U.leader><1: push U Leaders
  | case Leaders [L]
    | $world.params.winner <= L.owner.id
    | $world.params.victory_type <= 'Victory by defeating other leaders.'
| $active <= 0
| $world.free_unit{Me}

unit.remove =
| when $xyz.2 <> -1: $move_in{0}
| $world.remove_unit{Me}
| $xyz.2 <= -1

unit.removed = $xyz.2 >< -1

unit.order = $ordered

unit.order_act Act = $order.init{target Me @Act.list.join}

unit.guess_order_at_mark Mark =
| XYZ = Mark.xyz
| Us = $world.units_at{XYZ}
| Path = cons path: map M Mark^uncons{path}.lead.flip
  | Node = $world.alloc_unit{mark_node owner/$owner}
  | Node.move{M.xyz}
  | Node
| case Mark.type
  mark_move
    | $order.init{type/move at/XYZ path/Path}
  mark_attack
    | Target = Us.skip{?empty}.0
    | $order.init{type/attack target/Target at/XYZ path/Path}
  mark_swap
    | Target = Us.skip{?empty}.0
    | $order.init{type/swap target/Target at/XYZ path/Path}
  Else | leave 0
| 1

unit.guess_order_at XYZ =
| Marks = $world.units_at{XYZ}.keep{?mark}
| for Mark Marks: when $guess_order_at_mark{Mark}: leave

unit.move XYZ =
| $from.init{$xyz}
| $remove
| $xyz.init{XYZ}
| $xy.init{0,0}
| $world.place_unit{Me}
| $environment_updated
| $move_in{1}
| Me

unit.seen =
| X = $xyz.0
| Y = $xyz.1
| $world.human.sight.Y.X

unit.environment_updated =
| [UX UY UZ] = $xyz
| $slope <= $world.slope_at{UX,UY,UZ-1}^|$1 #@1111 => 0

unit.face XYZ =
| XY = (XYZ-$xyz).take{2}{?sign}
| less XY >< [0 0]: $facing <= Dirs.locate{(XYZ-$xyz).take{2}{?sign}}


world.can_move Src Dst =
| when Dst.2 < 1: leave 0
| less $fast_at{Src}.empty and $fast_at{Dst}.empty: leave 0
| SZ = Src.2
| DX,DY,DZ = Dst
| Height = DZ-SZ
| HeightAbs = Height.abs
| BelowDst = DX,DY,DZ-1
| when HeightAbs < 4: leave: $slope_at{BelowDst}><#@1111
                             or $fast_at{BelowDst}.stairs
| BelowDstTile = $fast_at{BelowDst}
| when BelowDstTile.stairs: leave HeightAbs << 4
| SX = Src.0
| SY = Src.1
| BelowSrc = SX,SY,SZ-1
| BelowSrcTile = $fast_at{BelowSrc}
| when BelowSrcTile.stairs and Height<0: leave HeightAbs << 4
| 0

MoveMapDirMap =
| T = dup 4: dup 4: dup 10: 0
| I = 0
| for Z [-4 -3 -2 -1 0 1 2 3 4]:
  | for X,Y [[1 0] [-1 0] [0 1] [0 -1]]
    | T.(X+1).(Y+1).(Z+4) <= I
    | !I+1
| T

world.update_move_map P =
| SX,SY = P
| when SX < 1 or SY < 1: leave 0
| for SZ $height{SX SY}
  | SZ = SZ+1
  | Src = SX,SY,SZ
  | M = 0
  | for Z [-4 -3 -2 -1 0 1 2 3 4]:
    | for X,Y [[1 0] [-1 0] [0 1] [0 -1]]:
      | when $can_move{Src Src+[X Y Z]}
        | F = MoveMapDirMap.(X+1).(Y+1).(Z+4) 
        | M <= M ++ (1</F)
  | $move_map.set{Src M}

unit.can_move Src Dst =
| when $flyer: leave $world.fast_at{Dst}.empty // FIXME: check for roof
| M = $world.move_map.at{Src}
| X,Y,Z = Dst-Src
| when Z.abs > 4: leave 0
| F = MoveMapDirMap.(X+1).(Y+1).(Z+4) 
| M^^(1</F)


type move{type src xyz}
move.as_text = "#move{[$type] [$src] [$xyz]}"

unit.list_moves XYZ =
| less $moves.size: leave []
| Moves = []
| I = 0
| OMs = $moves
| Ms = OMs.deep_copy
| O = Ms.size/2
| StackSrc = []
| StackDst = []
| for N [[O O-1] [O+1 O] [O O+1] [O-1 O]]:
  | X,Y = N
  | Xs = Ms.Y
  | when Xs.X
    | Xs.X <= 0
    | push XYZ StackSrc 
    | push N StackDst
| till StackDst.end
  | Src = pop StackSrc
  | DX,DY = pop StackDst
  | V = OMs.DY.DX
  | Dst = [XYZ.0+DX-O XYZ.1+DY-O Src.2]
  | Move = 0
  | less $world.fast_at{Dst}.empty:
    | I = 0
    | till I><4 or $world.fast_at{Dst}.empty:
      | !Dst.2 + $world.fast_at{Dst}.height
      | !I+1
  | !Dst.2 - 1
  | while $world.fast_at{Dst}.empty: !Dst.2 - 1
  | !Dst.2 + 1
  | Blocked = 0
  | less $world.no_block_at{Dst} and $can_move{Src Dst}:
    | when got!it $world.block_at{Dst}:
      | when $can_move{Src Dst}
        | if $owner.id >< it.owner.id
          then | when it.moves.size and it.can_move{Dst Src} and V <> 2:
                 | Move <= move swap Src Dst
          else | when it.hits < it.health and it.defense < $attack and V < 3:
                 | Move <= move attack Src Dst
    | Blocked <= 1
  | less Blocked
    | Move <= if V><2 then move node Src Dst else move move Src Dst
    | for N [[DX DY-1] [DX+1 DY] [DX DY+1] [DX-1 DY]]:
      | X,Y = N
      | Xs = Ms.Y
      | when Xs.X
        | Xs.X <= 0
        | push Dst StackSrc
        | push N StackDst
  | when Move: push Move Moves
| Moves.list

unit.list_attack_moves XYZ =
| less $attack: leave []
| Map = $moves
| $moves <= Map.deep_copy
| for Xs $moves: for I Xs.size: when Xs.I >< 2: Xs.I <= 1
| Ms = $list_moves{XYZ}
| $moves <= Map
| O =  Map.size/2
| OO = [O O 0]
| Map = $moves
| Ms.keep{M => 
          | X,Y,Z = OO+M.xyz-XYZ
          | V = Map.Y.X
          | V >< 1 or V >< 2}

unit.mark_moves @As =
| XYZ = if As.size then As.0 else $xyz
| Moves = $list_moves{XYZ}
| Marks = map Move Moves
  | Mark = $world.alloc_unit{"mark_[Move.type]" owner/$owner}
  | Mark.move{Move.xyz}
  | Src = Move.src
  | Mark.path <= if Src >< XYZ then 0 else Move.src
  | Mark
| for M Marks: when M.path: for N Marks: when M.path >< N.xyz: M.path <= N
| Marks

// order taking over any other order
unit.forced_order @As =
| O = $order.init{@As}
| O.priority <= 1000
| O.speed <= 0
| O

unit.die =
| when got!it $sounds.die: $main.sound{it.rand}
| $world.waiting <= $id
| $forced_order{type/die}

unit.harm Attacker Damage =
| when $shell and Damage > 0:
  | $shell <= 0
  | leave
| !$hits + Damage
| less $owner.human: $owner.ai.harm{Attacker Me}
| when $hits < $health:
  | if Damage >> 0
    then | when got!it $sounds.hit: $main.sound{it.rand}
         | $animate{hit}
    else when $hits << 0: $hits <= 0
  | leave
| $die
| $action.cycles <= 1


unit.render Heap X Y =
| G = $frame
| when G.w >< 1: leave// avoid drawing dummies
| XX = X+32-G.w/2 + $xy.0
| YY = Y-16-G.h+$slope*16 + $xy.1
| when $mirror: G.flop
| UX,UY,UZ = $xyz
| when $movement_render_hack
  | !UX+1
  | !UY+1
| Key = ((max UX UY)</54) + ((UX*128+UY)</38) + ((UZ*2-1)</30)
       + ((UX+$draw_order)</22) + $serial
| Shadow = $sprite.shadow
| when Shadow
  | Heap.push{Key-1 [Shadow X+$xy.0+8 Y+$xy.1-38 0]}
| when $picked and $world.player.id >< $owner.id:
  | Wave = @int 20.0*(@sin: ($world.cycle%100).float/100.0*PI)
  | Mark = $main.img{ui_picked_mark}
  | PH = $sprite.pick_height
  | less PH: PH <= $height*8+16
  | PH <= PH + Mark.h + Wave
  | Heap.push{Key+1 [Mark X+$xy.0+32-Mark.w/2 Y+$xy.1-PH 0]}
| Heap.push{Key [G XX YY 0]}


export unit