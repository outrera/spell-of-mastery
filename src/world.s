use util octree

MaxSize = 256

type world{Main Size}
   main/Main size/Size cells/octree{MaxSize} gfxes seed tid_map/Main.tid_map
   cycle
| $main.world <= Me
| Filler = $main.tiles.base.id
| SS = Size*Size
| $gfxes <= SS{_=>[]}
| $seed <= SS{_=>SS.rand}
| for P points{0 0 Size+2 Size+2}: $cells.set{[@P 0] Filler}
| $push{1,1 Filler}
| for P points{0 0 Size Size}: $updPilarGfxes{P}

world.get X Y Z = $cells.get{[X+1 Y+1 Z]}

world.set X Y Z V = $cells.set{[X+1 Y+1 Z] V}

world.xy_to_index X,Y =
| S = $size
| (Y%S)*S + X%S

world.getElev X,Y Z = $tid_map.($get{X Y Z}.0).elev

world.getTrn X,Y Z =
| C = $tid_map.($get{X Y Z}.0)
| C.trn and C.role

world.getCornerElev P Z = `[]`
  [$getElev{P+[-1 -1] Z} $getElev{P+[0 -1] Z} $getElev{P+[-1 0] Z}].min
  [$getElev{P+[ 1 -1] Z} $getElev{P+[0 -1] Z} $getElev{P+[ 1 0] Z}].min
  [$getElev{P+[ 1  1] Z} $getElev{P+[0  1] Z} $getElev{P+[ 1 0] Z}].min
  [$getElev{P+[-1  1] Z} $getElev{P+[0  1] Z} $getElev{P+[-1 0] Z}].min

world.getSideElev P Z = `[]`
  $getElev{P+[0 -1] Z} $getElev{P+[ 1 0] Z}
  $getElev{P+[0  1] Z} $getElev{P+[-1 0] Z}

world.getCornerTrns P Z R = `[]`
  [$getTrn{P+[-1 -1] Z} $getTrn{P+[0 -1] Z} $getTrn{P+[-1 0] Z}].all{R}
  [$getTrn{P+[ 1 -1] Z} $getTrn{P+[0 -1] Z} $getTrn{P+[ 1 0] Z}].all{R}
  [$getTrn{P+[ 1  1] Z} $getTrn{P+[0  1] Z} $getTrn{P+[ 1 0] Z}].all{R}
  [$getTrn{P+[-1  1] Z} $getTrn{P+[0  1] Z} $getTrn{P+[-1 0] Z}].all{R}

world.getPilar X Y = $cells.getPilar{X+1 Y+1}

world.updPilarGfxes P =
| I = $xy_to_index{P}
| S = $seed.I
| X,Y = P
| Cs = $getPilar{X Y}
| Gs = []
| Z = 0
| B = $tid_map.0 // Base
| for [N V] Cs
  | less V
    | B <= $tid_map.0
    | !Z + N
    | push N Gs
    | _goto for_break
  | C = $tid_map.V
  | times I N
    | A = if I+1 < N then B else $tid_map.($get{X Y Z+1}.0)
      // B=Below, A=Above, S=Seed
    | push C.render{P Z B A S} Gs
    | B <= C
    | !Z + 1 
| _label for_break
| $gfxes.I <= Gs.flip

world.drawPilar P BX BY Blit CursorI =
| X,Y = P
| when X < 0 or X >> $size: leave 0
| when Y < 0 or Y >> $size: leave 0
| I = $xy_to_index{P}
| Gs = $gfxes.I
| Cursor = same I CursorI
| Z = 0
| Os = []
//| case P X,Y: Os <= Objs.X.Y
| for G Gs: case G
  1.is_int | !Z+G
  Else | when Cursor | R = $main.rect_back; Blit BX BY-R.h+32-Z*32 R
       | Blit BX BY-G.h+32-Z*32 G
       //| when Z+1 < Os.size: for O Os.(Z+1): O.render{Blit BX BY-Z*32}
       | when Cursor | R = $main.rect_front; Blit BX BY-R.h+32-Z*32 R
       | !Z+1

world.updElev P =
| for D Dirs: $updPilarGfxes{P+D}
| $updPilarGfxes{P}

world.height X Y = MaxSize - $getPilar{X Y}.last.0

world.push X,Y C =
| $set{X Y $height{X Y} C}
| $updElev{X,Y}

world.pop X,Y =
| H = $height{X Y}
| less H: leave 0
| $set{X Y H-1 0}
| $updElev{X,Y}

world.update =
| !$cycle + 1

export world
