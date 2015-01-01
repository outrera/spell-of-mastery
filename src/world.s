use util octree

type world{Main Size} main/Main size/Size cells/(octree) gfxes seed tid_map/Main.tid_map
| Filler = $main.tiles.base.id
| SS = Size*Size
| $gfxes <= SS{_=>[]}
| $seed <= SS{_=>SS.rand}
| for P points{0 0 Size Size}: $cells.set{[@P 0] Filler}
| for P points{0 0 Size Size}: $updPilarGfxes{P}

world.p2i X,Y =
| S = $size
| (Y%S)*S + X%S

world.getElev P Z = $tid_map.($cells.get{[@P Z]}.0).elev

world.getTrn P Z =
| C = $tid_map.($cells.get{[@P Z]}.0)
| C.trn and C.role

world.getCornerElev P Z = `[]`
  [$getElev{P+[-1 -1] Z} $getElev{P+[0 -1] Z} $getElev{P+[-1 0] Z}].min
  [$getElev{P+[ 1 -1] Z} $getElev{P+[0 -1] Z} $getElev{P+[ 1 0] Z}].min
  [$getElev{P+[ 1  1] Z} $getElev{P+[0  1] Z} $getElev{P+[ 1 0] Z}].min
  [$getElev{P+[-1  1] Z} $getElev{P+[0  1] Z} $getElev{P+[-1 0] Z}].min

world.getSideElev P Z = `[]`
  $getElev{P+[0 -1] Z} $getElev{P+[1 0] Z} $getElev{P+[0 1] Z} $getElev{P+[-1 0] Z}

world.getCornerTrns P Z R = `[]`
  [$getTrn{P+[-1 -1] Z} $getTrn{P+[0 -1] Z} $getTrn{P+[-1 0] Z}].all{R}
  [$getTrn{P+[ 1 -1] Z} $getTrn{P+[0 -1] Z} $getTrn{P+[ 1 0] Z}].all{R}
  [$getTrn{P+[ 1  1] Z} $getTrn{P+[0  1] Z} $getTrn{P+[ 1 0] Z}].all{R}
  [$getTrn{P+[-1  1] Z} $getTrn{P+[0  1] Z} $getTrn{P+[-1 0] Z}].all{R}

world.getPilar P = $cells.getPilar{P}

world.updPilarGfxes P =
| I = $p2i{P}
| S = $seed.I
| Cs = $getPilar{P}
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
    | A = if I+1 < N then B else $tid_map.($cells.get{[@P Z+1]}.0)
      // B=Below, A=Above, S=Seed
    | push C.render{P Z B A S} Gs
    | B <= C
    | !Z + 1 
| _label for_break
| $gfxes.I <= Gs.flip

world.drawPilar P BX BY Blit CursorI =
| !P % $size
| I = $p2i{P}
| Gs = $gfxes.I
| Cursor = same I CursorI
| Z = 0
| Os = []
//| case P X,Y: Os <= Objs.X.Y
| for G Gs: case G
  0.is_int | !Z+G
  Else | when Cursor | R = $main.rect_back; Blit BX BY-R.h+32-Z*32 R
       | Blit BX BY-G.h+32-Z*32 G
       | for O Os.(Z+1): O.render{Blit BX BY-Z*32}
       | when Cursor | R = $main.rect_front; Blit BX BY-R.h+32-Z*32 R
       | !Z+1

world.updElev P =
| for D Dirs: $updPilarGfxes{P+D}
| $updPilarGfxes{P}

world.height XY = $size - $getPilar{XY}.last.0

world.push XY C =
| $cells.set{[@XY XY.height] C.id}
| $updElev{XY}

world.pop XY =
| H = XY.height
| less H: leave 0
| $cells.set{[@XY H-1] 0}
| $updElev{XY}
