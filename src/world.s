use util octree

MaxSize = 256

type world{Main Size}
   main/Main size/Size cells/octree{MaxSize} gfxes seed tid_map/Main.tid_map
   cycle filler
| $main.world <= Me
| $filler <= $main.tiles.plain.id
| SS = Size*Size
| $gfxes <= SS{_=>[]}
| $seed <= SS{_=>SS.rand}
| for P points{0 0 Size Size}: $cells.set{[@P 0] $filler}
| for P points{0 0 Size Size}: $updPilarGfxes{P}

world.get X Y Z =
| less 0 << X and X < $size: leave [$filler X,Y,Z 1]
| less 0 << Y and Y < $size: leave [$filler X,Y,Z 1]
| $cells.get{[X Y Z]}

world.set X Y Z V =
| less 0 << X and X < $size: leave 0
| less 0 << Y and Y < $size: leave 0
| $cells.set{[X Y Z] V}

world.xy_to_index X,Y =
| S = $size
| (Y%S)*S + X%S

world.getElev X,Y Z = $tid_map.($get{X Y Z}.0).elev

world.getCornerElev P Z = `[]`
  [$getElev{P+[-1 -1] Z} $getElev{P+[0 -1] Z} $getElev{P+[-1 0] Z}].min
  [$getElev{P+[ 1 -1] Z} $getElev{P+[0 -1] Z} $getElev{P+[ 1 0] Z}].min
  [$getElev{P+[ 1  1] Z} $getElev{P+[0  1] Z} $getElev{P+[ 1 0] Z}].min
  [$getElev{P+[-1  1] Z} $getElev{P+[0  1] Z} $getElev{P+[-1 0] Z}].min

world.getSideElev P Z = `[]`
  $getElev{P+[0 -1] Z} $getElev{P+[ 1 0] Z}
  $getElev{P+[0  1] Z} $getElev{P+[-1 0] Z}

world.getTrn X,Y Z =
| Tile = $tid_map.($get{X Y Z}.0)
| if Tile.trn then Tile.role else 0

world.getCornerTrns P Z Role = `[]`
 [$getTrn{P+[-1 -1] Z} $getTrn{P+[0 -1] Z} $getTrn{P+[-1 0] Z}].all{is{&Role+0}}
 [$getTrn{P+[ 1 -1] Z} $getTrn{P+[0 -1] Z} $getTrn{P+[ 1 0] Z}].all{is{&Role+0}}
 [$getTrn{P+[ 1  1] Z} $getTrn{P+[0  1] Z} $getTrn{P+[ 1 0] Z}].all{is{&Role+0}}
 [$getTrn{P+[-1  1] Z} $getTrn{P+[0  1] Z} $getTrn{P+[-1 0] Z}].all{is{&Role+0}}

world.getPilar X Y =
| less 0 << X and X < $size: leave [$filler X,Y,0 $size]
| less 0 << Y and Y < $size: leave [$filler X,Y,0 $size]
| $cells.getPilar{X Y}

world.updPilarGfxes P =
| X,Y = P
| less 0 << X and X < $size: leave 0
| less 0 << Y and Y < $size: leave 0
| I = $xy_to_index{P}
| S = $seed.I
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
