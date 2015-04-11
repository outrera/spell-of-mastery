use util action macros

type unit.$class{Id World}
  id/Id
  world/World
  name
  serial
  class
  xyz/[0 0 -1] // world coordinates
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
  hits // how damages is this unit
| $action <= action Me
| $next_action <= action Me
| $ordered <= action Me

unit.as_text = "#unit{[$type] [$id]}"

unit.main = $world.main

//FIXME: when serials get exhausted, compress serial space
unit.init Class =
| $class <= Class
| $sprite <= $default_sprite
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
| when $starts
  | less $active
    | $world.active.push{Me}
    | $active <= 1
  | $ordered.class <= 0
  | $next_action.class <= 0
  | $action.init{idle 0,0,0}
  | $action.cycles <= 0

unit.idle = not $ordered.class and
           [$action $next_action].all{?class_name^~{0 idle} >< idle}

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
| when $leader and $hits >> $health:
  | O = $owner
  | for U $world.active.list: when U.owner.id >< O.id and U.id <> $id:
    | U.free
| $world.free_unit{Me}

unit.remove =
| $world.remove_unit{Me}
| $xyz.2 <= -1

unit.removed = $xyz.2 >< -1

unit.order = $ordered

unit.guess_order_at_mark Mark =
| XYZ = Mark.xyz
| Us = $world.units_at{XYZ}
| Path = cons path: map M Mark^uncons{path}.lead.flip
  | Node = $world.alloc_unit{mark_node}
  | Node.move{M.xyz}
  | Node
| case Mark.type
  mark_move
    | $order.init{act/move at/XYZ path/Path}
  mark_attack
    | Target = Us.skip{?empty}.0
    | $order.init{act/attack target/Target at/XYZ path/Path}
  mark_swap
    | Target = Us.skip{?empty}.0
    | $order.init{act/swap target/Target at/XYZ path/Path}
  Else | leave 0
| 1

unit.guess_order_at XYZ =
| Marks = $world.units_at{XYZ}.keep{?mark}
| for Mark Marks: when $guess_order_at_mark{Mark}: leave

unit.move XYZ =
| $remove
| $xyz.init{XYZ}
| $xy.init{0,0}
| $world.place_unit{Me}
| $environment_updated
| Me

unit.environment_updated =
| [UX UY UZ] = $xyz
| $slope <= $world.slope_at{UX,UY,UZ-1}^|$1 #@1111 => 0

unit.face XYZ =
| $facing <= Dirs.locate{(XYZ-$xyz).take{2}{?sign}}


unit.can_move Src Dst =
| less $world.fast_at{Dst}.empty: leave 0
| SZ = Src.2
| DZ = Dst.2
| Height = DZ-SZ
| HeightAbs = Height.abs
| when HeightAbs << $jumps: leave 1
| DX = Dst.0
| DY = Dst.1
| BelowDst = DX,DY,DZ-1
| BelowDstTile = $world.fast_at{BelowDst}
| when BelowDstTile.stairs: leave HeightAbs << (max 4 $jumps)
| SX = Src.0
| SY = Src.1
| BelowSrc = SX,SY,SZ-1
| SlopedSrc = $world.slope_at{BelowSrc}<>#@1111
| BelowSrcTile = $world.fast_at{BelowSrc}
| when BelowSrcTile.stairs and Height<0: leave HeightAbs << (max 4 $jumps)
| 0


type move{type src xyz}
move.as_text = "#move{[$type] [$src] [$xyz]}"

unit.list_moves XYZ =
| less $moves.size: leave []
| Moves = []
| I = 0
| Ms = $moves.deep_copy
| O = Ms.size/2
| StackSrc = []
| StackDst = []
| XY = O,O
| for N [[O O-1] [O+1 O] [O O+1] [O-1 O]]:
  | X,Y = N
  | Ys = Ms.X
  | when Ys.Y
    | Ys.Y <= 0
    | push XY StackSrc 
    | push N StackDst
| till StackDst.end
  | SX,SY = pop StackSrc
  | DX,DY = pop StackDst
  | Src = XYZ + [SX-O SY-O 0]
  | Dst = XYZ + [DX-O DY-O 0]
  | Move = 0
  | !Dst.2 - 1
  | while $world.fast_at{Dst}.empty: !Dst.2 - 1
  | !Dst.2 + 1
  | less $can_move{Src Dst}
    | AboveDst = Dst + [0 0 $world.fast_at{Dst}.height]
    | when $can_move{Src AboveDst}: Dst <= AboveDst
  | Blocked = 0
  | less $world.no_block_at{Dst} and $can_move{Src Dst}:
    | when got!it $world.block_at{Dst}:
      | when $can_move{Src Dst}
        | if $owner.id >< it.owner.id
          then | when and it.moves.size
                      and it.can_move{Dst Src}:
                 | Move <= move swap Src Dst
          else when it.hits < it.health and it.defense < $attack:
               | Move <= move attack Src Dst
    | Blocked <= 1
  | less Blocked
    | Move <= move move Src Dst
    | XY = DX,DY
    | for N [[DX DY-1] [DX+1 DY] [DX DY+1] [DX-1 DY]]:
      | X,Y = N
      | Ys = Ms.X
      | when Ys.Y
        | Ys.Y <= 0
        | push XY StackSrc
        | push N StackDst
  | when Move: push Move Moves
| Moves.list


unit.mark_moves @As =
| XYZ = if As.size then As.0 else $xyz
| Moves = $list_moves{XYZ}
| Marks = map Move Moves
  | Mark = $world.alloc_unit{"mark_[Move.type]"}
  | Mark.move{Move.xyz}
  | Src = Move.src
  | Mark.path <= if Src >< XYZ then 0 else Move.src
  | Mark
| for M Marks: when M.path: for N Marks: when M.path >< N.xyz: M.path <= N
| Marks

unit.render Heap X Y =
| G = $frame
| when G.w >< 1: leave// avoid drawing dummies
| XX = X+32-G.w/2 + $xy.0
| YY = Y-16-G.h+$slope*16 + $xy.1
| FlipX = $mirror
| Flags = FlipX
| UX,UY,UZ = $xyz
| when $movement_render_hack
  | !UX+1
  | !UY+1
| Key = ((UX+UY)</40) + ((UZ*2-1)</30) + ((UX+$draw_order)</21) + $serial
| when $picked
  | Wave = @int 20.0*(@sin: ($world.cycle%100).float/100.0*PI)
  | Mark = $main.img{ui_picked_mark}
  | PH = $sprite.pick_height
  | less PH: PH <= $height*8+16
  | PH <= PH + Mark.h + Wave
  | Heap.push{Key+1 [Mark X+$xy.0+32-Mark.w/2 Y+$xy.1-PH Flags]}
/*  //| !Flags ++ #2
  | H = $sprite.height
  | Heap.push{Key-1 [H X Y-32 #4000+(H</16)]}
  | Heap.push{Key+1 [H X Y-32 #8000+(H</16)]}*/
| Heap.push{Key [G XX YY Flags]}

export unit