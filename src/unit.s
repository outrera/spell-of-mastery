use util action

type unit.$class{Id World}
  id/Id // numeric id for octree
  world/World
  name
  serial
  class
  xyz/[0 0 -1] // world coordinates
  xy/[0 0] // fine X,Y
  next // next unit inside of this world cell
  column_next // next unit inside of this world column
  anim // animation id
  anim_step // frame index inside of current animation
  anim_seq // current animation sequence
  anim_wait
  frame
  facing // direction this unit faces
  mirror
  slope // unit is standing on a sloped terrain
  owner // player controlling this unit
  picked // cons of the next unit in the selection
  active // true if this unit resides in the list of active units
  action // currently executing action
  next_action // action to be taken after the current one
  ordered // what owner of this unit has ordered
  sprite
  moved
  movement_render_hack
| $action <= action Me
| $next_action <= action Me
| $ordered <= action Me

unit.as_text = "#unit{[$type] [$id]}"

unit.main = $world.main

unit.init Class =
| $class <= Class
| $sprite <= $default_sprite
| $facing <= 3
| $next <= 0
| $column_next <= 0
| $serial <= $world.serial
| !$world.serial + 1
| $animate{idle}
| $picked <= 0
| when $starts
  | less $active
    | $world.active.push{Me}
    | $active <= 1
  | $ordered.class <= 0
  | $next_action.class <= 0
  | $action.init{idle 0,0,0}
  | $action.cycles <= 0

//FIXME: move these into sprite loading code
AngleReplacements = [6,1 6,1 3,0 -1,0 3,1 3,1 3,1 6,0]

unit.pick_facing F =
| $facing <= F
| FrameIndex = $anim_seq.$anim_step.0
| Frame = $sprite.frames.FrameIndex
| less Frame.is_list
  | $frame <= Frame
  | leave
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

unit.free = $world.free_unit{Me}


unit.remove =
| $world.remove_unit{Me}
| $xyz.2 <= -1

unit.removed = $xyz.2 >< -1

unit.move XYZ =
| $remove
| $xyz.init{XYZ}
| $xy.init{0,0}
| $world.place_unit{Me}
| $environment_updated

unit.environment_updated =
| [UX UY UZ] = $xyz
| $slope <= $world.slope_at{UX,UY,UZ-1}^|$1 #@1111 => 0

unit.render Heap X Y =
| G = $frame
| when G.w >< 1: leave// avoid drawing dummies
| XX = X+32-G.w/2 + $xy.0
| YY = Y-16-G.h+$slope*16 + $xy.1
| FlipX = $mirror
| Flags = FlipX
| when $picked: !Flags ++ #2
| UX,UY,UZ = $xyz
| when $movement_render_hack
  | !UX+1
  | !UY+1
| Key = ((UX+UY)</40) + ((UZ*2-1)</30) + ((UX+$draw_order)</21) + $serial
| Heap.push{Key [G XX YY Flags]}

unit.order = $ordered

export unit