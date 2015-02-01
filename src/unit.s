use util action

type unit.$class{Id World}
  id/Id // numeric id for octree
  world/World
  serial
  class
  xyz/[0 0 -1] // world coordinates
  xy/[0 0] // fine X,Y
  next // next unit inside of this world cell
  column_next // next unit inside of this world column
  anim // animation id
  anim_step // frame index inside of current animation
  anim_seq // current animation sequence
  frame
  facing // direction this unit faces
  slope // unit is standing on a sloped terrain
  flipX
  owner // player controlling this unit
  picked // cons of the next unit in the selection
  active // cons used to hold this unit inside the world active units list
  deactivated
  action // currently executing action
  next_action // action to be taken after the current one
  ordered // what owner of this unit has ordered
  sprite
| $action <= action Me
| $next_action <= action Me
| $ordered <= action Me

unit.as_text = "#unit{[$type] [$id]}"

unit.main = $world.main

unit.init Class =
| $class <= Class
| $sprite <= $default_sprite
| $flipX <= 0
| $facing <= 0
| $next <= 0
| $column_next <= 0
| $serial <= $world.serial
| !$world.serial - 1
| $animate{still}
| $picked <= 0
| $deactivated <= 1
| when $starts
  | less $active: $active <= $world.active
  | $deactivated <= 0
  | $world.active <= Me
  | $ordered.class <= 0
  | $next_action.class <= 0
  | $action.init{still 0,0,0}
  | $action.cycles <= 0

unit.animate Anim =
| $anim <= Anim
| $anim_seq <= $sprite.anims.$anim
| less got $anim_seq: $anim_seq <= $sprite.anims.still
| $anim_step <= 0
| AnimFrame = $anim_seq.$anim_step
| $frame <= $sprite.frames.AnimFrame

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

unit.can_move_to XYZ =
| $world.at{XYZ}.empty and $world.units_at{XYZ}.all{?empty}

unit.environment_updated =
| [UX UY UZ] = $xyz
| $slope <= $world.slope_at{UX,UY,UZ-1}^|$1 #@1111 => 0

unit.render Heap X Y =
| G = $frame
| when G.w >< 1: leave 0 // avoid drawing dummies
| XX = X+32-G.w/2 + $xy.0
| YY = Y-16-G.h+$slope*16 + $xy.1
| Flags = $flipX
| when $picked: !Flags ++ #2
//| when $picked: FB.rect{#00FF00 0 XX YY G.w G.h}
//| FB.blit{XX,YY G flipX/$flipX}
| UX,UY,UZ = $xyz
| Key = ((UX+UY)</20) + (UZ</10) + X
| Heap.push{Key [G XX YY Flags]}

unit.order = $ordered

export unit