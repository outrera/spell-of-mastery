use util octree unit stack

MaxSize = No
MaxUnits = No

XUnit = 64
YUnit = 32
ZUnit = No
YZUnit = No

type world{main size}
   w/Size
   h/Size
   name/default
   tilemap
   unit_map
   slope_map
   units
   free_units
   gfxes
   seed
   tid_map/Main.tid_map
   filler
   shadows
   cycle // counts calls to world.update
   serial/((1</20)-1) // used to generate serial numbers for units
   turn // turn in terms of game logic
   picked
   nil // null unit with id >< 0
   owners // unit owners
   active // active units
   vars/t{} // variables
| $main.world <= Me
| WParam = $main.params.world
| MaxSize <= WParam.max_size
| MaxUnits <= WParam.max_units
| XUnit <= WParam.x_unit
| YUnit <= WParam.y_unit
| ZUnit <= WParam.z_unit
| YZUnit <= YUnit/ZUnit
| $tilemap <= octree MaxSize
| $unit_map <= octree MaxSize
| $slope_map <= octree MaxSize
| $units <= MaxUnits{(unit ? Me)}
| $free_units <= stack $units.flip
| $filler <= $main.tiles.base_
| SS = Size*Size
| $gfxes <= ($w){_=>($h){_=>[]}}
| $seed <= ($w){_=>($h){_=>SS.rand}}
| for P points{0 0 $w $h}: $push_{P $filler}
| for P points{0 0 $w $h}: $updPilarGfxes{P}
| $nil <= $alloc_unit{unit_nil}
| $shadows <= $main.sprites.unit_shadows.frames


world.clear =
| for U $units: less U.removed: U.free
| $active <= 0

world.alloc_unit ClassName =
| Class = $main.classes.ClassName
| U = $free_units.pop
| till U.removed: U <= $free_units.pop
| U.init{Class}
| U

world.free_unit U =
| U.remove
| $free_units.push{U}

world.get X Y Z =
| Id = $tilemap.at{[X Y Z]}
| if Id < 0 then $tilemap.at{[X Y Z-Id]}
  else Id

world.at XYZ =
| X,Y,Z = XYZ
| $tid_map.| if X < 0 or Y < 0 then $tid_map.0 else $get{X Y Z}

world.set_ X Y Z V = $tilemap.set{[X Y Z] V}

// FIXME: remove overlapping tiles above setted tile
world.dirty_set X Y Z Tile =
| H = $height{X Y}
| when H < Z
  | EmptyId = $main.tiles.empty.id
  | while H < Z
    | $set_{X,Y,H EmptyId}
    | !H+1
| when Z < H
  | ZZ = Z
  | BelowId = $tilemap.at{X,Y,ZZ}
  | when BelowId < 0
    | !ZZ-BelowId
    | BelowId <= $tilemap.at{X,Y,ZZ}
  | Below = $tid_map.BelowId
  | ZZZ = ZZ - Below.height+1
  | EmptyId = $main.tiles.empty.id
  | while ZZZ < ZZ
    | $set_{X Y ZZZ EmptyId}
    | !ZZZ+1
| H = Tile.height-1
| times I H: $set_{X Y Z+I I-H} // push padding
| $set_{X Y Z+H Tile.id}

world.set X Y Z Tile =
| $dirty_set{X Y Z Tile}
| $updElev{X,Y}

world.generate W H =
| $clear
| $w <= W
| $h <= H
| Wall = $main.tiles.wall
| Z = 1
| for Y H: for X W: $dirty_set{X Y Z Wall}
| !Z + 4
| for Y H: for X W: $dirty_set{X Y Z Wall}
| for P points{0 0 $w $h}: $updPilarGfxes{P}

world.slope_at XYZ = $slope_map.at{XYZ}

world.set_slope_at XYZ Slope = $slope_map.set{XYZ Slope}

world.unit_id_at XYZ = $unit_map.at{XYZ}

world.unit_at XYZ =
| when!it $unit_map.at{XYZ}: leave $units.it
| 0

world.units_at XYZ =
| when!it $unit_map.at{XYZ}: leave $units.it^uncons{next}
| []

world.column_units_at X Y =
| when!it $unit_map.at{X,Y,0}: leave $units.it^uncons{column_next}
| []

cons_next F Xs = Xs.sortBy{F}.flip^cons{next}

cons_column_next F Xs = Xs.sortBy{F}.flip^cons{column_next}

world.place_unit U =
| XYZ = U.xyz
| Us = U,@$units_at{XYZ}
| Consed = Us^cons_next{?draw_order++?serial}
| Id = if Consed then Consed.id else 0
| $unit_map.set{XYZ Id}
| Us = U,@$column_units_at{XYZ.0 XYZ.1}.skip{?id >< U.id}
| Consed = Us^cons_column_next{?xyz.2}
| Id = if Consed then Consed.id else 0
| $unit_map.set{XYZ.0,XYZ.1,0 U.id}

world.remove_unit U =
| XYZ = U.xyz
| when XYZ.2 >< -1: leave 0
| Us = $units_at{XYZ}.skip{?id >< U.id}
| Consed = Us^cons_next{?draw_order++?serial}
| Id = if Consed then Consed.id else 0
| $unit_map.set{XYZ Id}
| Us = $column_units_at{XYZ.0 XYZ.1}.skip{?id >< U.id}
| Consed = Us^cons_column_next{?xyz.2}
| Id = if Consed then Consed.id else 0
| $unit_map.set{XYZ.0,XYZ.1,0 Id}

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
| $tilemap.getPilar{X Y}

world.updPilarGfxes P =
| X,Y = P
| less 0 << X and X < $size: leave 0
| less 0 << Y and Y < $size: leave 0
| Seed = $seed.X.Y
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
| $gfxes.X.Y <= Gs.flip //FIXME: use `init` method instead
| for U $column_units_at{X Y}: U.environment_updated

world.updElev P =
| for D Dirs: $updPilarGfxes{P+D}
| $updPilarGfxes{P}

draw_pick V Front FB X Y H =
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


world.drawPilar X Y BX BY FB CursorXY CursorZ =
| when X < 0 or X >> $size: leave 0
| when Y < 0 or Y >> $size: leave 0
| !BY + 32
| Gs = $gfxes.X.Y
| CurX = CursorXY.0
| CurY = CursorXY.1
| CurH = (CurX+CurY)/2
| CurHH = CurH+2
| Cursor = same X CurX and Y >< CurY
| Z = 0
| UnitZ = 0
//| TileShadow = $main.sprites.system_tile_shadow.frames.0
| for G Gs: if G.is_int
  then | when Cursor
         | draw_pick #FF0000 0 FB BX BY-YUnit-Z*ZUnit G
         | draw_pick #00FF00 1 FB BX BY-YUnit-Z*ZUnit G
       | !Z+G
  else | T = $tid_map.($get{X Y Z})
       | TH = T.height
       | ZZ = Z*ZUnit
       | when Cursor | draw_pick #FF0000 0 FB BX BY-YUnit-ZZ TH
       | XY2 = (X+Y)/2
       | when CurH >> XY2 or Z << CursorZ or XY2-CurHH-Z/YZUnit >> 0:
         | FB.blitRaw{BX BY-G.h-ZZ G}
       //| when T.shadow and $slope_at{X+1,Y,Z+TH*2-1} >< #@1111:
       //  | FB.blit{[BX BY-G.h-ZZ] TileShadow}
       | UnitZ <= Z + TH
       | for U $units_at{X,Y,UnitZ}: U.render{FB BX BY-ZUnit*UnitZ}
       | when Cursor | draw_pick #00FF00 1 FB BX BY-YUnit-ZZ TH
       | Z <= UnitZ
| for U $column_units_at{X Y}
  | Z = U.xyz.2
  | when Z > UnitZ
    | !Z+1
    | U.render{FB BX BY-ZUnit*Z+ZUnit}
    | S = $shadows.(2-min{(Z-UnitZ)/2-2 2})
    | FB.blit{[BX-S.w/2+32 BY-S.h-UnitZ*ZUnit] S}

world.height X Y = MaxSize - $getPilar{X Y}.last.0

world.push_ X,Y Tile =
| Z = $height{X Y}
| H = Tile.height-1
| times I H: $set_{X Y Z+I I-H} // push padding
| $set_{X Y Z+H Tile.id}


// push Tile on top of pilar at X,Y
world.push XY Tile =
| $push_{XY Tile}
| $updElev{XY}

world.pop_ X,Y =
| H = $height{X Y}
| less H: leave 0
| Z = H-1
| $set_slope_at{X,Y,Z #@0000}
| T = $tid_map.($get{X Y Z})
| times I T.height: $set_{X Y Z-I 0}

// pop top tile of pilar at X,Y
world.pop XY =
| $pop_{XY}
| $updElev{XY}

export world
