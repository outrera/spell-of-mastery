use gfx stack heap zmap util line_points unit player

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
   w //width
   h //height
   d //depth
   c //cell dimension unit
   maxSize //max size
   filename/`default`
   name/`default map`
   description/`describe the map here`
   tilemap
   unit_map
   lightmap
   heighmap
   units
   free_units
   proxies
   free_proxies
   players
   human // human controlled player
   gfxes
   seed
   tid_map/Main.tid_map
   void
   shadow
   cycle // counts calls to world.update
   serial
   nil // null unit with id >< 0
   owners // unit owners
   active // active units
   vars/t{} // variables
   marks/[]
   params/(t)
   events
   view //viewport, attached rendering this world
   act
   notes
   mode/brush
   sound_cycles/(t) //used to avoid playing similar sounds at once
   blink/[0 0]
   minimap/0
| $init

world.second = $cycle/24
world.turn = $second/10
world.new_turn = $cycle%(24*10)><0

world.init =
| $main.world <= Me
| $minimap <= gfx 128 128
| WParam = $main.params.world
| $d <= WParam.depth
| $maxSize <= WParam.max_size+12 //FIXME: get rid of this 12 margin
| MaxUnits <= WParam.max_units
| NoteSize = WParam.note_size
| NoteLife <= WParam.note_life
| $notes <= dup WParam.max_notes
  | [0.0 (dup NoteSize ``)]
| $players <= map Id WParam.max_players: player Id Me
| $c <= WParam.cell_size
| $void <= $main.tiles.void
| $tilemap <= zmap $maxSize $d $void
| $unit_map <= zmap $maxSize $d 0
| $lightmap <= zmap $maxSize $d 0
| $heighmap <= dup $maxSize: @bytes $maxSize
| $units <= MaxUnits{(unit ? Me)}
| $free_units <= stack $units.flip
| $proxies <= MaxUnits{(proxy ?)}
| $free_proxies <= stack $proxies.flip
| $active <= stack MaxActiveUnits
| $shadow <= $main.sprites.system_shadow.frames
| SS = $maxSize*$maxSize
| MaxSize = $maxSize
| $gfxes <= MaxSize{_=>MaxSize{_=>[]}}
| $seed <= MaxSize{_=>MaxSize{_=>SS.rand}}
| $nil <= $players.0.alloc_unit{unit_nil}
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
| for Y $h: when Y: for X $w: when X: $updPilarGfxes{X Y}
| !$w-1
| !$h-1
| $create_borders

calc_height Cs =
| Z = Cs.size
| while Z
  | !Z-1
  | when Cs.Z.id: leave Z+1
| 0

create_border_column Me X Y =
| Border = $main.tiles.border_
| Hs = $heighmap.X
| times I $d-1:
  | $push_{X Y Border}
  | !Hs.Y+1
| $heighmap.X.Y <= calc_height $tilemap.data.X.Y

// add movement blocking walls
world.create_borders = // draws maps borders in clockwise order
| for X,Y points{0    0    $w+1 1   }: create_border_column Me X Y
| for X,Y points{$w+1 0    1    $h+1}: create_border_column Me X Y
| for X,Y points{1    $h+1 $w+1 1   }: create_border_column Me X Y
| for X,Y points{0    1    1    $h+1}: create_border_column Me X Y

world.clear =
| $minimap.clear{#000000}
| $lightmap.clear{0}
| $act <= 0
| for U $units: less U.removed: U.free
| $tilemap.clear{$void}
| for H $heighmap: H.clear{0}
| for P $players: P.clear
| $human <= $players.1
| $human.human <= 1
| $marks.heapfree
| $marks <= []
| for K,V $params: $params.K <= No
| for U $active.list: U.active <= 0
| $active.clear
| for [K V] $sound_cycles: $sound_cycles.K <= 0
| $blink.init{[0 0]}

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

world.alloc_unit ClassName Owner =
| Class = $main.classes.ClassName
| less got Class:
  | $notify{"Missing class `[ClassName]`"}
  | Class <= $main.classes.trigger_missing
| U = $free_units.pop
| when Class.leader and Class.leader><1:
  | when Owner.leader: Owner.leader.free
  | Owner.leader <= U
| when Class.ai >< pentagram
  | Pentagram = Owner.pentagram
  | when Pentagram
    | $free_units.push{U}
    | leave Pentagram
  | Owner.pentagram <= U
| till U.removed: U <= $free_units.pop
| U.init{Class}
| U.owner <= Owner
| U.colors <= Owner.colors
| U.owner.got_unit{U}
| U

player.alloc_unit ClassName = $world.alloc_unit{ClassName Me}


world.free_unit U =
| when U.id
  | U.remove
  | $free_units.push{U}

world.picked = $player.picked
world.`!picked` Us = $player.picked <= Us

world.at X Y Z = $tilemap.at{X Y Z}
world.get XYZ = $tilemap.at{XYZ.0 XYZ.1 XYZ.2}

world.set_ X Y Z V = $tilemap.set{X Y Z V}

world.clear_tile X Y Z =
| Filler = $void
| Tile = $tilemap.at{X Y Z}
| when Tile.parts.is_int
  | !Z-Tile.parts
  | Tile <= $tilemap.at{X Y Z}
| less Tile.id: leave
| times I Tile.height
  | $set_{X Y Z-I Filler}
| when Tile.wall:
  | ZZ = 0
  | RT = 0
  | when Tile.roof.is_list:
    | H,RoofTile = Tile.roof
    | RT <= RoofTile
    | ZZ <= Z+H+1
    | less ZZ < $d: ZZ <= 0
    | when ZZ and $at{X Y ZZ}.type><RT.type: $clear_tile{X Y ZZ}
  | for DX,DY Dirs: //tile has associated walls
    | XX = X+DX
    | YY = Y+DY
    | TT = Tile.type
    | when ZZ and $at{XX YY ZZ}.type><RT.type: $clear_tile{XX YY ZZ}
    | when $at{XX YY Z}.around><TT:
      | when Dirs.all{DX,DY=>$at{XX+DX YY+DY Z}.type<>TT}
        | $clear_tile{XX YY Z}
| $upd_column{X Y}

world.clear_passage X Y Z PassageH =
| H = min $fix_z{X,Y,Z} Z+PassageH
| when H-Z < 5: leave
| ZZ = Z
| AddCeil = 1
| while Z<H:
  | less $at{X Y Z}.clear:
    | H<=Z
    | AddCeil <= 0
  | !Z+1
| Z <= ZZ
| when H-Z < 5: leave
| while Z<H:
  | Type = $at{X Y Z}.type
  | $set{X Y Z $main.tiles.void}
  | when Type<>void:
    | S = $players.0.alloc_unit{unit_dummy}
    | S.move{[X Y Z]}
    | S.add_effect{retile 24*10 [[effect [on timeout] [retile [[X Y Z] Type]]]]}
  | !Z+1
| when AddCeil: $set{X Y H-1 $main.tiles.floor_wooden}
| XY = X,Y


// FIXME: remove overlapping tiles above setted tile
world.dirty_set X Y Z Tile =
| H = Tile.height
| times I H: $clear_tile{X Y Z+I}
| Ps = Tile.parts
| H = H-1
| times I H: $set_{X Y Z+I Ps.I} // push padding
| $set_{X Y Z+H Tile}

world.set X Y Z Tile =
| $dirty_set{X Y Z Tile}
| $upd_column{X Y}

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
| while $at{X Y Z}.empty and Z < $d-1: !Z+1
| Z


world.seen_from A B =
| AX,AY,AZ = A
| BX,BY,BZ = B
| DZ = (BZ-AZ)
| PX = AX
| PY = AY
| PZ = AZ
| BottomClear = 1
| when DZ.abs>16: leave 0 //z-difference is too large
| when DZ > 4:
  | BAX = BX + (AX-BX).sign
  | BAY = BY + (AY-BY).sign
  | BottomClear <= $at{BAX BAY BZ}.empty and $at{BAX BAY BZ-1}.empty
| line_calls3d AX AY AZ BX BY BZ: X Y Z =>
  | R = 0
  | DX = X-PX
  | DY = Y-PY
  | when DX*DX><1 and DY*DY><1:
    | less $at{PX+DX PY Z}.empty or $at{PX PY+DY Z}.empty: _goto end
  | PX <= X
  | PY <= Y
  | PZ <= Z
  | R <= $at{X Y Z}.empty
         or (X><AX and Y><AY)
         or (BottomClear and X><BX and Y><BY)
  | _label end
  | R

world.fxyz XYZ = [XYZ.0*32 XYZ.1*32 XYZ.2*8]

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
| Blocker = U.passable and U.block
| for XX,YY,ZZ U.form:
  | P = XYZ + if Mirror then [-YY XX ZZ] else [XX -YY ZZ]
  | U.xyz.init{P}
  | $place_unitS{U}
  | when Blocker: $set{@P U.block}
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
| Blocker = U.passable and U.block
| for XX,YY,ZZ U.form:
  | P = XYZ + if Mirror then [-YY XX ZZ] else [XX -YY ZZ]
  | U.xyz.init{P}
  | $remove_unitS{U}
  | when Blocker: $clear_tile{@P}
| U.xyz.init{XYZ}

world.effect X,Y,Z What =
| E = $players.0.alloc_unit{"effect_[What]"}
| E.move{X,Y,Z}
| E.die
| E

world.targets_in_range Center R =
| Targets = []
| Points = points_in_circle R
| for X,Y Points
  | XYZ = Center+[X Y 0]
  | X = XYZ.0
  | Y = XYZ.1
  | when X>0 and X<<$w and Y>0 and Y<<$h:
    | for U $column_units_at{X Y}: when $seen_from{Center U.xyz}:
      | when (U.xyz.2-XYZ.2).abs<R*2:
        | push U Targets
| Targets

world.neibs X Y Z =
  [$at{X Y-1 Z} $at{X+1 Y Z} $at{X Y+1 Z} $at{X-1 Y Z}
   $at{X+1 Y-1 Z} $at{X+1 Y+1 Z} $at{X-1 Y+1 Z} $at{X-1 Y-1 Z}]

world.filled X Y Z =
| when X < 0 or Y < 0: leave 1
| $at{X Y Z}.filler

world.getCorners X Y Z = `[]`
  [$filled{X-1 Y-1 Z} $filled{X Y-1 Z} $filled{X-1 Y Z}].all{1}
  [$filled{X+1 Y-1 Z} $filled{X Y-1 Z} $filled{X+1 Y Z}].all{1}
  [$filled{X+1 Y+1 Z} $filled{X Y+1 Z} $filled{X+1 Y Z}].all{1}
  [$filled{X-1 Y+1 Z} $filled{X Y+1 Z} $filled{X-1 Y Z}].all{1}

world.getSides X Y Z = `[]`
  $filled{X Y-1 Z} $filled{X+1 Y Z}
  $filled{X Y+1 Z} $filled{X-1 Y Z}

world.role X Y Z =
| when X < 0 or Y < 0: leave 0
| $at{X Y Z}.role

world.getCornersSame X Y Z Role = `[]`
  [$role{X-1 Y-1 Z} $role{X Y-1 Z} $role{X-1 Y Z}].all{Role}
  [$role{X+1 Y-1 Z} $role{X Y-1 Z} $role{X+1 Y Z}].all{Role}
  [$role{X+1 Y+1 Z} $role{X Y+1 Z} $role{X+1 Y Z}].all{Role}
  [$role{X-1 Y+1 Z} $role{X Y+1 Z} $role{X-1 Y Z}].all{Role}

world.getSidesSame X Y Z Role = `[]`
  $role{X Y-1 Z}><Role $role{X+1 Y Z}><Role
  $role{X Y+1 Z}><Role $role{X-1 Y Z}><Role

world.color_at X Y =
| Z = $height{X Y}-1
| Gs = $gfxes.Y.X
| when Z > 0 and not Gs.last:
  | Gs <= Gs.lead
  | !Z-1
| G = Gs.last
| less G: leave 0
| G.get{G.w/2 (min G.h/2 16)} ^^ #FFFFFF

world.update_minimap X Y =
| Z = $height{X Y}-1
| T = $at{X Y Z}
| G = $gfxes.Y.X.last
| Color = $color_at{X Y}
| WW = $w
| WH = $h
| MW = $minimap.w
| MH = $minimap.h
//| SX = (MW-WW)/2
//| SY = (MH-WH)/2
| PW = (MW+WW-1)/WW
| PH = (MH+WH-1)/WH
| SX = (X-1)*PW
| SY = (Y-1)*PH
| for YY PH: for XX PW:
  | $minimap.set{SX+XX SY+YY Color}

world.updPilarGfxes X Y =
| when X < 0 or Y < 0: leave 0
| $heighmap.X.Y <= calc_height $tilemap.data.X.Y
| Seed = $seed.Y.X
| Gs = []
| Z = 0
| H = $height{X Y}
| Column = $tilemap.data.X.Y
| Below = $tid_map.0
| C = Column.0
| while Z < H:
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
| $update_minimap{X Y}

world.upd_column X Y =
| $heighmap.X.Y <= calc_height $tilemap.data.X.Y
| for DX,DY Dirs: $updPilarGfxes{X+DX Y+DY}
| $updPilarGfxes{X Y}

world.height X Y = $heighmap.X.Y

world.outdoor XYZ = $height{XYZ.0 XYZ.1} << XYZ.2

world.up XYZ = //finds Z of the floor above
| X,Y,Z = XYZ
| H = $height{X Y}
| when Z>>H: leave 0
| while Z<H and $at{X Y Z}.empty: !Z+1
| till Z>>H or $at{X Y Z}.empty: !Z+1
| leave Z

world.down XYZ = //finds Z of the floor below
| X,Y,Z = XYZ
| B = 1
| till $at{X Y B}.empty: !B+1
| when Z<<B: leave 0
| while Z>B and $at{X Y Z}.empty: !Z-1
| till Z<<B or $at{X Y Z}.empty: !Z-1
| while Z>B and $at{X Y Z-1}.empty: !Z-1
| leave Z

world.valid X Y Z =
| X >> 0 and Y >> 0 and Z >> 0 and X << $w and Y << $h and Z < $d

world.push_ X Y Tile =
| Z = $height{X Y}
| H = Tile.height-1
| Ps = Tile.parts
| times I H: $set_{X Y Z+I Ps.I} // push padding
| $set_{X Y Z+H Tile}


// push Tile on top of pilar at X,Y
world.push XY Tile =
| X,Y = XY
| $push_{X Y Tile}
| $upd_column{X Y}

world.pop_ X,Y =
| H = $height{X Y}
| less H: leave
| Z = H-1
| T = $at{X Y Z}
| times I T.height: $set_{X Y Z-I $void}

// pop top tile of pilar at X,Y
world.pop XY =
| $pop_{XY}
| $upd_column{XY.0 XY.1}

export world
