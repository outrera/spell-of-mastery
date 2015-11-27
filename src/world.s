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
   void
   shadow
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
| $void <= $main.tiles.void
| $tilemap <= zmap MaxSize $void
| $unit_map <= zmap MaxSize 0
| $slope_map <= zmap MaxSize 0
| $move_map <= zmap MaxSize 0
| $units <= MaxUnits{(unit ? Me)}
| $free_units <= stack $units.flip
| $proxies <= MaxUnits{(proxy ?)}
| $free_proxies <= stack $proxies.flip
| $active <= stack MaxActiveUnits
| $shadow <= $main.sprites.system_shadow.frames
| SS = MaxSize*MaxSize
| $gfxes <= MaxSize{_=>MaxSize{_=>[]}}
| $seed <= MaxSize{_=>MaxSize{_=>SS.rand}}
| $nil <= $alloc_unit{unit_nil owner/$players.0}
| $main.params.unit_setters_ <=
  | ($nil)^methods_.keep{?0.0 >< '!'}{[?0.tail ?1]}.table

world.create W H =
| $w <= W
| $h <= H
| !$w+1
| !$h+1
| $clear
| Filler = $main.tiles.base_
| for Y $h: when Y: for X $w: when X: $push_{X Y Filler}
| for Y $h: when Y: for X $w: when X: $updPilarGfxes{X,Y}
| for Y $h: when Y: for X $w: when X: $update_move_map_{X,Y}
| !$w-1
| !$h-1
| $create_borders

// add movement blocking walls
world.create_borders =
| Border = $main.tiles.border_
| for P points{0    0    $w+2 1   }: times I 26: $push_{P.0 P.1 Border}
| for P points{0    0    1    $h+2}: times I 26: $push_{P.0 P.1 Border}
| for P points{0    $h+1 $w+2 1   }: times I 26: $push_{P.0 P.1 Border}
| for P points{$w+1 0    1    $h+2}: times I 26: $push_{P.0 P.1 Border}

world.clear =
| $act <= 0
| for U $units: less U.removed: U.free
| $tilemap.clear{$void}
| $move_map.clear{0}
| for P $players: P.clear
| $player <= $players.0
| $players.1.human <= 1
| $human <= $players.1
| $marks <= $nil
| $waiting <= 0
| $params <= t
| for U $active.list: U.active <= 0
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
| less got Class:
  | $notify{"Missing class `[ClassName]`"}
  | Class <= $main.classes.trigger_missing
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

world.at X Y Z = $tilemap.at{X Y Z}

world.set_ X Y Z V = $tilemap.set{X Y Z V}

world.clear_tile_ XYZ Filler =
| X,Y,Z = XYZ
| Tile = $tilemap.at{X Y Z}
| when Tile.parts.is_int
  | !Z-Tile.parts
  | Tile <= $tilemap.at{X Y Z}
| less Tile.id: leave
| times I Tile.height
  | $set_{X Y Z-I Filler}
  | $set_slope_at{X Y (Z-I) #@0000}
| $updElev{X,Y}

world.clear_tile XYZ Filler =
| $clear_tile_{XYZ Filler}
| XY = XYZ.take{2}
| $update_move_map{XY}

can_move Me SX SY SZ DX DY DZ =
| H = DZ-SZ
| if H < 0
  then | when H < -4: leave 0
       | when H > -4: leave 1
       | $at{SX SY SZ-1}.stairs
  else | when H > 4: leave 0
       | when H < 4: leave 1
       | $at{DX DY DZ-1}.stairs

MoveMapZs = [-4 -3 -2 -1 0 1 2 3 4]
MoveMapXYs = [[1 0] [-1 0] [0 1] [0 -1]]
MoveMapXYZs = @join: map Z MoveMapZs: map X,Y MoveMapXYs: [X Y Z]

MoveMapDirMap =
| T = dup 4: dup 4: dup 10: 0
| I = 0
| for X,Y,Z MoveMapXYZs:
  | T.(X+1).(Y+1).(Z+4) <= I
  | !I+1
| T

world.update_move_map_ P =
| SX,SY = P
| when SX < 1 or SY < 1: leave
| times SZ $height{SX SY}
  | SZ = SZ+1
  | M = 0
  | when $at{SX SY SZ}.empty: for X,Y,Z MoveMapXYZs:
    | DX = SX+X
    | DY = SY+Y
    | DZ = SZ+Z
    | Empty = DZ > 0 and $at{DX DY DZ}.empty
    | when Empty and can_move{Me SX SY SZ DX DY DZ}:
      | F = MoveMapDirMap.(X+1).(Y+1).(Z+4) 
      | M <= M ++ (1</F)
  | $move_map.set{SX SY SZ M}

world.update_move_map XY =
| $update_move_map_{XY}
| for D Dirs: $update_move_map_{XY+D}

unit.can_move Src Dst =
| DX,DY,DZ = Dst
| when $flyer: leave $world.at{DX DY DZ}.empty // FIXME: check for roof
| M = $world.move_map.at{Src.0 Src.1 Src.2}
| X,Y,Z = Dst-Src
| when Z.abs > 4: leave 0
| F = MoveMapDirMap.(X+1).(Y+1).(Z+4) 
| M^^(1</F)


world.clear_passage X Y Z =
| HH = $fix_z{X,Y,Z}
| H = HH
| when H-Z < 5: leave
| ZZ = Z
| AddCeil = 1
| while Z<H:
  | less $at{X,Y,Z}.clear:
    | H<=Z
    | AddCeil <= 0
  | !Z+1
| Z <= ZZ
| when H-Z < 5: leave
| while Z<H:
  | when Dirs.all{DX,DY=>$at{[X+DX Y+DY Z]}.empty}: H<=Z
  | !Z+1
| Z <= ZZ
| when H-Z < 5: leave
| while Z<H:
  | $set{X Y Z $main.tiles.filler1}
  | !Z+1
| when AddCeil: $set{X Y H-1 $main.tiles.floor_wooden}
| XY = X,Y
| $update_move_map{XY}


// FIXME: remove overlapping tiles above setted tile
world.dirty_set X Y Z Tile =
| H = Tile.height
| times I H: $clear_tile_{X,Y,Z+I $void}
| Ps = Tile.parts
| H = H-1
| times I H: $set_{X Y Z+I Ps.I} // push padding
| $set_{X Y Z+H Tile}

world.set X Y Z Tile =
| $dirty_set{X Y Z Tile}
| $updElev{X,Y}

world.fix_z XYZ =
| X,Y,Z = XYZ
| till $at{X Y Z}.empty: !Z+1
| !Z-1
| while $at{X Y Z}.empty: !Z-1
| !Z+1
| Z

world.fix_z_void XYZ =
| X,Y,Z = XYZ
| while $at{X Y Z}.id: !Z+1
| !Z-1
| till $at{X Y Z}.id: !Z-1
| !Z+1
| Z

world.roof XYZ =
| X,Y,Z = XYZ
| while $at{X Y Z}.empty and Z < 63: !Z+1
| Z

world.slope_at X Y Z = $slope_map.at{X Y Z}

world.set_slope_at X Y Z Slope = $slope_map.set{X Y Z Slope}

world.proxies_at X,Y,Z =
| when!it $unit_map.at{X Y Z}: leave $proxies.it^uncons{next}
| []

world.column_proxies_at X Y =
| when!it $unit_map.at{X Y 0}: leave $proxies.it^uncons{column_next}
| []

world.units_at XYZ = $proxies_at{XYZ}{?unit_}

world.column_units_at X Y = $column_proxies_at{X Y}{?unit_}

world.no_block_at XYZ = $units_at{XYZ}.all{?empty}

world.block_at XYZ =
| Block = $units_at{XYZ}.skip{?empty}
| if Block.size then Block.head else No

world.place_unitS UU =
| U = $free_proxies.pop
| U.init{UU}
| XYZ = U.xyz
| X,Y,Z = XYZ
| Us = U,@$proxies_at{XYZ}
| Consed = Us^cons{next}
| Id = if Consed then Consed.id else 0
| $unit_map.set{X Y Z Id}
| Us = U,@$column_proxies_at{X Y}.skip{?id >< U.id}
| Consed = Us^cons{column_next}
| Id = if Consed then Consed.id else 0
| $unit_map.set{X Y 0 Id}

unit.explore V =
| Sight = $sight
| when no Sight: leave
| XYZ = $xyz
| Explored = $owner.sight
| UX = XYZ.0
| UY = XYZ.1
| for X,Y points{UX-Sight UY-Sight Sight*2+1 Sight*2+1}: when X>>0 and Y>>0:
  | E = Explored.Y
  | less E.X: E.X <= 1
  | !E.X+V

world.explore State = for P $players: P.explore{State}

world.seen X Y = $human.sight.Y.X>1

world.place_unit U =
| XYZ = U.xyz.copy
| Mirror = U.facing >< 5
| for XX,YY,ZZ U.form:
  | U.xyz.init{XYZ + if Mirror then [-YY XX ZZ] else [XX -YY ZZ]}
  | $place_unitS{U}
| U.xyz.init{XYZ}
| U.explore{1}

world.remove_unitS U =
| U.explore{-1}
| XYZ = U.xyz
| Us = []
| for P $proxies_at{XYZ}: if P.unit_.id >< U.id 
  then $free_proxies.push{P} 
  else push P Us
| Consed = Us^cons{next}
| Id = if Consed then Consed.id else 0
| X,Y,Z = XYZ
| $unit_map.set{X Y Z Id}
| Us = $column_proxies_at{X Y}.skip{?.unit_.id >< U.id}
| Consed = Us^cons{column_next}
| Id = if Consed then Consed.id else 0
| $unit_map.set{X Y 0 Id}

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

world.neibs X Y Z =
  [$at{X Y-1 Z} $at{X+1 Y Z} $at{X Y+1 Z} $at{X-1 Y Z}
   $at{X+1 Y-1 Z} $at{X+1 Y+1 Z} $at{X-1 Y+1 Z} $at{X-1 Y-1 Z}]

world.filled X,Y Z =
| when X < 0 or Y < 0: leave 1
| $at{X Y Z}.filler

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
| $at{X Y Z}.role

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
| Tile = $at{X Y Z}
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
| C = Column.0
| while C.id
  | NextZ = Z + C.height
  | Above = Column.NextZ
  | when Above.parts.is_int: Above <= Column.(NextZ-Above.parts)
  // NextZ-1 is a hack to exclude short tiles from tiling with tall-tiles
  | push C.render{X Y NextZ-1 Below Above Seed} Gs
  | Below <= C
  | C <= Above
  | Z <= NextZ
| Gs = Gs.flip
| PrevGs = $gfxes.Y.X
| if PrevGs.size >< Gs.size then PrevGs.init{Gs}
  else if PrevGs.size > Gs.size
    then | Dummy = $nil.sprite.frames.0
         | PrevGs.init{[@Gs @(dup PrevGs.size-Gs.size Dummy)]}
  else $gfxes.Y.X <= Gs
| for U $column_units_at{X Y}: U.environment_updated

world.updElev P =
| for D Dirs: $updPilarGfxes{P+D}
| $updPilarGfxes{P}
| $update_move_map_{P}

world.height X Y = $tilemap.height{X Y}

world.push_ X Y Tile =
| Z = $height{X Y}
| H = Tile.height-1
| Ps = Tile.parts
| times I H: $set_{X Y Z+I Ps.I} // push padding
| $set_{X Y Z+H Tile}


// push Tile on top of pilar at X,Y
world.push XY Tile =
| $push_{XY.0 XY.1 Tile}
| $updElev{XY}

world.pop_ X,Y =
| H = $height{X Y}
| less H: leave
| Z = H-1
| $set_slope_at{X Y Z #@0000}
| T = $at{X Y Z}
| times I T.height: $set_{X Y Z-I $void}

// pop top tile of pilar at X,Y
world.pop XY =
| $pop_{XY}
| $updElev{XY}

export world
