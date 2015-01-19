use util

type unit.$class{Id World}
  id/Id // numeric id for octree
  world/World
  serial
  class
  xyz/[0 0 -1] // world coordinates
  sub_xyz/[0 0 0] // fine X,Y,Z for movement animation between cells
  next // next unit inside of this world cell
  column_next // next unit inside of this world column
  owner // player controlling this unit
  anim // current animation
  anim_step // frame index inside of current animation
  frame
  facing // direction this unit faces
  slope // unit is standing on a sloped terrain
  flipX

unit.main = $world.main

unit.init Class =
| $class <= Class
| $flipX <= 0
| $facing <= 0
| $next <= 0
| $column_next <= 0
| $serial <= $world.unit_serial
| !$world.unit_serial - 1
| $animate{still}

unit.animate Anim =
| $anim <= $sprite.anims.Anim
| $anim_step <= 0
| $frame <= $sprite.frames.$anim_step

unit.free = $world.free_unit{Me}

unit.remove =
| $world.remove_unit{Me}
| $xyz.2 <= -1

unit.move XYZ =
| $remove
| $xyz.init{XYZ}
| $sub_xyz.init{[0 0 0]}
| $world.place_unit{Me}
| [UX UY UZ] = XYZ
| when UZ > 0: $slope <= $world.slope_at{UX,UY,UZ-1}^|$1 #@0000+#@1111 => 0


unit.render Blit X Y =
| G = $frame
| DX,DY = G.hotspot
| DY <= DY + $slope*16
| OX = if $flipX then -DX else DX
| Blit X+32-G.w/2+OX Y+DY-16-G.h G $flipX



export unit