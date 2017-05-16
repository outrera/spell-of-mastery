use enheap gfx stack heap util line_points unit player

MaxUnits = No
MaxActiveUnits = 4096
NoteLife = 1.0

type efx when name amount params

CellsTile =
CellsUnits = //units residing in the cell
CellsGfxes = //sprite used to draw cell on screen
CellsBlock = //blocking unit residing in cell
CellsCost =  //movement cost to reach this cell
CellsPrev =
CellsFloor =
WorldSize = 1 //max world size
WorldDepth = 1
CellsLineSize = 1
World =

//FIXME: such structs could be defined with a macro
int.tile = CellsTile.Me
int.`=tile` V = CellsTile.Me <= V
int.empty = $tile.empty
int.type = $tile.type
int.units = CellsUnits.Me
int.`=units` V = CellsUnits.Me <= V
int.gfx = CellsGfxes.Me
int.`=gfx` V = CellsGfxes.Me <= V
int.block = CellsBlock.Me //unit blocking the tile
int.`=block` V = CellsBlock.Me <= V
int.cost = CellsCost.Me
int.`=cost` V = CellsCost.Me <= V
int.prev = CellsPrev.Me
int.`=prev` V = CellsPrev.Me <= V
int.floor = CellsFloor.Me
int.`=floor` V = CellsFloor.Me <= V
int.xyz = [Me/WorldDepth%WorldSize Me/CellsLineSize Me%WorldDepth]
int.z = Me%WorldDepth
int.north = Me-CellsLineSize
int.south = Me+CellsLineSize
int.west = Me-WorldDepth
int.east = Me+WorldDepth
int.neibs = [Me-CellsLineSize Me+CellsLineSize Me-WorldDepth Me+WorldDepth]
int.path =
| Cell = Me
| Path = []
| while Cell
  | push Cell Path
  | Cell <= Cell.prev
| Path.tail.list
list.cell = (Me.1*WorldSize+Me.0)*WorldDepth+Me.2
int.pile =
| R = $units.find{?ai><pile}
| if got R then R else 0
int.items =
| Pile = $pile
| if Pile then Pile.items else []
int.get_item Name =
| Pile = $pile
| if Pile then Pile.get_item{Name} else 0
unit.update_pile =
| Items = $items
| when Items.end:
  | $free
  | leave
| if Items.tail.end then
  | Item = Items.0
  | Cl = World.main.classes.(Item.0)
  | $sprite <= Cl.default_sprite
  else
  | $sprite <= $default_sprite
| $animate{idle}
int.add_item Name Amount =
| Pile = $pile
| less Pile:
  | Pile <= World.players.0.alloc_unit{item_pile}
  | Pile.move{$xyz}
| Pile.add_item{Name Amount}
| Pile.update_pile

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
   actors/heapval{[]} // currently acting unit
   players
   human // human controlled player
   tid_map/Main.tid_map
   void
   shadow
   cycle // counts calls to world.update
   turn // current turn
   player //turn player
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
   cost/#FFFFFF //cost for pathfinder
   variation //used to randomize tiles and make them less repetitive
   seed //PRNG running value
| $init

LCG_M = 2147483647
LCG_M_F = LCG_M.float
LCG_A = 16807
LCG_B = 0

world.rand Size =
| $seed <= ($seed*LCG_A + LCG_B) % LCG_M
| @int: @round: $seed.float*Size.float/LCG_M_F

world.init =
| $main.world <= Me
| World <= Me
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
| CellsCost <= dup NCells #FFFFFFFFFFFF
| CellsPrev <= dup NCells 0
| CellsFloor <= dup NCells 0
| $heighmap <= dup $maxSize: @bytes $maxSize
| $units <= MaxUnits{(unit ? Me)}
| $free_units <= stack $units.flip
| $effects <= (MaxUnits*2){N=>(efx)}
| $free_effects <= stack $effects
| $active <= stack MaxActiveUnits
| $shadow <= $main.sprites.system_shadow.frames
| SS = $maxSize*$maxSize
| MaxSize = $maxSize
| $variation <= MaxSize{_=>MaxSize{_=>SS.rand}}
| $nil <= $players.0.alloc_unit{unit_nil}
| $main.params.unit_setters_ <=
  | ($nil)^methods_.keep{?0.0 >< '='}{[?0.tail ?1]}.table

world.new_cost =
| $cost--
| less $cost:
  | CellsCost.clear{#FFFFFFFFFFFF}
  | $cost <= #FFFFFF
| $cost*#1000000

world.create W H =
| $w <= W
| $h <= H
| $w++
| $h++
| $clear
| Filler = [$main.tiles.soil]
| for Y $h: for X $w: $set_pilar{X Y Filler}
| $w--
| $h--
| $create_borders
| $w++
| $h++
| for Y $h: when Y: for X $w: when X: $updPilarGfxes{X Y}
| $w--
| $h--

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
| $seed <= LCG_M.rand
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

// force reset of all unit effects and health
reinit_units Us =
| InitedUnits = []
| for U Us: less U.removed
  | Type = U.type
  | Owner = U.owner
  | Facing = U.facing
  | XYZ = U.xyz.deep_copy
  | FXYZ = U.fxyz.deep_copy
  | Items = U.items
  | when U.leader: U.hp <= U.class.hp
  | U.free
  | less U.ordered.type><die:
    | U = Owner.alloc_unit{Type}
    | U.move{XYZ}
    | U.pick_facing{Facing}
    | U.fxyz.init{FXYZ}
    | when Items: for Item,Amount Items: U.add_item{Item Amount}
    | push U InitedUnits
| InitedUnits

handle_attack_triggers Us =
| for U Us
  | Os = U.world.units_get{U.xyz}
  | AttackTrigger = Os.find{?ai><attack}
  | if got AttackTrigger and U.ai<>attack
    then | U.aistate <= \attack
         | AttackTrigger.free
    else | U.aistate <= \guard

world.new_game =
| $actors.set{[]}
| $seed <= LCG_M.rand
| for K,V $main.params.world: $params.K <= V
| for ActName,Act $main.params.acts: Act.enabled <= #FFFFFF
| $human <= $players.1
| $human.human <= 1
| $cycle <= 0
| $turn <= 0
| $player <= 0
| if $params.explored then $explore{1} else $explore{0}
| ActNames = $main.params.acts{}{?0}
| StartMana = $main.params.world.start_mana
| StartLore = $main.params.world.start_lore
| InitedUnits = reinit_units $active
| PAI = $main.params.ai
| for P $players:
  | P.init{StartMana StartLore}
  | Us = P.units
  | less P.human: when Us.size:
    | for ActName ActNames: P.research_item{ActName}
  | L = P.leader
  | C = P.pentagram
  | when L and not C:
    | C = P.alloc_unit{L.class.pentagram}
    | C.move{L.xyz}
    | L.move{C.xyz}
    | L.alpha <= 255
    | L.delta <= -50
    | $effect{C.xyz teleport}
    | C.alpha <= 255
    | C.delta <= -10
    | $effect{C.xyz pentagram_appearance}
  | when L and got PAI.(L.type): P.params.aiType <= L.type //got specialized AI
| when got@@it $players.find{?human}: $human <= it
| handle_attack_triggers InitedUnits
| $end_turn

world.notify Text =
| Clock = clock
| Used = $notes.keep{?0 > Clock}
| Free = $notes.skip{?0 > Clock}
| less Free.size: push Used^pop Free
| N = Free.0
| N.0 <= Clock + NoteLife
| Chars = N.1
| Chars.clear{``}
| for I min{Chars.size Text.size}: Chars.I <= Text.I
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
world.`=picked` Us = $player.picked <= Us

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
| for T Ts: CellsTile.(Cell++) <= T
| Void = $void
| times I $d-Ts.size: CellsTile.(Cell++) <= Void

world.clear_tile_ X Y Z =
| Filler = $void
| Tile = $cell{X Y Z}.tile
| when Tile.parts.is_int
  | Z -= Tile.parts
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
| $upd_neibs{X Y}

world.respawn_tile XYZ Type Delay =
| S = $players.0.alloc_unit{unit_dummy}
| S.move{XYZ}
| S.add_effect{retile Delay [[effect [on timeout] [retile [XYZ Type]]]]}

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

linked_cells2dS Cell Cost Check =
| when Cell.cost><Cost: leave []
| Cell.cost <= Cost
| less Check Cell: leave []
| Rs = [Cell]
| for N Cell.neibs: for R linked_cells2dS{N Cost Check}: push R Rs
| Rs

world.linked_cells2d Cell Check = linked_cells2dS{Cell $new_cost Check}

points_rect Ps =
| X = Ps{?0}.min
| Y = Ps{?1}.min
| [X Y Ps{?0}.max+1-X Ps{?1}.max+1-Y]

update_deco Me Owner Tile Z Ps = //Me=world
| Type = Tile.type
| ZH = Z+Tile.height
| DSize,OX,OY,Params,DecoType = Tile.deco
| Single = 0
| when Params: for P Params: case P
  single | Single <= 1
| MX,MY,W,H = points_rect Ps{?xyz}
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
      | Deco = (Owner or $players.0).alloc_unit{DecoType}
      | Deco.move{X,Y,ZH}
      //| Deco.fxyz.init{Deco.fxyz-[FOff.0 FOff.1 0]}
    | X += OX.2
  | Y += OY.2

world.set X Y Z Tile owner/0 =
| Cell = $cell{X Y Z}
| Removed = Cell.tile
| DecoTs = 0
| when Removed.deco and Removed.type<>Tile.type:
  | DecoTs <= $linked_cells2d{Cell | Cell => Cell.tile.type><Removed.type}
| $dirty_set{X Y Z Tile}
| when DecoTs: update_deco Me Owner Removed Z DecoTs
| when Tile.deco:
  | DecoTs <= $linked_cells2d{Cell | Cell => Cell.tile.type><Tile.type}
  | update_deco Me Owner Tile Z DecoTs
| $upd_neibs{X Y}

world.floor XYZ = $cell{XYZ.0 XYZ.1 XYZ.2}.floor%WorldDepth

world.floor_void XYZ =
| X,Y,Z = XYZ
| while $at{X Y Z}.id: Z++
| Z--
| till $at{X Y Z}.id: Z--
| Z+1

world.roof XYZ =
| X,Y,Z = XYZ
| while $at{X Y Z}.empty and Z < $d-1: Z++
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
  | E.X += V

world.explore State = for P $players: P.explore{State}

world.place_unitS U X Y Z =
| Cell = $cell{X Y 0}
| Cell.units <= Cell.units.cons{U}
| Cell += Z
| Cell.units <= Cell.units.cons{U}
| less U.empty: Cell.block <= U

world.place_unit U =
| XYZ = U.xyz
| Mirror = U.facing >< 5
| Blocker = U.passable and U.block
| for DX,DY,DZ U.form:
  | XX,YY,ZZ = XYZ + if Mirror then [-DY DX DZ] else [DX -DY DZ]
  | $place_unitS{U XX YY ZZ}
  | when Blocker: $set{XX YY ZZ U.block}
| U.cell <= $cell{XYZ.0 XYZ.1 XYZ.2}
| U.explore{1}

world.remove_unitS U X Y Z =
| U.explore{-1}
| Cell = $cell{X Y 0}
| K = Cell.units
| Cell.units <= K.unheap.skip{?id><U.id}.enheap
| K.heapfree
| Cell += Z
| K = Cell.units
| Us = K.unheap.skip{?id><U.id}
| Cell.units <= Us.enheap
| K.heapfree
| less U.empty:
  | Cell.block <= 0
  | for U Us: less U.empty: Cell.block <= U

world.remove_unit U =
| when U.removed: leave
| XYZ = U.xyz.copy
| Mirror = U.facing >< 5
| Blocker = U.passable and U.block
| for XX,YY,ZZ U.form:
  | XX,YY,ZZ = XYZ + if Mirror then [-YY XX ZZ] else [XX -YY ZZ]
  | $remove_unitS{U XX YY ZZ}
  | when Blocker: $clear_tile{XX YY ZZ}
| U.cell <= 0
| U.xyz.init{XYZ}

world.effect XYZ What =
| E = $players.0.alloc_unit{"effect_[What]"}
| E.move{XYZ}
| E.die
| E

world.units_in_range Center R =
| Units = []
| for X,Y points_in_diamond{R}
  | XYZ = Center+[X Y 0]
  | X = XYZ.0
  | Y = XYZ.1
  | when X>0 and X<<$w and Y>0 and Y<<$h:
    | for U $column_units_get{X Y}: when $seen_from{Center U.xyz}:
      | when (U.xyz.2-XYZ.2).abs<R*2:
        | push U Units
| Units

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
| while Z > 0 and not (Cell+Z).gfx: Z--
| G = (Cell+Z).gfx
| less G: leave 0
| G.get{G.w/2 (min G.h/2 16)} &&& #FFFFFF

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

upd_floor Me Bottom =
| Cell = Bottom
| Floor = Cell
| LastEmpty = 0
| times I $d:
  | Empty = Cell.tile.empty
  | when Empty
    | less LastEmpty: Floor <= Cell
    | Cell.floor <= Floor
  | Cell++
  | LastEmpty <= Empty
| Cell = Bottom+$d-1
| Floor = Cell
| LastEmpty = 0
| times I $d:
  | Empty = Cell.tile.empty
  | less Empty
    | when LastEmpty: Floor <= Cell+1
    | Cell.floor <= Floor
  | Cell--
  | LastEmpty <= Empty

world.updPilarGfxes X Y =
| when X < 0 or Y < 0: leave 0
| Cell = $cell{X Y 0}
| upd_floor Me Cell
| $heighmap.X.Y <= (Cell+$d-2).floor.z
| Var = $variation.Y.X
| Z = 0
| H = $height{X Y}
| Below = $tid_map.0
| T = Cell.tile
| while Z < H:
  | TH = T.height
  | Next = Cell+TH
  | Above = Next.tile
  | when Above.parts.is_int: //multi-height tile
    | Above <= (Next-Above.parts).tile
  // TH-1 is a hack to exclude short tiles from tiling with tall-tiles
  | Cell.gfx <= T.render{X Y Z+TH-1 Below Above Var}
  | Below <= T
  | T <= Above
  | Cell <= Next
  | Z += TH
| for U $column_units_get{X Y}: U.environment_updated
| $update_minimap{X Y}

world.upd_neibs X Y =
| for DX,DY Dirs: $updPilarGfxes{X+DX Y+DY}
| $updPilarGfxes{X Y}

world.height X Y = $heighmap.X.Y

world.outdoor XYZ = $height{XYZ.0 XYZ.1} << XYZ.2

world.up XYZ = //finds Z of the floor above
| X,Y,Z = XYZ
| H = $height{X Y}
| when Z>>H: leave 0
| while Z<H and $at{X Y Z}.empty: Z++
| till Z>>H or $at{X Y Z}.empty: Z++
| Z

world.down XYZ = //finds Z of the floor below
| X,Y,Z = XYZ
| B = 1
| till $at{X Y B}.empty: B++
| when Z<<B: leave 0
| while Z>B and $at{X Y Z}.empty: Z--
| till Z<<B or $at{X Y Z}.empty: Z--
| while Z>B and $at{X Y Z-1}.empty: Z--
| Z

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
| $upd_neibs{X Y}

world.pop_ X,Y =
| H = $height{X Y}
| less H: leave
| Z = H-1
| T = $at{X Y Z}
| times I T.height: $set_{X Y Z-I $void}

// pop top tile of pilar at X,Y
world.pop XY =
| $pop_{XY}
| $upd_neibs{XY.0 XY.1}

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
