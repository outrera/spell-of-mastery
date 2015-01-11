use util octree unit stack

MaxSize = 256
MaxUnits = 4096


type world{Main Size}
   main/Main size/Size
   cells/octree{MaxSize}
   unit_cells/octree{MaxSize}
   units
   free_units/stack{MaxUnits}
   gfxes seed tid_map/Main.tid_map
   cycle filler
| $main.world <= Me
| $units <= MaxUnits{(unit ? Me)}
| $filler <= $main.tiles.plain.id
| SS = Size*Size
| $gfxes <= SS{_=>[]}
| $seed <= SS{_=>SS.rand}
| for P points{0 0 Size Size}: $cells.set{[@P 0] $filler}
| for P points{0 0 Size Size}: $updPilarGfxes{P}
| for U $units: $free_units.push{U}

world.alloc_unit ClassName =
| Class = $main.classes.ClassName
| U = $free_units.pop
| U.init{Class}
| U

world.free_unit U =
| U.remove
| $free_units.push{U}

world.get X Y Z = $cells.get{[X Y Z]}

world.set X Y Z V = $cells.set{[X Y Z] V}

world.get_units XYZ =
| when!it $unit_cells.get{XYZ}.0: leave $units.it^uncons{?next}
| 0

world.place_unit U = $unit_cells.set{U.xyz U.id}

world.remove_unit U = when U.xyz.2 <> -1: $unit_cells.set{U.xyz 0}

world.xy_to_index X,Y =
| S = $size
| (Y%S)*S + X%S

world.getElev X,Y Z =
| less 0 << X and X < $size: leave 1.0
| less 0 << Y and Y < $size: leave 1.0
| $tid_map.($get{X Y Z}.0).elev

world.getCornerElev P Z = `[]`
  [$getElev{P+[-1 -1] Z} $getElev{P+[0 -1] Z} $getElev{P+[-1 0] Z}].min
  [$getElev{P+[ 1 -1] Z} $getElev{P+[0 -1] Z} $getElev{P+[ 1 0] Z}].min
  [$getElev{P+[ 1  1] Z} $getElev{P+[0  1] Z} $getElev{P+[ 1 0] Z}].min
  [$getElev{P+[-1  1] Z} $getElev{P+[0  1] Z} $getElev{P+[-1 0] Z}].min

world.getSideElev P Z = `[]`
  $getElev{P+[0 -1] Z} $getElev{P+[ 1 0] Z}
  $getElev{P+[0  1] Z} $getElev{P+[-1 0] Z}

world.getTrn X,Y Z =
| less 0 << X and X < $size: leave 0
| less 0 << Y and Y < $size: leave 0
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
| Seed = $seed.I
| Cs = $getPilar{X Y}
| Gs = []
| Z = 0
| Below = $tid_map.0
| for [Count TileId] Cs
  | less TileId
    | Below <= $tid_map.0
    | !Z + Count
    | push Count Gs
    | _goto for_break
  | C = $tid_map.TileId
  | times I Count
    | Above = if I+1 < Count then Below else $tid_map.($get{X Y Z+1}.0)
    | push C.render{P Z Below Above Seed} Gs
    | Below <= C
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
//| Os = []
//| case P X,Y: Os <= Objs.X.Y
| for G Gs: case G
  1.is_int | !Z+G
  Else | when Cursor | R = $main.rect_back; Blit BX BY-R.h+32-Z*32 R
       | Blit BX BY-G.h+32-Z*32 G
       //| when Z+1 < Os.size: for O Os.(Z+1): O.render{Blit BX BY-Z*32}
       | for U $get_units{X,Y,Z+1}: U.render{Blit BX BY-32*Z}
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
