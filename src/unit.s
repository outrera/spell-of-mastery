use util

type unit.$class{Id World}
  id/Id // numeric id for octree
  world/World
  class
  xyz/[0 0 -1] // world coordinates
  sub_xyz/[0 0 0] // fine X,Y,Z for movement animation between cells
  next // next unit inside of this world cell
  owner // player controlling this unit
  anim // current animation
  anim_step // frame index inside of current animation
  frame
  facing // direction this unit faces

unit.init Class =
| $class <= Class
| $facing <= 0
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

unit.render Blit X Y =
| G = $frame
| DX,DY = G.hotspot
| Blit X+DX-G.w/2 Y+DY-16-G.h G

export unit