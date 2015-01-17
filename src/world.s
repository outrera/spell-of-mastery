use util octree unit stack

MaxSize = 256
MaxUnits = 4096


type world{Main Size}
   main/Main size/Size
   cells/octree{MaxSize}
   unit_cells/octree{MaxSize}
   slope_map/octree{MaxSize}
   units
   free_units/stack{MaxUnits}
   gfxes
   seed
   tid_map/Main.tid_map
   cycle
   filler
| $main.world <= Me
| $units <= MaxUnits{(unit ? Me)}
| $filler <= $main.tiles.plain.id
| SS = Size*Size
| $gfxes <= SS{_=>[]}
| $seed <= SS{_=>SS.rand}
| for P points{0 0 Size Size}: $cells.set{[@P 0] $filler}
| for P points{0 0 Size Size}: $updPilarGfxes{P}
| for U $units: when U.id <> 0: $free_units.push{U}

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

world.slope_at XYZ = $slope_map.get{XYZ}.0

world.unit_id_at XYZ = $unit_cells.get{XYZ}.0

world.unit_at XYZ =
| when!it $unit_cells.get{XYZ}.0: leave $units.it
| 0

world.units_at XYZ =
| when!it $unit_cells.get{XYZ}.0: leave $units.it^uncons{?next}
| []

world.place_unit U =
| XYZ = U.xyz
| ColumnXYZ = XYZ.0,XYZ.1,0
| U.next <= $unit_at{XYZ}
| U.column_next <= $unit_at{ColumnXYZ}
| $unit_cells.set{XYZ U.id}
| $unit_cells.set{ColumnXYZ U.id}

world.remove_unit U =
| XYZ = U.xyz
| when XYZ.2 >< -1: leave 0
| Next = $units_at{XYZ}.skip{?id >< U.id}^cons{(?.next <= ??)}
| Id = if Next then Next.id else 0
| $unit_cells.set{XYZ Id}
| ColumnXYZ = [XYZ.0 XYZ.1 0]
| Next = $units_at{ColumnXYZ}.skip{?id >< U.id}^cons{(?.next <= ??)}
| Id = if Next then Next.id else 0
| $unit_cells.set{ColumnXYZ Id}

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
| $gfxes.I <= Gs.flip //FIXME: use `init` method instead

world.drawPilar P BX BY Blit CursorI =
| X,Y = P
| when X < 0 or X >> $size: leave 0
| when Y < 0 or Y >> $size: leave 0
| I = $xy_to_index{P}
| Gs = $gfxes.I
| Cursor = same I CursorI
| Z = 0
| UnitZ = 0
| for G Gs: case G
  1.is_int | !Z+G
  Else | when Cursor | R = $main.rect_back; Blit BX BY-R.h+32-Z*32 R 0
       | Blit BX BY-G.h+32-Z*32 G 0
       | UnitZ <= Z+1
       | for U $units_at{X,Y,UnitZ}: U.render{Blit BX BY-32*Z}
       | when Cursor | R = $main.rect_front; Blit BX BY-R.h+32-Z*32 R 0
       | !Z+1
| for U $units_at{X,Y,0}
  | Z = U.xyz.2
  | when Z > UnitZ: U.render{Blit BX BY-32*Z+32}

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
