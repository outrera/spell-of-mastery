use gfx util fxn

CellSize = 32 //FIXME: hardcoded

type tile{As Main Type Role Id stack/0
          height/1 filler/1 invisible/0 match/same_corner shadow/0
          anim_wait/0 water/0 wall/0 bank/0 unit/0 heavy/1 lineup/1 dig/0
          parts/0 wallShift/0 indoor/0 liquid/0 opaque/No
          around/0 back/0 fallback/[0 0 0] roof/0 hp/0 cost/0
          hit/0 death/0 embed/0 sprite/0 flatGfx/0 lay/No
          struct/0 structTiles/0 colors/[#808080 #A0A0A0]}
     id/Id
     main/Main
     bank/Bank
     type/Type
     role/Role
     stack/Stack //column base, middle, top segments
     sprite/Sprite
     gfxes_data
     flatGfx/FlatGfx
     lay/Lay
     height/Height
     empty/0
     filler/Filler //true if tile fills space, matching with other tiles
     invisible/Invisible
     shadow/Shadow
     match/Match
     anim_wait/Anim_wait
     water/Water
     wall/Wall
     around/Around
     back/Back
     unit/Unit //used for units that act as platforms
     heavy/Heavy //shapes the tile below into a cube
     lineup/Lineup //shaped by tile above into a cube
     dig/Dig
     parts/Parts
     wallShift/WallShift //used for calcucalating door`s fine x,y
     tiler/0
     indoor/Indoor
     liquid/Liquid
     opaque/Opaque
     fallback/Fallback
     roof/Roof
     embed/Embed //embed into what type of other tile
     hp/Hp
     cost/Cost
     hit/Hit //on hit effect
     death/Death //on death effect
     struct/Struct
     structTiles/StructTiles
     colors/Colors
| $empty <= not $id
| when Cost and Cost.size: $cost <= Cost.group{2}{K,V=>"item_[K]",V}
| when no $opaque: $opaque <= not $invisible
| less $parts:
  | if $height>1
    then | $parts <= @flip: map I $height-1
           | tile As Main Type Role Id @[parts -(I+1) @As]
    else $parts <= []

m_same_side Site X Y Z Tile = Site.getSidesSame{X Y Z Tile.role}
m_same_corner Site X Y Z Tile = Site.getCornersSame{X Y Z Tile.role}
m_any_side Site X Y Z Tile = Site.getSides{X Y Z}
m_any_corner Site X Y Z Tile = Site.getCorners{X Y Z}

m_any_cornerside Site X Y Z Tile =
| R = Site.getCorners{X Y Z}
| if R><[0 1 0 0] then
    if Site.filled{X Y+1 Z} then R <= [1 1 0 1]
    else if Site.at{X Y Z+1}.type><Tile.type then R <= [1 1 0 0]
    else
  else if R><[0 0 0 1] then 
    if Site.filled{X+1 Y Z} then R <= [1 1 0 1]
    else if Site.at{X Y Z+1}.type><Tile.type then R <= [1 0 0 1]
    else
  else
| R

//stairs defs
SLeft   = [1 0 0 0]      //left-stairs
SLeftR  = [0 1 0 0]      //left-stairs-reversed
SRightR = [0 0 1 0]      //right-stairs-reversed
SRight  = [0 0 0 1]      //left-stairs
SFrontC = SLeft+SRight   //center-corner
SLeftC  = SLeft+SLeftR   //left-corner
SRightC = SRight+SRightR //right-corner
SBackC  = SLeftR+SRightR //back-corner
SLineH  = SLeftR+SRight
SLineV  = SRightR+SLeft
SRightE = SRightR+SLeft+SRight
SFlat = [0 0 0 0]
SFilled = [1 1 1 1]

m_any_stairs Me X Y Z Tile =
| Role = Tile.role
| H = Tile.height
| E = `[]` //   north            east             south            west
           $filled{X Y-1 Z} $filled{X+1 Y Z} $filled{X Y+1 Z} $filled{X-1 Y Z}
| AN = $role{X Y-1 Z+H}><Role and not $filled{X Y-1 Z+H+1}
| AE = $role{X+1 Y Z+H}><Role and not $filled{X+1 Y Z+H+1}
| AS = $role{X Y+1 Z+H}><Role and not $filled{X Y+1 Z+H+1}
| AW = $role{X-1 Y Z+H}><Role and not $filled{X-1 Y Z+H+1}
//| D = E.digits{2}
//| when [X Y]><[6 4]: say [Role [X Y Z] E]
| if E><SFrontC then
     if      AW and not AN and $filled{X+1 Y Z-H} then E<=SRight
     else if not AW and AN and $filled{X Y+1 Z-H} then E<=SLeft
     else if $filled{X+1 Y Z-H} and not $filled{X Y+1 Z-H} then E<=SRight
     else if $filled{X Y+1 Z-H} and not $filled{X+1 Y Z-H} then E<=SLeft
     else
  else if E><SLeftC then
     if      AE and not AN and $filled{X-1 Y Z-H} then E<=SLeftR
     else if not AE and AN and $filled{X Y+1 Z-H} then E<=SLeft
     else if $filled{X-1 Y Z-H} and not $filled{X Y+1 Z-H} then E<=SLeftR
     else if $filled{X Y+1 Z-H} and not $filled{X-1 Y Z-H} then E<=SLeft
     else
  else if E><SRightC then
     if      AW and not AS and $filled{X+1 Y Z-H} then E<=SRight
     else if not AW and AS and $filled{X Y-1 Z-H} then E<=SRightR
     else if $filled{X+1 Y Z-H} and not $filled{X Y-1 Z-H} then E<=SRight
     else if $filled{X Y-1 Z-H} and not $filled{X+1 Y Z-H} then E<=SRightR
     else
  else if E><SBackC then 
     if      AE and not AS then E<=SLeftR
     else if not AE and AS then E<=SRightR
     else if $filled{X-1 Y Z-H} and not $filled{X Y-1 Z-H} then E<=SLeftR
     else if $filled{X Y-1 Z-H} and not $filled{X-1 Y Z-H} then E<=SRightR
     else
  else if E><SLeft then
     if      $role{X Y+1 Z-H}><Role and not $filled{X Y+1 Z} then
     else if $role{X-1 Y Z-H}><Role and not $filled{X-1 Y Z} then E<=SLeftR
     else if $role{X+1 Y Z-H}><Role and not $filled{X+1 Y Z} then E<=SRight
     else
  else if E><SRight then
     if      $role{X+1 Y Z-H}><Role and not $filled{X+1 Y Z} then
     else if $role{X Y-1 Z-H}><Role and not $filled{X Y-1 Z} then E<=SRightR
     else if $role{X Y+1 Z-H}><Role and not $filled{X Y+1 Z} then E<=SLeft
     else
  else if E><SLeftR then
     if      $role{X-1 Y Z-H}><Role and not $filled{X-1 Y Z} then
     else if $role{X Y-1 Z-H}><Role and not $filled{X Y-1 Z} then E<=SRightR
     else if $role{X Y+1 Z-H}><Role and not $filled{X Y+1 Z} then E<=SLeft
     else
  else if E><SRightR then
     if      $role{X Y-1 Z-H}><Role and not $filled{X Y-1 Z} then
     else if $role{X-1 Y Z-H}><Role and not $filled{X-1 Y Z} then E<=SLeftR
     else if $role{X+1 Y Z-H}><Role and not $filled{X+1 Y Z} then E<=SRight
     else
  else if E><SLineH then
   | A = $filled{X Y+1 Z-H}
   | B = $filled{X Y-1 Z-H}
   | if      A and not B then E<=SLeft
     else if B and not A then E<=SRightR
     else E<=SFilled
  else if E><SLineV then
   | A = $filled{X+1 Y Z-H}
   | B = $filled{X-1 Y Z-H} 
   | if      A and not B then E<=SRight
     else if B and not A then E<=SLeftR
     else E<=SFilled
  else if E><SFlat then
     if $role{X-1 Y Z-H}><Role then E<=SLeftR
     else if $role{X Y+1 Z-H}><Role then E<=[1 0 0 0]
     else if $role{X Y-1 Z-H}><Role then E<=SRightR
     else
  else
| E

m_same_lay Me X Y Z Tile =

BelowSlope = 0
ColumnHeight = 0
BelowTile = 0
BelowG = 0

list.loop I =
| S = $size
| if I<0 then Me.(S - I%S) else Me.(I%S)

tile.render X Y Z Below Above Variation =
| when $invisible
  | BelowSlope <= #@1111
  | leave 0
| Site = $main.site
| less Z: ColumnHeight <= Site.height{X Y}
| TH = $height
| BE = Below.empty
| BR = Below.role
| AH = Above.heavy
| AR = Above.role
| NeibSlope = #@0000
| T = Me
| when $indoor and Z < ColumnHeight-1 /*and AH*/: //FIXME: non-ceil tiles?
  | T <= $indoor
| when T.water:
  | Neib,Water = T.water
  | when got Site.neibs{X Y Z-TH+1}.find{?type><Neib}:
    | T <= Water
| when $back:
  | ZZ = Z-$height
  | A = Site.at{X+1 Y ZZ}
  | B = Site.at{X Y+1 ZZ}
  | C = Site.at{X+1 Y+1 ZZ}
  | Ar = $around
  | when A.type><Ar or B.type><Ar or C.type><Ar:
    | T <= $back
| TT = T
| St = TT.stack
| when St:
  | TT <= if BE then fxn St.2
          else if BR <> $role or fxn BelowSlope><#@1111 then fxn St.0
          else if AR <> $role then fxn St.2
          else fxn St.1
| Gs = TT.gfxes
| Lineup = 0
| when AH and $lineup and ($lineup<>other or AR<>$role):
  | Lineup <= not Above.stack or AR <> $role
| Opaque = $opaque
| G = if AH and TT.flatGfx then
         | NeibSlope <= #@1111
         | TT.flatGfx
      else if $match><same_lay then
         | XX = 1
         | YY = 1
         | while Site.cell{X-XX Y Z}.type><$type: XX++
         | while Site.cell{X Y-YY Z}.type><$type: YY++
         | NeibSlope <= #@1111
         | G,F = Gs.loop{YY-1}.loop{XX-1}
         | when F&&&1: Opaque <= 0
         | G
      else if Lineup then
         | NeibSlope <= #@1111
         | Gs.NeibSlope
      else fxn:
         | Elev = $tiler{}{Site X Y Z Me}
         | FB = TT.fallback
         | when FB.0><Elev and FB.1><AH:
           | Elev <= (FB.3){Site X Y Z Me}
           | Gs <= FB.2.gfxes
         | NeibSlope <= Elev.digits{2}
         | R = fxn Gs.NeibSlope
         | R
| BelowSlope <= NeibSlope
| BelowTile <= TT
| when G.is_list: less $anim_wait: G <= G.(Variation%G.size)
| fxn: when Opaque and Z > 0:
  | ZZ = Z-1
  | A = Site.at{X+1 Y ZZ}
  | B = Site.at{X Y+1 ZZ}
  | C = Site.at{X+1 Y+1 ZZ}
  | D = Site.at{X+1 Y-1 ZZ}
  | TH = Site.at{X Y ZZ}.height
  | when A.opaque and B.opaque and C.opaque and (D.opaque or D.type><border_)
         and A.height>>TH and B.height>>TH and C.height>>TH and D.height>>TH:
    | Site.cell{X Y ZZ}.gfx <= 0
| leave G

tile.sloped_color =
| T = BelowTile
| less T: leave 0
| BelowTile <= 0
| if BelowSlope><#@1111 then T.colors.1 else T.colors.0

main.tile_names Bank =
| $tiles{}{?1}.keep{?bank><Bank}{?type}.skip{$aux_tiles.?^got}.sort

get_match_fn Desc = case Desc
  any_corner     | &m_any_corner
  any_side       | &m_any_side
  same_corner    | &m_same_corner
  same_side      | &m_same_side
  any_cornerside | &m_any_cornerside
  any_stairs     | &m_any_stairs
  same_lay       | &m_same_lay
  Else           | 0

tile.get_tile_sprite TileName SpriteName =
| Sprite = $main.sprites.SpriteName
| less got Sprite: bad "Tile [TileName] references missing sprite [SpriteName]"
| Sprite


Es = [1111 1000 1100 1001 0100 0001 0110 0011
        0010 0111 1011 1101 1110 1010 0101 0000]
DefaultLay =
  [[ 7  6  4]
   [ 5 16  2]
   [ 3  1  0]
   [ 8  9   ]
   [11 10   ]
   [12 13 18]]
LayMap =
  [[#@0010 #@0011 #@0001]
   [#@0110 #@1111 #@1001]
   [#@0100 #@1100 #@1000]
   [#@0111 #@1011]
   [#@1110 #@1101]
   [#@1010 #@0101 #@0000]]

tile.gfxes =
| Gs = $gfxes_data
| when Gs: leave Gs
| $init_gfxes
| $gfxes_data

tile.init_gfxes =
| Sprite = $get_tile_sprite{"[$bank]_[$type]" $sprite}
| NFrames = Sprite.nframes
| getFrame I = 
  | less I < NFrames:
    | bad "Tile `[$type]` wants missing frame [I] in `[$sprite]`"
  | Sprite.I
| Lay = $lay
| less got Lay: Lay <= 0
| Lay <= if Lay.is_int then map Is LayMap: map I Is: Lay
         else if Lay><default then DefaultLay
         else Lay.tail.list
| when $match<>same_lay:
  | $gfxes_data <= dup 16 No
  | for Y LayMap.size:
    | Es = LayMap.Y
    | for X Es.size:
      | E = Es.X
      | Is = Lay.Y.X
      | if Is.is_list then
           | when Is.size: $gfxes_data.E <= Is{?^getFrame}
        else $gfxes_data.E <= Is^getFrame
| when $match><same_lay:
  | $gfxes_data <= map Is Lay: map _,I,F Is: getFrame{I},F
| when $flatGfx:
  | G = $get_tile_sprite{"[$bank]_[$type]" "tiles_[$flatGfx]"}.0
  | $flatGfx <= dup 16 G

main.load_tiles =
| BankNames = case $cfg.site.tile_banks [@Xs](Xs) X[X]
| $cfg.site.tile_banks <= BankNames 
| $aux_tiles <= t
| T = $cfg.tile
| HT = T.height_
| for I 15: // object height blockers
  | T."h[I+1]_" <=
    | R = HT.deep_copy
    | R.height <= I+1
    | R
| Tiles = t
| for Bank BankNames: for Type,Tile $cfg.Bank
  | Tile.bank <= Bank
  | Tiles.Type <= Tile
  | when got Tile.aux: $aux_tiles.Type <= Tile.aux
| $tiles <= t size/1024
| for K,V Tiles
  | Id = if K >< void then 0
         else | $last_tid++
              | $last_tid
  | As = V.list.join
  | Tile = tile As Me K V.role^~{K} Id @As
  | Tile.tiler <= get_match_fn Tile.match
  | less Tile.tiler: bad "tile [K] has invalid `match` ([Tile.match])"
  | $tiles.K <= Tile
| for K,T $tiles
  | when T.stack: T.stack <= T.stack{}{$tiles.?}
  | when T.indoor:
    | T.indoor <= $tiles.(T.indoor)
    | less got T.indoor: bad "tile [K] references unknown indoor tile"
  | when T.water:
    | T.water <= [T.water.0 $tiles.(T.water.1)]
    | less got T.water: bad "tile [K] references unknown water tile"
  | when T.back: T.back <= $tiles.(T.back)
  | when T.fallback.0:
    | T.fallback.2 <= $tiles.(T.fallback.2)
    | less got T.fallback.2: bad "tile [K] references unknown fallback tile"
    | Match = T.fallback.3
    | T.fallback.3 <= get_match_fn Match
    | less T.fallback.3: bad "tile [K] has invalid fallback match = [Match]"
  | when T.roof.is_list: T.roof <= [T.roof.0 $tiles.(T.roof.1)]

export tile
