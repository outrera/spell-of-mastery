use util octree unit stack heap player

MaxSize = No
MaxUnits = No
MaxActiveUnits = 4096

PlayerColors = [white red blue cyan violet orange black yellow magenta]

type world{main W H}
   w
   h
   filename/`default`
   name/`default map`
   description/`describe the map here`
   tilemap
   unit_map
   slope_map
   units
   free_units
   players
   player // currently moving player
   this_player // player beside this computer
   gfxes
   seed
   tid_map/Main.tid_map
   filler
   shadows
   cycle // counts calls to world.update
   serial
   turn // turn in terms of game logic
   picked
   nil // null unit with id >< 0
   owners // unit owners
   active // active units
   vars/t{} // variables
   xunit
   yunit
   zunit
   on_player_change
   marks
| $main.world <= Me
| WParam = $main.params.world
| MaxSize <= WParam.max_size
| MaxUnits <= WParam.max_units
| $players <= map Id WParam.max_players
  | P = player Id Me
  | P.name <= if Id >< 0 then "Independent" else "Player[Id]"
  | when Id >< 1: P.human <= 1
  | P.color <= PlayerColors.Id
  | P
| $player <= $players.0
| $this_player <= $players.1
| $xunit <= WParam.x_unit
| $yunit <= WParam.y_unit
| $zunit <= WParam.z_unit
| $tilemap <= octree MaxSize
| $unit_map <= octree MaxSize
| $slope_map <= octree MaxSize
| $units <= MaxUnits{(unit ? Me)}
| $free_units <= stack $units.flip
| $active <= stack MaxActiveUnits
| $shadows <= $main.sprites.unit_shadows.frames
| $filler <= $main.tiles.base_
| SS = MaxSize*MaxSize
| $gfxes <= MaxSize{_=>MaxSize{_=>[]}}
| $seed <= MaxSize{_=>MaxSize{_=>SS.rand}}
| $create{W H}

world.create W H =
| $w <= W
| $h <= H
| !$w+1
| !$h+1
| $clear
| for P points{0 0 $w $h}: $push_{P $filler}
| for P points{0 0 $w $h}: $updPilarGfxes{P}
// add movement blocking wall
| for P points{0 $h-1 $w 1}: times I 10: $push_{P $filler}
| for P points{$w-1 0 1 $h-1}: times I 10: $push_{P $filler}
| !$w-1
| !$h-1

world.clear =
| for U $units: less U.removed: U.free
| $tilemap.clear{0}
| $picked <= 0
| $nil <= $alloc_unit{unit_nil}
| $marks <= $nil
| for Type,Act $main.params.acts: for Player $players: Player.research.Type <= 0

world.alloc_unit ClassName =
| Class = $main.classes.ClassName
| less got Class: bad "Missing class `[ClassName]`"
| U = $free_units.pop
| till U.removed: U <= $free_units.pop
| U.init{Class}
| U.owner <= $player
| U

world.free_unit U =
| when U.id
  | U.remove
  | $free_units.push{U}

world.get X Y Z =
| Id = $tilemap.at{[X Y Z]}
| if Id < 0 then $tilemap.at{[X Y Z-Id]}
  else Id

world.at XYZ =
| X,Y,Z = XYZ
| $tid_map.| if X < 0 or Y < 0 then 0 else $get{X Y Z}

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

world.block_at XYZ =
| Block = $units_at{XYZ}.skip{?empty}
| if Block.size then Block.head else No

world.place_unit U =
| XYZ = U.xyz
| Us = U,@$units_at{XYZ}
| Consed = Us^cons{next}
| Id = if Consed then Consed.id else 0
| $unit_map.set{XYZ Id}
| Us = U,@$column_units_at{XYZ.0 XYZ.1}.skip{?id >< U.id}
| Consed = Us^cons{column_next}
| Id = if Consed then Consed.id else 0
| $unit_map.set{XYZ.0,XYZ.1,0 Id}

world.remove_unit U =
| XYZ = U.xyz
| when XYZ.2 >< -1: leave
| Us = $units_at{XYZ}.skip{?id >< U.id}
| Consed = Us^cons{next}
| Id = if Consed then Consed.id else 0
| $unit_map.set{XYZ Id}
| Us = $column_units_at{XYZ.0 XYZ.1}.skip{?id >< U.id}
| Consed = Us^cons{column_next}
| Id = if Consed then Consed.id else 0
| $unit_map.set{XYZ.0,XYZ.1,0 Id}

world.effect X,Y,Z What =
| E = $alloc_unit{"effect_[What]"}
| E.move{X,Y,Z}
| E.order.init{act/die level/0}

world.filled X,Y Z =
| less 0 << X and X < $w: leave 1
| less 0 << Y and Y < $h: leave 1
| $tid_map.($get{X Y Z}).filler

world.getCorners P Z = `[]`
  [$filled{P+[-1 -1] Z} $filled{P+[0 -1] Z} $filled{P+[-1 0] Z}].all{1}
  [$filled{P+[ 1 -1] Z} $filled{P+[0 -1] Z} $filled{P+[ 1 0] Z}].all{1}
  [$filled{P+[ 1  1] Z} $filled{P+[0  1] Z} $filled{P+[ 1 0] Z}].all{1}
  [$filled{P+[-1  1] Z} $filled{P+[0  1] Z} $filled{P+[-1 0] Z}].all{1}

world.getSides P Z = `[]`
  $filled{P+[0 -1] Z} $filled{P+[ 1 0] Z}
  $filled{P+[0  1] Z} $filled{P+[-1 0] Z}

world.role X,Y Z =
| less 0 << X and X < $w: leave 0
| less 0 << Y and Y < $h: leave 0
| $tid_map.($get{X Y Z}).role

world.getCornersSame P Z Role = `[]`
  [$role{P+[-1 -1] Z} $role{P+[0 -1] Z} $role{P+[-1 0] Z}].all{Role}
  [$role{P+[ 1 -1] Z} $role{P+[0 -1] Z} $role{P+[ 1 0] Z}].all{Role}
  [$role{P+[ 1  1] Z} $role{P+[0  1] Z} $role{P+[ 1 0] Z}].all{Role}
  [$role{P+[-1  1] Z} $role{P+[0  1] Z} $role{P+[-1 0] Z}].all{Role}

world.getSidesSame P Z Role = `[]`
  $role{P+[0 -1] Z}><Role $role{P+[ 1 0] Z}><Role
  $role{P+[0  1] Z}><Role $role{P+[-1 0] Z}><Role

world.getTrn X,Y Z =
| less 0 << X and X < $w: leave 0
| less 0 << Y and Y < $h: leave 0
| Tile = $tid_map.($get{X Y Z})
| if Tile.trn then Tile.role else 0

world.getCornersTrns P Z Role = `[]`
 [$getTrn{P+[-1 -1] Z} $getTrn{P+[0 -1] Z} $getTrn{P+[-1 0] Z}].all{is{&Role+0}}
 [$getTrn{P+[ 1 -1] Z} $getTrn{P+[0 -1] Z} $getTrn{P+[ 1 0] Z}].all{is{&Role+0}}
 [$getTrn{P+[ 1  1] Z} $getTrn{P+[0  1] Z} $getTrn{P+[ 1 0] Z}].all{is{&Role+0}}
 [$getTrn{P+[-1  1] Z} $getTrn{P+[0  1] Z} $getTrn{P+[-1 0] Z}].all{is{&Role+0}}

world.getPilar X Y =
| less 0 << X and X < $w: leave [$filler X,Y,0 MaxSize-1]
| less 0 << Y and Y < $h: leave [$filler X,Y,0 MaxSize-1]
| $tilemap.getPilar{X Y}

world.updPilarGfxes P =
| X,Y = P
| less 0 << X and X < $w: leave 0
| less 0 << Y and Y < $h: leave 0
| Seed = $seed.Y.X
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
| $gfxes.Y.X <= Gs.flip //FIXME: use `init` method instead
| for U $column_units_at{X Y}: U.environment_updated

world.updElev P =
| for D Dirs: $updPilarGfxes{P+D}
| $updPilarGfxes{P}

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
| less H: leave
| Z = H-1
| $set_slope_at{X,Y,Z #@0000}
| T = $tid_map.($get{X Y Z})
| times I T.height: $set_{X Y Z-I 0}

// pop top tile of pilar at X,Y
world.pop XY =
| $pop_{XY}
| $updElev{XY}

export world
