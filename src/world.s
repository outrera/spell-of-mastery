use gfx stack heap util line_points unit player

MaxUnits = No
MaxActiveUnits = 4096
NoteLife = 1.0

type efx when name amount params

CellsTile =
CellsUnits =
CellsGfxes =
CellsBlock =
CellsVisited =
WorldSize = 1 //max world size
WorldDepth = 1
CellsLineSize = 1

//FIXME: such structs could be defined with a macro
int.tile = CellsTile.Me
int.`!tile` V = CellsTile.Me <= V
int.units = CellsUnits.Me
int.`!units` V = CellsUnits.Me <= V
int.gfx = CellsGfxes.Me
int.`!gfx` V = CellsGfxes.Me <= V
int.block = CellsBlock.Me //unit blocking the tile
int.`!block` V = CellsBlock.Me <= V
int.visited = CellsVisited.Me
int.`!visited` V = CellsVisited.Me <= V
int.xyz = [Me/WorldDepth%WorldSize Me/CellsLineSize Me%WorldDepth]
int.north = Me-CellsLineSize
int.south = Me+CellsLineSize
int.west = Me-WorldDepth
int.east = Me+WorldDepth
int.neibs = [Me-CellsLineSize Me+CellsLineSize Me-WorldDepth Me+WorldDepth]
int.fix_z =
| Cell = Me
| till Cell.tile.empty: !Cell+1
| !Cell-1
| while Cell.tile.empty: !Cell-1
| !Cell+1
| Cell


type world{main}
   w //width
   h //height
   d //depth
   c //cell dimension unit
   maxSize //max size
   filename/`default`
   name/`default map`
   description/`describe the map here`
   heighmap
   owners // unit owners
   units
   free_units
   effects
   free_effects
   active // active units
   players
   human // human controlled player
   seed
   tid_map/Main.tid_map
   void
   shadow
   cycle // counts calls to world.update
   serial
   nil // null unit with id >< 0
   vars/t{} // variables
   marks/[]
   params/(t)
   events
   view //viewport, attached rendering this world
   act
   act_unit/[0 0]
   notes
   editor/0 //world is in editor mode
   paused/0
   sound_cycles/(t) //used to avoid playing similar sounds at once
   blink/[0 0]
   minimap/0
   visited/#FFFFFF
| $init

world.init =
| $main.world <= Me
| $minimap <= gfx 128 128
| WParam = $main.params.world
| $d <= WParam.depth
| WorldDepth <= $d
| $maxSize <= WParam.max_size+12 //FIXME: get rid of this 12 margin
| WorldSize <= $maxSize
| CellsLineSize <= WorldSize*WorldDepth
| MaxUnits <= WParam.max_units
| NoteSize = WParam.note_size
| NoteLife <= WParam.note_life
| $notes <= dup WParam.max_notes
  | [0.0 (dup NoteSize ``)]
| $players <= map Id WParam.max_players: player Id Me
| $c <= WParam.cell_size
| init_unit_module $c
| $void <= $main.tiles.void
| NCells = $maxSize*$maxSize*$d
| Void = $void
| CellsTile <= dup NCells Void
| CellsUnits <= dup NCells []
| CellsGfxes <= dup NCells 0
| CellsBlock <= dup NCells 0
| CellsVisited <= dup NCells #FFFFFFFFFFFF
| $heighmap <= dup $maxSize: @bytes $maxSize
| $units <= MaxUnits{(unit ? Me)}
| $free_units <= stack $units.flip
| $effects <= (MaxUnits*2){N=>(efx)}
| $free_effects <= stack $effects
| $active <= stack MaxActiveUnits
| $shadow <= $main.sprites.system_shadow.frames
| SS = $maxSize*$maxSize
| MaxSize = $maxSize
| $seed <= MaxSize{_=>MaxSize{_=>SS.rand}}
| $nil <= $players.0.alloc_unit{unit_nil}
| $main.params.unit_setters_ <=
  | ($nil)^methods_.keep{?0.0 >< '!'}{[?0.tail ?1]}.table

world.new_visit =
| !$visited - 1
| less $visited:
  | CellsVisited.clear{#FFFFFFFFFFFF}
  | $visited <= #FFFFFF
| $visited*#1000000

world.create W H =
| $w <= W
| $h <= H
| !$w+1
| !$h+1
| $clear
| Filler = [$main.tiles.soil]
| for Y $h: for X $w: $set_pilar{X Y Filler}
| !$w-1
| !$h-1
| $create_borders
| !$w+1
| !$h+1
| for Y $h: when Y: for X $w: when X: $updPilarGfxes{X Y}
| !$w-1
| !$h-1

calc_height Me X Y =
| Low = $cell{X Y -1}
| Cell = Low + $d
| while Low < Cell:
  | when CellsTile.Cell.id: leave Cell-Low
  | !Cell-1
| 0

// add movement blocking walls
world.create_borders = // draws maps borders in clockwise order
| H = $d-1
| Border = $main.tiles.border_
| Pilar = dup H Border
| create_border_pilar X Y =
  | $set_pilar{X Y Pilar}
  | $heighmap.X.Y <= H 
| for X,Y points{0    0    $w+1 1   }: create_border_pilar X Y
| for X,Y points{$w+1 0    1    $h+1}: create_border_pilar X Y
| for X,Y points{1    $h+1 $w+1 1   }: create_border_pilar X Y
| for X,Y points{0    1    1    $h+1}: create_border_pilar X Y

world.clear =
| $paused <= 1
| $minimap.clear{#000000}
| $act <= 0
| for U $units: less U.removed: U.free
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

world.cell X Y Z = (Y*$maxSize+X)*$d+Z
world.at X Y Z = $cell{X Y Z}.tile
world.get XYZ = $cell{XYZ.0 XYZ.1 XYZ.2}.tile
world.set_ X Y Z V = CellsTile.($cell{X Y Z}) <= V

world.pilar X Y =
| H = $height{X Y}
| Cell = $cell{X Y 0}
| map Z H: (Cell+Z).tile

world.set_pilar X Y Ts =
| Cell = $cell{X Y 0}
| for T Ts:
  | CellsTile.Cell <= T
  | !Cell + 1
| Void = $void
| times I $d-Ts.size
  | CellsTile.Cell <= Void
  | !Cell + 1

world.clear_tile_ X Y Z =
| Filler = $void
| Tile = $cell{X Y Z}.tile
| when Tile.parts.is_int
  | !Z-Tile.parts
  | Tile <= $cell{X Y Z}.tile
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
    | when $at{XX YY Z+1}.around><TT:
      | when Dirs.all{DX,DY=>$at{XX+DX YY+DY Z}.type<>TT}
        | $clear_tile{XX YY Z+1}


world.clear_tile X Y Z =
| $clear_tile_{X Y Z}
| $upd_column{X Y}

world.respawn_tile XYZ Type Delay =
| S = $players.0.alloc_unit{unit_dummy}
| S.move{XYZ}
| S.add_effect{retile Delay [[effect [on timeout] [retile [XYZ Type]]]]}

world.excavate X Y Z PassageH Amount =
| Work = $units_get{X,Y,Z}.find{?type><unit_work}
| when no Work:
  | Work <= $players.0.alloc_unit{unit_work}
  | Work.move{X,Y,Z}
  | Work.hp <= 0
| !Work.hp+Amount
| Tile = $at{X Y Z}
| when $at{X Y Z}.unit:
  | B = $block_at{X,Y,Z}
  | less B: leave 1
  | when Work.hp >> B.class.hp:
    | when B.death: Work.effect{B.death Work X,Y,Z}
    | B.free
    | Work.free
    | leave 1
  | when B.hit: Work.effect{B.hit Work X,Y,Z}
  | leave 0
| when Work.hp < Tile.hp:
  | when Tile.hit: Work.effect{Tile.hit Work X,Y,Z}
  | leave 0
| when Tile.death: Work.effect{Tile.death Work X,Y,Z}
| Work.free
| H = min $fix_z{X,Y,Z} Z+PassageH
| ZZ = Z
| while Z<H:
  | less $at{X Y Z}.excavate: H<=Z
  | !Z+1
| Z <= ZZ
| while Z<H:
  | Type = $at{X Y Z}.type
  | $set{X Y Z $main.tiles.void}
  | !Z+1
| 1

// FIXME: remove overlapping tiles above setted tile
world.dirty_set X Y Z Tile =
| H = Tile.height
| times I H: $clear_tile_{X Y Z+I}
| Ps = Tile.parts
| H = H-1
| times I H: $set_{X Y Z+I Ps.I} // push padding
| $set_{X Y Z+H Tile}

DecoDirs = list
   [[0 0]]
   [[0 0]]
   [[0 0] [-1 -1] [-1 0] [0 -1]]
   [[-1 1] [-1 0] [-1 -1]
    [ 0 1] [ 0 0] [ 0 -1]
    [ 1 1] [ 1 0] [ 1 -1]]
   [[0 0]]
   [[ 0 1] [ 0 0] [ 0 -1]
    [ 1 1] [ 1 0] [ 1 -1]
    [ 2 1] [ 2 0] [ 2 -1]]

linked_tiles2dS Me Cost X Y Check =
| Cell = $cell{X Y 0}
| when Cell.visited><Cost: leave []
| Cell.visited <= Cost
| less Check X Y: leave []
| Rs = [[X Y]]
| for DX,DY Dirs4: for R linked_tiles2dS{Me Cost X+DX Y+DY Check}: push R Rs
| Rs

linked_tiles2d Me X Y Check =
| linked_tiles2dS Me $new_visit X Y Check

points_rect Ps =
| X = Ps{?0}.min
| Y = Ps{?1}.min
| [X Y Ps{?0}.max+1-X Ps{?1}.max+1-Y]

update_deco Me Tile Z Ps =
| Type = Tile.type
| ZH = Z+Tile.height
| DSize,OX,OY,Params,DecoType = Tile.deco
| Single = 0
| when Params: for P Params: case P
  single | Single <= 1
| MX,MY,W,H = points_rect Ps
| XYs = points{MX MY W H}
| for X,Y XYs:
  | D = $units_get{X,Y,ZH}.find{?type><DecoType}
  | when got D: D.free
| Ds = if DSize.is_list then DSize else DecoDirs.DSize
| Y = MY + OY.0
| EY = Y + H-OY.1
| while Y < EY:
  | X = MX + OX.0
  | EX = X + W-OX.1
  | while X < EX:
    | when Ds.all{DX,DY => $at{X+DX Y+DY Z}.type><Type}
      | Deco = $players.0.alloc_unit{DecoType}
      | Deco.move{X,Y,ZH}
      //| Deco.fxyz.init{Deco.fxyz-[FOff.0 FOff.1 0]}
    | !X + OX.2
  | !Y + OY.2

world.set X Y Z Tile =
| Removed = $at{X Y Z}
| DecoTs = 0
| when Removed.deco and Removed.type<>Tile.type:
  | DecoTs <= linked_tiles2d Me X Y: X Y => $at{X Y Z}.type><Removed.type
| $dirty_set{X Y Z Tile}
| when DecoTs: update_deco Me Removed Z DecoTs
| when Tile.deco:
  | DecoTs <= linked_tiles2d Me X Y: X Y => $at{X Y Z}.type><Tile.type
  | update_deco Me Tile Z DecoTs
| $upd_column{X Y}

world.fix_z XYZ = $cell{XYZ.0 XYZ.1 XYZ.2}.fix_z%WorldDepth

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
| PX = AX //prev X
| PY = AY
| when DZ.abs>4: leave 0 //z-difference is too large
  //Z+1 is required, because actual units are above the ground
| line_calls3d AX AY AZ+1 BX BY BZ+1: X Y Z =>
  | R = 0
  | DX = X-PX
  | DY = Y-PY
  | when DX*DX><1 and DY*DY><1:
    | less $at{PX+DX PY Z}.empty or $at{PX PY+DY Z}.empty: _goto end
  | PX <= X
  | PY <= Y
  | R <= $at{X Y Z}.empty
  | _label end
  | R

world.fxyz XYZ =
| CellSize = $c
| [XYZ.0*CellSize XYZ.1*CellSize XYZ.2*CellSize]

world.units_get X,Y,Z = $cell{X Y Z}.units.unheap

world.column_units_get X Y = $cell{X Y 0}.units.unheap

world.block_at XYZ = $cell{XYZ.0 XYZ.1 XYZ.2}.block

world.no_block_at XYZ = not $cell{XYZ.0 XYZ.1 XYZ.2}.block

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

world.place_unitS U =
| X,Y,Z = U.xyz
| Cell = $cell{X Y 0}
| Cell.units <= Cell.units.cons{U}
| !Cell+Z
| Cell.units <= Cell.units.cons{U}
| less U.empty: Cell.block <= U

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
| X,Y,Z = U.xyz
| Cell = $cell{X Y 0}
| K = Cell.units
| Cell.units <= K.unheap.skip{?id><U.id}.enheap
| K.heapfree
| !Cell+Z
| K = Cell.units
| Us = K.unheap.skip{?id><U.id}
| Cell.units <= Us.enheap
| K.heapfree
| less U.empty:
  | Cell.block <= 0
  | for U Us: less U.empty: Cell.block <= U

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
    | for U $column_units_get{X Y}: when $seen_from{Center U.xyz}:
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
| when Z<0: Z <= 0
| Cell = $cell{X Y 0}
| while Z > 0 and not (Cell+Z).gfx: !Z-1
| G = (Cell+Z).gfx
| less G: leave 0
| G.get{G.w/2 (min G.h/2 16)} ^^ #FFFFFF

world.update_minimap X Y =
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
| $heighmap.X.Y <= calc_height Me X Y
| Seed = $seed.Y.X
| Z = 0
| H = $height{X Y}
| Cell = $cell{X Y 0}
| Below = $tid_map.0
| T = Cell.tile
| while Z < H:
  | TH = T.height
  | Next = Cell+TH
  | Above = Next.tile
  | when Above.parts.is_int: //multi-height tile
    | Above <= (Next-Above.parts).tile
  // TH-1 is a hack to exclude short tiles from tiling with tall-tiles
  | Cell.gfx <= T.render{X Y Z+TH-1 Below Above Seed}
  | Below <= T
  | T <= Above
  | Cell <= Next
  | !Z+TH
| for U $column_units_get{X Y}: U.environment_updated
| $update_minimap{X Y}

world.upd_column X Y =
| $heighmap.X.Y <= calc_height Me X Y
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

world.new_effect When Name Amount Params =
| E = $free_effects.pop
| E.when <= When
| E.name <= Name
| E.amount <= Amount
| E.params <= Params.enheap
| E

world.free_effect E =
| E.params.heapfree
| $free_effects.push{E}

export world
