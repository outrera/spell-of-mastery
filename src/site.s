use enheap gfx stack heap util line_points unit player fxn

type efx when name amount data

CellsTile =
CellsUnits = //units residing in the cell
CellsGfxes = //sprite used to draw cell on screen
CellsBlock = //blocking unit residing in cell
CellsCost =  //movement cost to reach this cell
CellsPrev =
CellsFloor =
CellsGate =
CellsBlitem =
SiteSize = 1 //max site size
SiteDepth = 1
CellsLineSize = 1
Site =

//FIXME: such structs could be defined with a macro
int.tile = fxn CellsTile.Me
int.`=tile` V = fxn: CellsTile.Me <= V
int.empty = $tile.empty
int.invisible = $tile.invisible
int.type = $tile.type
int.units = fxn CellsUnits.Me
int.`=units` V = fxn: CellsUnits.Me <= V
int.gfx = fxn CellsGfxes.Me
int.`=gfx` V = fxn: CellsGfxes.Me <= V
int.blitem = fxn CellsBlitem.Me
int.`=blitem` V = fxn: CellsBlitem.Me <= V
int.block = fxn CellsBlock.Me //unit blocking the tile
int.`=block` V = fxn: CellsBlock.Me <= V
int.vacant = $empty and not $block
int.cost = CellsCost.Me
int.`=cost` V = CellsCost.Me <= V
int.prev = CellsPrev.Me
int.`=prev` V = CellsPrev.Me <= V
//for empty cell, floor returns corresponding ground cell bellow them
//for non-empty cell, floor returns ground cell above them
int.floor = fxn CellsFloor.Me
int.`=floor` V = fxn: CellsFloor.Me <= V
int.gate = CellsGate.Me
int.`=gate` V = CellsGate.Me <= V
int.xyz = fxn [Me/SiteDepth%SiteSize Me/CellsLineSize Me%SiteDepth]
int.z = fxn Me%SiteDepth
int.north = fxn Me-CellsLineSize
int.south = fxn Me+CellsLineSize
int.west = fxn Me-SiteDepth
int.east = fxn Me+SiteDepth
int.neibs = fxn [Me-CellsLineSize Me+CellsLineSize Me-SiteDepth Me+SiteDepth]
int.climbable = $neibs.any{?empty^not}
int.path =
| Cell = Me
| Path = []
| while Cell
  | push Cell Path
  | Cell <= Cell.prev
| Path.tail.list
int.is_floor_empty = $units.all{U=>U.ai<>pentagram and U.type<>special_node}
list.cell = (Me.1*SiteSize+Me.0)*SiteDepth+Me.2
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
  | Cl = Site.main.classes.(Item.0)
  | $sprite <= Cl.default_sprite
  else
  | $sprite <= $default_sprite
| $animate{idle}
int.add_item Name Amount =
| Pile = $pile
| less Pile:
  | Pile <= Site.players.0.alloc_unit{item_pile}
  | Pile.move{$xyz}
| Pile.add_item{Name Amount}
| Pile.update_pile

type site{main}
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
   genes
   free_genes
   active //active units, which are processed each cycle
   actors/heapval{[]} // currently acting unit
   players
   human // human controlled player
   void
   shadow
   cycle // counts calls to site.update
   turn // current turn
   player //turn player
   serial
   nil // null unit with id >< 0
   vars/t{} // variables
   marks
   free_marks
   last_picked
   cfg
   data/(t)
   events
   view //viewport, attached rendering this site
   act
   act_unit/[0 0]
   editor/0 //site is in editor mode
   paused/0
   sound_cycles/(t) //used to avoid playing similar sounds at once
   blink/[0 0]
   minimap/0
   cost/#FFFFFF //cost for pathfinder
   variation //used to randomize tiles and make them less repetitive
   seed //PRNG running value
   shake_start
   shake_end
   color_overlay
   color_overlay_step
| $init

LCG_M = 2147483647
LCG_M_F = LCG_M.float
LCG_A = 16807
LCG_B = 0

site.rand Size =
| $seed <= ($seed*LCG_A + LCG_B) % LCG_M
| @int: @round: $seed.float*Size.float/LCG_M_F

setters_ O = O^methods_.keep{?0.0 >< '='}{[?0.tail ?1]}.table
getters_ O =
| Setters = setters_ O
| O^methods_.keep{K,V => got Setters.K}.table

site.init =
| $main.site <= Me
| Site <= Me
| $minimap <= gfx 128 128
| $cfg <= $main.cfg.site
| $d <= $cfg.depth
| SiteDepth <= $d
| $maxSize <= $cfg.max_size+12 //FIXME: get rid of this 12 margin
| SiteSize <= $maxSize
| CellsLineSize <= SiteSize*SiteDepth
| $players <= map Id $cfg.max_players: player Id Me
| $c <= $cfg.cell_size
| init_unit_module $c
| $void <= $main.tiles.void
| $ncells = $maxSize*$maxSize*$d
| Void = $void
| CellsTile <= dup $ncells Void
| CellsUnits <= dup $ncells []
| CellsGfxes <= dup $ncells 0
| CellsBlock <= dup $ncells 0
| CellsCost <= dup $ncells #FFFFFFFFFFFF
| CellsPrev <= dup $ncells 0
| CellsFloor <= dup $ncells 0
| CellsGate <= dup $ncells 0
| CellsBlitem <= dup $ncells 0
| $heighmap <= dup $maxSize: @bytes $maxSize
| MaxUnits = $cfg.max_units
| $units <= MaxUnits{(unit ? Me)}
| $free_units <= stack $units.flip
| $genes <= (MaxUnits*2){N=>(efx)}
| $free_genes <= stack $genes
| MaxActiveUnits = 4096
| $active <= stack MaxActiveUnits
| $marks <= stack 1024
| $free_marks <= stack 1024
| $shadow <= $main.sprites.system_shadow
| SS = $maxSize*$maxSize
| MaxSize = $maxSize
| $variation <= MaxSize{_=>MaxSize{_=>SS.rand}}
| $nil <= $players.0.alloc_unit{unit_nil}
| $main.cfg.unit_getters_ <= getters_ $nil
| $main.cfg.unit_setters_ <= setters_ $nil

site.new_cost =
| $cost--
| less $cost:
  | CellsCost.clear{#FFFFFFFFFFFF}
  | $cost <= #FFFFFF
| $cost*#1000000

site.create W H D Filler =
| $w <= W
| $h <= H
| $w++
| $h++
| $clear
| FillerTile = $main.tiles.Filler
| FillerColumn = dup D FillerTile
| times Y $h: times X $w: $set_pilar{X Y FillerColumn}
| $w--
| $h--
| $create_borders
| times Y $h+1: when Y: times X $w+1: when X: $upd_pilar{X Y}
| $paused <= 1

// add movement blocking walls
site.create_borders = // draws maps borders in clockwise order
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

site.clear =
| $paused <= 1
| $seed <= LCG_M.rand
| $minimap.clear{#000000}
| $act <= 0
| for U $units: less U.removed: U.free
| for H $heighmap: H.clear{0}
| for P $players: P.clear
| $human <= $players.1
| $human.human <= 1
| $marks.clear
| $free_marks.clear
| $last_picked <= 0
| for K,V $data: $data.K <= No
| for U $active.list: U.active <= 0
| $active.clear
| for [K V] $sound_cycles: $sound_cycles.K <= 0
| $blink.init{[0 0]}
| $shake_start <= 0
| $shake_end <= 0
| $color_overlay <= []
| $color_overlay_step <= 0

// force reset of all unit genes and health
reinit_units Us =
| InitedUnits = []
| XYZ = [0 0 0]
| FXYZ = [0 0 0]
| for U Us: less U.removed
  | Type = U.type
  | Owner = U.owner
  | Facing = U.facing
  | XYZ.init{U.xyz}
  | FXYZ.init{U.fxyz}
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
  | Os = U.site.units_get{U.xyz}
  | AttackTrigger = Os.find{?ai><attack}
  | if got AttackTrigger and U.ai<>attack
    then | U.aistate <= \roam
         | AttackTrigger.free
    else | U.aistate <= \guard

site.new_game =
| $actors.set{[]}
| $seed <= LCG_M.rand
| SCfg = $main.cfg.site
| for K,V SCfg: $data.K <= V
| for ActName,Act $main.acts: Act.players <= #FFFFFF
| $human <= $players.1
| $human.human <= 1
| $cycle <= 0
| $turn <= 0
| $player <= 0
| if SCfg.explored then $explore{1} else $explore{0}
| ActNames = $main.acts{}{?0}
| StartMana = $main.cfg.site.start_mana
| StartLore = $main.cfg.site.start_lore
| InitedUnits = reinit_units $active
| PAI = $main.cfg.ai
| for P $players:
  | P.init{StartMana StartLore}
  | Us = P.units
  | less P.human: when Us.size:
    | for ActName ActNames: P.research_item{ActName}
  | L = P.leader
  | less L.removed:
    | L.alpha <= 255
    | L.delta <= -50
    | $visual{L.xyz teleport}
    | C = P.pentagram
    | less C.removed:
      | XYZ = C.xyz.copy
      | C.free
      | C = P.alloc_unit{special_pentagram}
      | C.move{XYZ}
  | when got PAI.(L.type): P.data.aiType <= L.type //got specialized AI
| when got@@it $players.find{?human}: $human <= it
| handle_attack_triggers InitedUnits
| $end_turn
| $paused <= 0

site.notify Text = $main.ui.notify{Text}

site.alloc_unit ClassName Owner =
| Class = $main.classes.ClassName
| when no Class:
  | $notify{"Missing class `[ClassName]`"}
  | when ClassName><unit_nil:
    | say 'site.alloc_unit: unit_nil is missing!'
    | halt //something is really wrong
  | Class <= $main.classes.trigger_missing
| U = $free_units.pop
| when Class.ai >< pentagram
  | Pentagram = Owner.pentagram
  | less Pentagram.removed:
    | $free_units.push{U}
    | leave Pentagram
  | Owner.pentagram <= U
| till U.removed: U <= $free_units.pop
| U.init{Class}
| when U.leader:
  | Owner.leader.free
  | Owner.leader <= U
| U.owner <= Owner
| U.colors <= Owner.colors
| U.owner.got_unit{U}
| U

player.alloc_unit ClassName = $site.alloc_unit{ClassName Me}


site.free_unit U =
| when U.id
  | U.remove
  | $free_units.push{U}

site.picked = $player.picked
site.`=picked` Us = $player.picked <= Us


site.valid X Y Z =
| fxn: X >> 0 and Y >> 0 and Z >> 0 and X << $w and Y << $h and Z < $d
site.cell X Y Z = fxn (Y*$maxSize+X)*$d+Z
site.cellp P =
| P <= P.list
| fxn (P.1*$maxSize+P.0)*$d+P.2
site.at X Y Z = $cell{X Y Z}.tile
site.get XYZ = $cell{XYZ.0 XYZ.1 XYZ.2}.tile
site.set_ X Y Z V = CellsTile.($cell{X Y Z}) <= V

site.pilar X Y =
| H = $height{X Y}
| Cell = $cell{X Y 0}
| fxn: map Z H: (Cell+Z).tile

site.set_pilar X Y Ts =
| Cell = $cell{X Y 0}
| fxn: for T Ts: CellsTile.(Cell++) <= T
| Void = $void
| fxn: times I $d-Ts.size: CellsTile.(Cell++) <= Void

site.clear_tile_ X Y Z =
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


site.clear_tile X Y Z =
| $clear_tile_{X Y Z}
| $upd_neibs{X Y}

// FIXME: remove overlapping tiles above setted tile
site.dirty_set X Y Z Tile =
| H = Tile.height
| times I H: $clear_tile_{X Y Z+I}
| Ps = Tile.parts
| H = H-1
| times I H: $set_{X Y Z+I Ps.I} // push padding
| $set_{X Y Z+H Tile}

site.set X Y Z Tile owner/0 =
| Cell = $cell{X Y Z}
| Removed = Cell.tile
| $dirty_set{X Y Z Tile}
| $upd_neibs{X Y}

site.floor XYZ = $cell{XYZ.0 XYZ.1 XYZ.2}.floor%SiteDepth

site.floor_void XYZ =
| X,Y,Z = XYZ
| while $at{X Y Z}.id: Z++
| Z--
| till $at{X Y Z}.id: Z--
| Z+1

site.roof XYZ =
| X,Y,Z = XYZ
| while $at{X Y Z}.empty and Z < $d-1: Z++
| Z

site.seen_from A B = fxn:
| when A.2 < B.2: swap A B //hack to accomodate for line_calls3d quirks
| AX,AY,AZ = A
| BX,BY,BZ = B
| when [AX AY].mdist{[BX BY]}><1: //units near cliff should see each other
  | Dst = $cell{BX BY BZ}
  | times I AZ-BZ: less (Dst+I).tile.empty: leave 0
  | leave 1
| PX = AX //prev X
| PY = AY
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

site.fxyz XYZ =
| CellSize = $c
| [XYZ.0*CellSize XYZ.1*CellSize XYZ.2*CellSize]

site.units_get X,Y,Z = $cell{X Y Z}.units.unheap

site.column_units_get X Y = $cell{X Y 0}.units.unheap

site.block_at XYZ = $cell{XYZ.0 XYZ.1 XYZ.2}.block

site.block_at_safe XYZ =
| when XYZ.0<1: leave 0
| when XYZ.1<1: leave 0
| when XYZ.2<1: leave 0
| $cell{XYZ.0 XYZ.1 XYZ.2}.block

site.no_block_at XYZ = not $cell{XYZ.0 XYZ.1 XYZ.2}.block

unit.explore V =
| Sight = $sight
| when no Sight: leave
| XYZ = $xyz
| Explored = $owner.sight
| UX = XYZ.0
| UY = XYZ.1
| for X,Y points{UX-Sight UY-Sight Sight*2+1 Sight*2+1}: when fxn (X>>0 and Y>>0):
  | E = Explored.Y
  | less E.X: E.X <= 1
  | E.X += V

site.explore State = for P $players: P.explore{State}

site.place_unitS U X Y Z =
| Cell = $cell{X Y 0}
| Cell.units <= Cell.units.cons{U}
| fxn: Cell += Z
| Cell.units <= Cell.units.cons{U}
| less U.empty: Cell.block <= U

site.place_unit U =
| XYZ = U.xyz
| Blocker = U.passable and U.block
| if U.form then
    | Mirror = U.facing >< 5
    | for DX,DY,DZ U.form:
      | XX,YY,ZZ = XYZ + if Mirror then [-DY DX DZ] else [DX -DY DZ]
      | $place_unitS{U XX YY ZZ}
      | when Blocker: $set{XX YY ZZ U.block}
  else
    | XX,YY,ZZ = XYZ
    | $place_unitS{U XX YY ZZ}
    | when Blocker: $set{XX YY ZZ U.block}
| U.cell <= fxn $cell{XYZ.0 XYZ.1 XYZ.2}
| when U.gate:
  | Target = 0
  | for A $active: when A.gate><U.gate and A.id<>U.id: Target <= A
  | when Target:
    | U.cell.gate <= Target
    | Target.cell.gate <= U
| U.explore{1}

site.remove_unitS U X Y Z = fxn:
| U.explore{-1}
| Cell = $cell{X Y 0}
| K = Cell.units
| Cell.units <= K.unheap.skip{X=>fxn X.id><U.id}.enheap
| K.heapfree
| Cell += Z
| K = Cell.units
| Us = K.unheap.skip{X=>fxn X.id><U.id}
| Cell.units <= Us.enheap
| K.heapfree
| less U.empty:
  | Cell.block <= 0
  | for U Us: less U.empty: Cell.block <= U

site.remove_unit U =
| when U.removed: leave
| XYZ = U.xyz.copy
| Blocker = U.passable and U.block
| if U.form then
    | Mirror = U.facing >< 5
    | for XX,YY,ZZ U.form:
      | XX,YY,ZZ = XYZ + if Mirror then [-YY XX ZZ] else [XX -YY ZZ]
      | $remove_unitS{U XX YY ZZ}
      | when Blocker: $clear_tile{XX YY ZZ}
  else
    | XX,YY,ZZ = XYZ
    | $remove_unitS{U XX YY ZZ}
    | when Blocker: $clear_tile{XX YY ZZ}
| when U.gate: for A $active: when A.gate><U.gate: U.cell.gate <= 0
| U.cell <= 0
| U.xyz.init{XYZ}

site.visual XYZ What =
| E = $players.0.alloc_unit{"effect_[What]"}
| E.move{XYZ}
| E.die
| E

site.new_goal XYZ =
| G = $players.0.alloc_unit{special_goal}
| G.move{XYZ}
| G

site.units_in_range Center R =
| Units = []
| for X,Y points_in_diamond{R}
  | XYZ = Center+[X Y 0]
  | X = XYZ.0
  | Y = XYZ.1
  | when X>0 and X<<$w and Y>0 and Y<<$h:
    | for U $column_units_get{X Y}: when $seen_from{Center U.xyz}: push U Units
| Units

site.neibs X Y Z = fxn:
  [$at{X Y-1 Z} $at{X+1 Y Z} $at{X Y+1 Z} $at{X-1 Y Z}
   $at{X+1 Y-1 Z} $at{X+1 Y+1 Z} $at{X-1 Y+1 Z} $at{X-1 Y-1 Z}]

site.filled X Y Z = fxn:
| when X < 0 or Y < 0: leave 1
| $at{X Y Z}.filler

site.getCorners X Y Z = fxn: `[]`
  [$filled{X-1 Y-1 Z} $filled{X Y-1 Z} $filled{X-1 Y Z}].all{1}
  [$filled{X+1 Y-1 Z} $filled{X Y-1 Z} $filled{X+1 Y Z}].all{1}
  [$filled{X+1 Y+1 Z} $filled{X Y+1 Z} $filled{X+1 Y Z}].all{1}
  [$filled{X-1 Y+1 Z} $filled{X Y+1 Z} $filled{X-1 Y Z}].all{1}

site.getSides X Y Z = fxn: `[]`
  $filled{X Y-1 Z} $filled{X+1 Y Z}
  $filled{X Y+1 Z} $filled{X-1 Y Z}

site.role X Y Z = fxn:
| when X < 0 or Y < 0: leave 0
| $at{X Y Z}.role

site.getCornersSame X Y Z Role = fxn: `[]`
  [$role{X-1 Y-1 Z} $role{X Y-1 Z} $role{X-1 Y Z}].all{Role}
  [$role{X+1 Y-1 Z} $role{X Y-1 Z} $role{X+1 Y Z}].all{Role}
  [$role{X+1 Y+1 Z} $role{X Y+1 Z} $role{X+1 Y Z}].all{Role}
  [$role{X-1 Y+1 Z} $role{X Y+1 Z} $role{X-1 Y Z}].all{Role}

site.getSidesSame X Y Z Role = fxn: `[]`
  $role{X Y-1 Z}><Role $role{X+1 Y Z}><Role
  $role{X Y+1 Z}><Role $role{X-1 Y Z}><Role

site.update_minimap X Y Color = fxn:
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
| times YY PH: times XX PW: $minimap.set{SX+XX SY+YY Color}

upd_floor Me Bottom = fxn:
| Cell = Bottom
| Floor = Cell
| LastEmpty = 0
| times I $d:
  | Empty = Cell.empty
  | when Empty
    | less LastEmpty: Floor <= Cell
    | Cell.floor <= Floor
  | Cell++
  | LastEmpty <= Empty
| Cell = Bottom+$d-1
| Floor = Cell
| LastEmpty = 0
| times I $d:
  | Empty = Cell.empty
  | less Empty
    | when LastEmpty: Floor <= Cell+1
    | Cell.floor <= Floor
  | Cell--
  | LastEmpty <= Empty

site.upd_pilar X Y =
| fxn: when X < 0 or Y < 0: leave 0
| Cell = $cell{X Y 0}
| upd_floor Me Cell
| $heighmap.X.Y <= fxn (Cell+$d-2).floor.z
| for U $column_units_get{X Y}: U.environment_updated
| Var = $variation.Y.X
| H = $height{X Y}
| Below = $main.tid_map.0
| T = Cell.tile
| Z = 0
| fxn: while Z < H:
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
| $update_minimap{X Y T.sloped_color}

site.upd_neibs X Y =
| for DX,DY Dirs: $upd_pilar{X+DX Y+DY}
| $upd_pilar{X Y}

site.height X Y = $heighmap.X.Y

site.outdoor XYZ = $height{XYZ.0 XYZ.1} << XYZ.2

site.up XYZ = //finds Z of the floor above
| X,Y,Z = XYZ
| H = $height{X Y}
| when Z>>H: leave 0
| while Z<H and $at{X Y Z}.empty: Z++
| till Z>>H or $at{X Y Z}.empty: Z++
| Z

site.down XYZ = //finds Z of the floor below
| X,Y,Z = XYZ
| B = 1
| till $at{X Y B}.empty: B++
| when Z<<B: leave 0
| while Z>B and $at{X Y Z}.empty: Z--
| till Z<<B or $at{X Y Z}.empty: Z--
| while Z>B and $at{X Y Z-1}.empty: Z--
| Z

site.push_ X Y Tile =
| Z = $height{X Y}
| H = Tile.height-1
| Ps = Tile.parts
| times I H: $set_{X Y Z+I Ps.I} // push padding
| $set_{X Y Z+H Tile}


// push Tile on top of pilar at X,Y
site.push XY Tile =
| X,Y = XY
| $push_{X Y Tile}
| $upd_neibs{X Y}

site.pop_ X,Y =
| H = $height{X Y}
| less H: leave
| Z = H-1
| T = $at{X Y Z}
| times I T.height: $set_{X Y Z-I $void}

// pop top tile of pilar at X,Y
site.pop XY =
| $pop_{XY}
| $upd_neibs{XY.0 XY.1}

site.new_gene When Name Amount Data =
| E = $free_genes.pop
| E.when <= When
| E.name <= Name.enheap
| E.amount <= Amount
| E.data <= Data.enheap
| E

site.free_gene E =
| E.name.heapfree
| E.data.heapfree
| $free_genes.push{E}

site.shake Cycles =
| $shake_start <= $cycle
| $shake_end <= $cycle+Cycles

site.set_color_overlay List =
| $color_overlay <= List
| $color_overlay_step <= 0

site.sound_at XYZ ForceExplored SoundName =
| less ForceExplored or $human.explored{XYZ} > 1: leave 0
| CXYZ = $main.ui.view.center
| V = 1.0 / | max 1.0 (CXYZ - XYZ).abs*0.5
| when V>0.01: $main.sound{SoundName volume/V}
| 1

export site
