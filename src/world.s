use util zmap unit stack heap player

MaxSize = No
MaxUnits = No
MaxActiveUnits = 4096

type proxy.$unit_{id}
  unit_ 
  next // next unit inside of this world cell
  column_next // next unit inside of this world column

proxy.as_text = "#proxy{[$id] [$type] [$unit_id]}"

proxy.init Unit =
| $unit_ <= Unit
| $next <= 0
| $column_next <= 0

type world{main W H}
   w
   h
   filename/`default`
   name/`default map`
   description/`describe the map here`
   tilemap
   unit_map
   slope_map
   move_map
   units
   free_units
   proxies
   free_proxies
   players
   player // currently moving player
   gfxes
   seed
   tid_map/Main.tid_map
   filler
   shadows
   cycle // counts calls to world.update
   serial
   turn // turn in terms of game logic
   nil // null unit with id >< 0
   owners // unit owners
   active // active units
   vars/t{} // variables
   xunit
   yunit
   zunit
   on_player_change
   on_update
   marks
   params
   waiting // true if wating for action to complete
| $init{W H}

world.init W H =
//| W <= 128
//| H <= 128
| $main.world <= Me
| WParam = $main.params.world
| MaxSize <= WParam.max_size
| MaxUnits <= WParam.max_units
| $players <= map Id WParam.max_players: player Id Me
| $xunit <= WParam.x_unit
| $yunit <= WParam.y_unit
| $zunit <= WParam.z_unit
| $tilemap <= zmap MaxSize
| $unit_map <= zmap MaxSize
| $slope_map <= zmap MaxSize
| $move_map <= zmap MaxSize
| $units <= MaxUnits{(unit ? Me)}
| $free_units <= stack $units.flip
| $proxies <= MaxUnits{(proxy ?)}
| $free_proxies <= stack $proxies.flip
| $active <= stack MaxActiveUnits
| $shadows <= $main.sprites.unit_shadows.frames
| $filler <= $main.tiles.base_
| SS = MaxSize*MaxSize
| $gfxes <= MaxSize{_=>MaxSize{_=>[]}}
| $seed <= MaxSize{_=>MaxSize{_=>SS.rand}}
| $nil <= $alloc_unit{unit_nil}
//| StartTime = clock
| $create{W H}
//| EndTime = clock
//| say EndTime-StartTime
//| halt

world.create W H =
| $w <= W
| $h <= H
| !$w+1
| !$h+1
| $clear
| for Y $h: when Y: for X $w: when X: $push_{X Y $filler}
| for Y $h: when Y: for X $w: when X: $updPilarGfxes{X,Y}
| for Y $h: when Y: for X $w: when X: $update_move_map{X,Y}
| !$w-1
| !$h-1
| $create_borders

// add movement blocking walls
world.create_borders =
| for P points{0    0    $w+2 1   }: times I 26: $push_{P.0 P.1 $filler}
| for P points{0    0    1    $h+2}: times I 26: $push_{P.0 P.1 $filler}
| for P points{0    $h+1 $w+2 1   }: times I 26: $push_{P.0 P.1 $filler}
| for P points{$w+1 0    1    $h+2}: times I 26: $push_{P.0 P.1 $filler}

world.clear =
| for U $units: less U.removed: U.free
| $tilemap.clear{0}
| $move_map.clear{0}
| for P $players: P.clear
| $player <= $players.0
| $players.1.human <= 1
| $marks <= $nil
| $params <= t

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

world.picked = $player.picked
world.`!picked` U = $player.picked <= U

world.get X Y Z =
| Id = $tilemap.at{[X Y Z]}
| if Id < 0 then $tilemap.at{[X Y Z-Id]}
  else Id

world.at XYZ =
| X,Y,Z = XYZ
| $tid_map.| if X < 0 or Y < 0 then 0 else $get{X Y Z}

world.fast_at XYZ =
| Id = $tilemap.at{XYZ}
| when Id < 0: Id <= $tilemap.at{[XYZ.0 XYZ.1 XYZ.2-Id]}
| $tid_map.Id

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

world.proxies_at XYZ =
| when!it $unit_map.at{XYZ}: leave $proxies.it^uncons{next}
| []

world.column_proxies_at X Y =
| when!it $unit_map.at{X,Y,0}: leave $proxies.it^uncons{column_next}
| []

world.units_at XYZ = $proxies_at{XYZ}{?unit_}

world.no_block_at XYZ = $units_at{XYZ}.all{?empty}

world.column_units_at X Y = $column_proxies_at{X Y}{?unit_}

world.block_at XYZ =
| Block = $units_at{XYZ}.skip{?empty}
| if Block.size then Block.head else No

world.place_unitS UU =
| U = $free_proxies.pop
| U.init{UU}
| XYZ = U.xyz
| Us = U,@$proxies_at{XYZ}
| Consed = Us^cons{next}
| Id = if Consed then Consed.id else 0
| $unit_map.set{XYZ Id}
| Us = U,@$column_proxies_at{XYZ.0 XYZ.1}.skip{?id >< U.id}
| Consed = Us^cons{column_next}
| Id = if Consed then Consed.id else 0
| $unit_map.set{XYZ.0,XYZ.1,0 Id}

world.place_unit U =
| XYZ = U.xyz.copy
| Mirror = U.facing >< 5
| for XX,YY,ZZ U.form:
  | U.xyz.init{XYZ + if Mirror then [-YY XX ZZ] else [XX -YY ZZ]}
  | $place_unitS{U}
| U.xyz.init{XYZ}

world.remove_unitS U =
| XYZ = U.xyz
| Us = []
| for P $proxies_at{XYZ}: if P.unit_.id >< U.id 
  then $free_proxies.push{P} 
  else push P Us
| Consed = Us^cons{next}
| Id = if Consed then Consed.id else 0
| $unit_map.set{XYZ Id}
| Us = $column_proxies_at{XYZ.0 XYZ.1}.skip{?.unit_.id >< U.id}
| Consed = Us^cons{column_next}
| Id = if Consed then Consed.id else 0
| $unit_map.set{XYZ.0,XYZ.1,0 Id}

world.remove_unit U =
| XYZ = U.xyz.copy
| when XYZ.2 >< -1: leave
| Mirror = U.facing >< 5
| for XX,YY,ZZ U.form:
  | U.xyz.init{XYZ + if Mirror then [-YY XX ZZ] else [XX -YY ZZ]}
  | $remove_unitS{U}
| U.xyz.init{XYZ}


world.effect X,Y,Z What =
| E = $alloc_unit{"effect_[What]"}
| E.move{X,Y,Z}
| A = E.order.init{act/die cost/0}
| A.priority <= 1000

world.filled X,Y Z =
| when X < 0 or Y < 0: leave 1
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
| when X < 0 or Y < 0: leave 0
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
| when X < 0 or Y < 0: leave 0
| Tile = $tid_map.($get{X Y Z})
| if Tile.trn then Tile.role else 0

world.getCornersTrns P Z Role = `[]`
 [$getTrn{P+[-1 -1] Z} $getTrn{P+[0 -1] Z} $getTrn{P+[-1 0] Z}].all{is{&Role+0}}
 [$getTrn{P+[ 1 -1] Z} $getTrn{P+[0 -1] Z} $getTrn{P+[ 1 0] Z}].all{is{&Role+0}}
 [$getTrn{P+[ 1  1] Z} $getTrn{P+[0  1] Z} $getTrn{P+[ 1 0] Z}].all{is{&Role+0}}
 [$getTrn{P+[-1  1] Z} $getTrn{P+[0  1] Z} $getTrn{P+[-1 0] Z}].all{is{&Role+0}}

world.getPilar X Y =
| when X < 0 or Y < 0: leave [$filler X,Y,0 MaxSize-1]
| $tilemap.getPilar{X Y}

world.updPilarGfxes P =
| X,Y = P
| when X < 0 or Y < 0: leave 0
| Seed = $seed.Y.X
| Gs = []
| Z = 0
| Column = $tilemap.data.X.Y
| Below = $tid_map.0
| C = $tid_map.(Column.0)
| while C.id
  | NextZ = Z + C.height
  | TileId = Column.NextZ
  | when TileId < 0: TileId <= Column.(NextZ-TileId)
  | Above = $tid_map.TileId
  | if C.invisible
    then push 1 Gs
    else // NextZ-1 is a hack to exclude short tiles from tiling with tall-tiles
         push C.render{P NextZ-1 Below Above Seed} Gs
  | Below <= C
  | C <= Above
  | Z <= NextZ
| _label for_break
| Gs = Gs.flip
| PrevGs = $gfxes.Y.X
| if PrevGs.size >< Gs.size then PrevGs.init{Gs}
  else if PrevGs.size > Gs.size
    then PrevGs.init{[@Gs @(dup PrevGs.size-Gs.size 0)]}
  else $gfxes.Y.X <= Gs
| for U $column_units_at{X Y}: U.environment_updated

world.updElev P =
| for D Dirs: $updPilarGfxes{P+D}
| $updPilarGfxes{P}
| $update_move_map{P}

world.height X Y = $tilemap.height{X Y}

world.push_ X Y Tile =
| Z = $height{X Y}
| H = Tile.height-1
| times I H: $set_{X Y Z+I I-H} // push padding
| $set_{X Y Z+H Tile.id}


// push Tile on top of pilar at X,Y
world.push XY Tile =
| $push_{XY.0 XY.1 Tile}
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
