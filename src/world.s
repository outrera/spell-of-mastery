use stack heap zmap util unit player

MaxSize = No
MaxUnits = No
MaxActiveUnits = 4096
NoteLife = 1.0

type proxy.$unit_{id}
  unit_ 
  next // next unit inside of this world cell
  column_next // next unit inside of this world column

proxy.as_text = "#proxy{[$id] [$type] [$unit_id]}"

proxy.init Unit =
| $unit_ <= Unit
| $next <= 0
| $column_next <= 0

type world{main}
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
   human // human player hosting this session
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
   events
   view
   act
   notes
   mode/brush
| $init

world.init =
| $main.world <= Me
| WParam = $main.params.world
| MaxSize <= WParam.max_size
| MaxUnits <= WParam.max_units
| NoteSize = WParam.note_size
| NoteLife <= WParam.note_life
| $notes <= dup WParam.max_notes
  | [0.0 (dup NoteSize ``)]
| $players <= map Id WParam.max_players: player Id Me
| $player <= $players.0
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
| $nil <= $alloc_unit{unit_nil owner/$players.0}

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
| $act <= 0
| for U $units: less U.removed: U.free
| $tilemap.clear{0}
| $move_map.clear{0}
| for P $players: P.clear
| $player <= $players.0
| $players.1.human <= 1
| $human <= $players.1
| $marks <= $nil
| $waiting <= 0
| $params <= t
| $active.clear

world.notify Text =
| Clock = clock
| Used = $notes.keep{?0 > Clock}
| Free = $notes.skip{?0 > Clock}
| less Free.size: push Used^pop Free
| N = Free.0
| N.0 <= Clock + NoteLife
| Chars = N.1
| Chars.clear{``}
| for I Text.size: Chars.I <= Text.I
| $notes.init{[@Used @Free]}

world.alloc_unit ClassName owner/0 =
| Class = $main.classes.ClassName
| less got Class: bad "Missing class `[ClassName]`"
| U = $free_units.pop
| less Owner: Owner <= $player
| when Class.ai >< pentagram
  | Pentagram = Owner.pentagram
  | when Pentagram
    | $free_units.push{U}
    | leave Pentagram
  | Owner.pentagram <= U
| till U.removed: U <= $free_units.pop
| U.init{Class}
| U.owner <= Owner
| U.owner.got_unit{U}
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

world.clear_tile XYZ =
| Id = $tilemap.at{XYZ}
| less Id: leave
| X,Y,Z = XYZ
| when Id<0: !Z-Id
| Tile = $tid_map.($tilemap.at{X,Y,Z})
| times I Tile.height
  | $set_{X Y Z-I 0}
  | $set_slope_at{X,Y,(Z-I) #@0000}
| $updElev{X,Y}

// FIXME: remove overlapping tiles above setted tile
world.dirty_set X Y Z Tile =
| H = Tile.height
| times I H: $clear_tile{X,Y,Z+I}
| H = H-1
| times I H: $set_{X Y Z+I I-H} // push padding
| $set_{X Y Z+H Tile.id}

world.set X Y Z Tile =
| $dirty_set{X Y Z Tile}
| $updElev{X,Y}

world.fix_z XYZ =
| X,Y,Z = XYZ
| till $fast_at{X,Y,Z}.empty: !Z+1
| !Z-1
| while $fast_at{X,Y,Z}.empty: !Z-1
| !Z+1
| Z

world.fix_z_void XYZ =
| X,Y,Z = XYZ
| while $fast_at{X,Y,Z}.id: !Z+1
| !Z-1
| till $fast_at{X,Y,Z}.id: !Z-1
| !Z+1
| Z


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

unit.explore =
| Sight = $sight
| when no Sight: leave
| XYZ = $xyz
| Explored = $owner.sight
| UX = XYZ.0
| UY = XYZ.1
| for X,Y points{UX-Sight UY-Sight Sight*2+1 Sight*2+1}: when X>>0 and Y>>0:
  | Explored.Y.X <= 1

world.place_unit U =
| XYZ = U.xyz.copy
| Mirror = U.facing >< 5
| for XX,YY,ZZ U.form:
  | U.xyz.init{XYZ + if Mirror then [-YY XX ZZ] else [XX -YY ZZ]}
  | $place_unitS{U}
| U.xyz.init{XYZ}
| U.explore

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
| E = $alloc_unit{"effect_[What]" owner/$players.0}
| E.move{X,Y,Z}
| E.die
| E

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
  // NextZ-1 is a hack to exclude short tiles from tiling with tall-tiles
  | push C.render{P NextZ-1 Below Above Seed} Gs
  | Below <= C
  | C <= Above
  | Z <= NextZ
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
