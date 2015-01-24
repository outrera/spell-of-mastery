use util octree unit stack

MaxSize = No
MaxUnits = No
ZUnit = No

type world{main size}
   game
   w/Size
   h/Size
   cells
   unit_cells
   unit_serial/((1</20)-1) // used to generate serial numbers for units
   slope_map
   units
   free_units
   gfxes
   seed
   tid_map/Main.tid_map
   filler
   shadows
| MaxSize <= $main.params.world.max_size
| MaxUnits <= $main.params.world.max_units
| ZUnit <= $main.params.world.z_unit
| $cells <= octree MaxSize
| $unit_cells <= octree MaxSize
| $slope_map <= octree MaxSize
| $free_units <= stack MaxUnits
| $main.world <= Me
| $units <= MaxUnits{(unit ? Me)}
| $filler <= $main.tiles.base_
| SS = Size*Size
| $gfxes <= SS{_=>[]}
| $seed <= SS{_=>SS.rand}
| for P points{0 0 Size Size}: $push_{P $filler}
| for P points{0 0 Size Size}: $updPilarGfxes{P}
| for U $units: when U.id <> 0: $free_units.push{U}
| $shadows <= $main.sprites.unit_shadows.frames

world.alloc_unit ClassName =
| Class = $main.classes.ClassName
| U = $free_units.pop
| U.init{Class}
| U

world.free_unit U =
| U.remove
| $free_units.push{U}

world.get X Y Z =
| Id = $cells.get{[X Y Z]}.0
| if Id < 0 then $cells.get{[X Y Z-Id]}.0
  else Id

world.set X Y Z V = $cells.set{[X Y Z] V}

world.slope_at XYZ = $slope_map.get{XYZ}.0

world.set_slope_at XYZ Slope = $slope_map.set{XYZ Slope}

world.unit_id_at XYZ = $unit_cells.get{XYZ}.0

world.unit_at XYZ =
| when!it $unit_cells.get{XYZ}.0: leave $units.it
| 0

world.units_at XYZ =
| when!it $unit_cells.get{XYZ}.0: leave $units.it^uncons{next}
| []

world.column_units_at XYZ =
| when!it $unit_cells.get{XYZ}.0: leave $units.it^uncons{column_next}
| []

cons_next F Xs = Xs.sortBy{F}.flip^cons{next}

cons_column_next F Xs = Xs.sortBy{F}.flip^cons{column_next}

world.place_unit U =
| XYZ = U.xyz
| Us = U,@$units_at{XYZ}
| Consed = Us^cons_next{?draw_order++?serial}
| Id = if Consed then Consed.id else 0
| $unit_cells.set{XYZ Id}
| ColumnXYZ = XYZ.0,XYZ.1,0
| Us = U,@$column_units_at{ColumnXYZ}.skip{?id >< U.id}
| Consed = Us^cons_column_next{?xyz.2}
| Id = if Consed then Consed.id else 0
| $unit_cells.set{ColumnXYZ U.id}

world.remove_unit U =
| XYZ = U.xyz
| when XYZ.2 >< -1: leave 0
| Us = $units_at{XYZ}.skip{?id >< U.id}
| Consed = Us^cons_next{?draw_order++?serial}
| Id = if Consed then Consed.id else 0
| $unit_cells.set{XYZ Id}
| ColumnXYZ = [XYZ.0 XYZ.1 0]
| Us = $column_units_at{ColumnXYZ}.skip{?id >< U.id}
| Consed = Us^cons_column_next{?xyz.2}
| Id = if Consed then Consed.id else 0
| $unit_cells.set{ColumnXYZ Id}

world.xy_to_index X Y =
| S = $size
| (Y%S)*S + X%S

world.getElev X,Y Z =
| less 0 << X and X < $size: leave 100
| less 0 << Y and Y < $size: leave 100
| $tid_map.($get{X Y Z}).height

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
| Tile = $tid_map.($get{X Y Z})
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
| I = $xy_to_index{X Y}
| Seed = $seed.I
| Cs = $getPilar{X Y}
| Gs = []
| Z = 0
| Below = $tid_map.0
| for [Count TileId] Cs
  | less TileId //end?
    | Below <= $tid_map.0
    | !Z + Count
    | _goto for_break
  | C = $tid_map.|if TileId < 0 then $get{X Y Z-TileId} else TileId
  | if TileId < 0 or C.invisible
    then | when C.invisible: push Count Gs
         | less TileId < 0: Below <= C
         | !Z + Count
    else times I Count
         | Above = if I+1 < Count then Below else $tid_map.($get{X Y Z+1})
         | push C.render{P Z Below Above Seed} Gs
         | Below <= C
         | !Z + 1
| _label for_break
| $gfxes.I <= Gs.flip //FIXME: use `init` method instead

world.updElev P =
| for D Dirs: $updPilarGfxes{P+D}
| $updPilarGfxes{P}

XUnit = 64
YUnit = 32

draw_cursor V Front FB X Y H =
| !H*ZUnit
| !Y - H
| !Y - 2
| !Y+YUnit/2
| A = [X Y]
| B = [X+XUnit/2 if Front then Y+YUnit/2 else Y-YUnit/2]
| C = [X+XUnit Y]
| FB.line{V A B}
| FB.line{V B C}
| FB.line{V A+[0 H] B+[0 H]}
| FB.line{V B+[0 H] C+[0 H]}
| FB.line{V A A+[0 H]}
| FB.line{V B B+[0 H]}
| FB.line{V C C+[0 H]}


world.drawPilar X Y BX BY FB CursorI =
| !BY + 32
| when X < 0 or X >> $size: leave 0
| when Y < 0 or Y >> $size: leave 0
| I = $xy_to_index{X Y}
| Gs = $gfxes.I
| Cursor = same I CursorI
| Z = 0
| UnitZ = 0
//| TileShadow = $main.sprites.system_tile_shadow.frames.0
| for G Gs: if G.is_int
  then | when Cursor
         | draw_cursor #FF0000 0 FB BX BY-YUnit-Z*ZUnit G
         | draw_cursor #00FF00 1 FB BX BY-YUnit-Z*ZUnit G
       | !Z+G
  else | T = $tid_map.($get{X Y Z})
       | TH = T.height
       | ZZ = Z*ZUnit
       | when Cursor | draw_cursor #FF0000 0 FB BX BY-YUnit-ZZ TH
       | HS = G.hotspot
       | FB.blit{[BX+HS.0 BY-G.h-ZZ+HS.1] G}
       //| when T.shadow and $slope_at{X+1,Y,Z+TH*2-1} >< #@1111:
       //  | FB.blit{[BX+HS.0 BY-G.h-ZZ+HS.1] TileShadow}
       | UnitZ <= Z + TH
       | for U $units_at{X,Y,UnitZ}: U.render{FB BX BY-ZUnit*UnitZ}
       | when Cursor | draw_cursor #00FF00 1 FB BX BY-YUnit-ZZ TH
       | Z <= UnitZ
| for U $units_at{X,Y,0}
  | Z = U.xyz.2
  | when Z > UnitZ
    | !Z+1
    | U.render{FB BX BY-ZUnit*Z+ZUnit}
    | S = $shadows.(2-min{Z-UnitZ-2 2})
    | FB.blit{[BX-S.w/2+32 BY-S.h-UnitZ*ZUnit] S}

world.height X Y = MaxSize - $getPilar{X Y}.last.0

world.push_ X,Y Tile =
| Z = $height{X Y}
| H = Tile.height-1
| times I H: $set{X Y Z+I I-H} // push padding
| $set{X Y Z+H Tile.id}


// push Tile on top of pilar at X,Y
world.push XY Tile =
| $push_{XY Tile}
| $updElev{XY}

// pop top tile of pilar at X,Y
world.pop X,Y =
| H = $height{X Y}
| less H: leave 0
| Z = H-1
| $set_slope_at{X,Y,Z #@0000}
| T = $tid_map.($get{X Y Z})
| times I T.height: $set{X Y Z-I 0}
| $updElev{X,Y}

world.update = when $game: $game.update



export world
