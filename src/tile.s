use gfx util fxn

type tile{As Main Type Id stack/0
          tiler/[uniq any corner] ztiler/[uniq same]
          height/1 filler/1 invisible/0 shadow/0
          anim_wait/0 water/0 bank/0 unit/0 heavy/1 lineup/1 dig/0
          parts/0 wallShift/0 plain/0 indoor/0 liquid/0 opaque/No
          around/0 back/0 fallback/[0 0 0] hp/0
          hit/0 death/0 embed/0 sprite/0 flatGfx/0 lay/No
          struct/0 structTiles/0 colors/[#808080 #A0A0A0]}
     id/Id
     main/Main
     bank/Bank
     type/Type
     tiler/Tiler
     match/0
     role/0
     tilerFn/0
     zrole/0
     zmatch/0
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
     anim_wait/Anim_wait
     water/Water
     around/Around
     back/Back
     unit/Unit //used for units that act as platforms
     heavy/Heavy //1=shapes the tile below into a cube
                 //2=shapes into cube, but preserves grass
     lineup/Lineup //shaped by tile above into a cube
     dig/Dig
     parts/Parts
     wallShift/WallShift //used for calcucalating door`s fine x,y
     plain/Plain
     indoor/Indoor
     liquid/Liquid //this tile is liquid
     opaque/Opaque
     fallback/Fallback
     embed/Embed //embed into what type of other tile
                 //0 = don't embed, but place on top
                 //1 = embed water
                 //2 = embed floor
     hp/Hp
     hit/Hit //on hit effect
     death/Death //on death effect
     struct/Struct
     structTiles/StructTiles
     colors/Colors
| [Role Match TilerName] = $tiler
| $role <= Role
| $match <= Match
| $tiler <= TilerName
| when $role><uniq: $role <= $type
| when $match><same: $match <= $role
| [ZRole ZMatch] = Ztiler
| $zrole <= ZRole
| $zmatch <= ZMatch
| when $zrole><uniq: $zrole <= $type
| when $zmatch><same: $zmatch <= $zrole
| $empty <= not $id
| when no $opaque: $opaque <= not $invisible
| less $parts:
  | if $height>1
    then | $parts <= @flip: map I $height-1
           | tile As Main Type Id @[parts -(I+1) @As]
    else $parts <= []

m_role_side Site X Y Z Tile = Site.getSidesRole{X Y Z Tile.match}
m_role_corner Site X Y Z Tile = Site.getCornersSame{X Y Z Tile.match}
m_any_side Site X Y Z Tile = Site.getSides{X Y Z}
m_any_corner Site X Y Z Tile = Site.getCorners{X Y Z}

m_role_wall Site X Y Z Tile =
| R = Site.getSidesRole2{X Y Z Tile.match}
| when Site.at{X Y Z-1}.role><Tile.match:
  | R <= Site.getSidesRole2{X Y Z-1 Tile.match}
| when R >< [0 0 0 0]:
  | when Site.at{X Y Z+1}.role><Tile.match:
    | R <= Site.getSidesRole2{X Y Z+1 Tile.match}
| R

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
BU = [1 0 0 0]  //up
BR = [0 1 0 0]  //right
BD = [0 0 1 0]  //down
BL = [0 0 0 1]  //left
BS = BU+BL      //south corner
BW = BU+BR      //west corner
BE = BL+BD      //east corner
BN = BR+BD      //north corner
BH = BR+BL      //horizontal
BV = BD+BU      //vertical
BXD = BU+BL+BR  //eXcluding down
BXU = BL+BD+BR  //eXcluding up
BXL = BU+BD+BR  //eXcluding left
BXR = BU+BD+BL  //eXcluding right
SFlat = [0 0 0 0]
SFilled = [1 1 1 1]

m_role_stairs Me X Y Z Tile =
| Role = Tile.role
| H = Tile.height
| E = `[]` $filled{X Y-1 Z} $filled{X+1 Y Z} $filled{X Y+1 Z} $filled{X-1 Y Z}
| AU = $role{X Y-1 Z+H}><Role and not $filled{X Y-1 Z+H+1}
| AR = $role{X+1 Y Z+H}><Role and not $filled{X+1 Y Z+H+1}
| AD = $role{X Y+1 Z+H}><Role and not $filled{X Y+1 Z+H+1}
| AL = $role{X-1 Y Z+H}><Role and not $filled{X-1 Y Z+H+1}
//| D = E.digits{2}
//| when [X Y Z]><[2 8 6]: say [Role [X Y Z] E]
| if E><BS then
     if      AL and not AU and $filled{X+1 Y Z-H} then E<=BL
     else if not AL and AU and $filled{X Y+1 Z-H} then E<=BU
     else if $filled{X+1 Y Z-H} and not $filled{X Y+1 Z-H} then E<=BL
     else if $filled{X Y+1 Z-H} and not $filled{X+1 Y Z-H} then E<=BU
     else if not AD and AU then E<=BXD
     else if not AR and AL then E<=BXR
     else
  else if E><BW then
     if      AR and not AU and $filled{X-1 Y Z-H} then E<=BR
     else if not AR and AU and $filled{X Y+1 Z-H} then E<=BU
     else if $filled{X-1 Y Z-H} and not $filled{X Y+1 Z-H} then E<=BR
     else if $filled{X Y+1 Z-H} and not $filled{X-1 Y Z-H} then E<=BU
     else if not AD and AU then E<=BXD
     else if not AL and AR then E<=BXL
     else
  else if E><BE then
     if      AL and not AD and $filled{X+1 Y Z-H} then E<=BL
     else if not AL and AD and $filled{X Y-1 Z-H} then E<=BD
     else if $filled{X+1 Y Z-H} and not $filled{X Y-1 Z-H} then E<=BL
     else if $filled{X Y-1 Z-H} and not $filled{X+1 Y Z-H} then E<=BD
     else if AD and not AU then E<=BXU
     else if not AR and AL then E<=BXR
     else
  else if E><BN then 
     if      AR and not AD then E<=BR
     else if not AR and AD then E<=BD
     else if $filled{X-1 Y Z-H} and not $filled{X Y-1 Z-H} then E<=BR
     else if $filled{X Y-1 Z-H} and not $filled{X-1 Y Z-H} then E<=BD
     else
  else if E><BU then
     if      $role{X Y+1 Z-H}><Role and not $filled{X Y+1 Z} then
     else if $role{X-1 Y Z-H}><Role and not $filled{X-1 Y Z} then E<=BR
     else if $role{X+1 Y Z-H}><Role and not $filled{X+1 Y Z} then E<=BL
     else
  else if E><BL then
     if      $role{X+1 Y Z-H}><Role and not $filled{X+1 Y Z} then
     else if $role{X Y-1 Z-H}><Role and not $filled{X Y-1 Z} then E<=BD
     else if $role{X Y+1 Z-H}><Role and not $filled{X Y+1 Z} then E<=BU
     else
  else if E><BR then
     if      $role{X-1 Y Z-H}><Role and not $filled{X-1 Y Z} then
     else if $role{X Y-1 Z-H}><Role and not $filled{X Y-1 Z} then E<=BD
     else if $role{X Y+1 Z-H}><Role and not $filled{X Y+1 Z} then E<=BU
     else
  else if E><BD then
     if      $role{X Y-1 Z-H}><Role and not $filled{X Y-1 Z} then
     else if $role{X-1 Y Z-H}><Role and not $filled{X-1 Y Z} then E<=BR
     else if $role{X+1 Y Z-H}><Role and not $filled{X+1 Y Z} then E<=BL
     else
  else if E><BH then
   | A = $filled{X Y+1 Z-H}
   | B = $filled{X Y-1 Z-H}
   | if      A and not B then E<=BU
     else if B and not A then E<=BD
     else E<=SFilled
  else if E><BV then
   | A = $filled{X+1 Y Z-H}
   | B = $filled{X-1 Y Z-H} 
   | if      A and not B then E<=BL
     else if B and not A then E<=BR
     else E<=SFilled
  else if E><SFlat then
     if $role{X-1 Y Z-H}><Role then E<=BR
     else if $role{X Y+1 Z-H}><Role then E<=[1 0 0 0]
     else if $role{X Y-1 Z-H}><Role then E<=BD
     else
  else
| E

m_role_lay Me X Y Z Tile =

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
| BZR = Below.zrole
| AH = Above.heavy
| AZR = Above.zrole
| NeibSlope = #@0000
| T = Me
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
| ZR = $zmatch //match zrole
| St = TT.stack
| when St:
  | TT <= if BE then fxn St.2
          else if BZR <> ZR or fxn BelowSlope><#@1111 then fxn St.0
          else if AZR <> ZR then fxn St.2
          else fxn St.1
| Gs = TT.gfxes
| Lineup = 0
| when AH and $lineup and ($lineup<>other or AZR<>ZR):
  | Lineup <= not Above.stack or AZR<>ZR
| Opaque = $opaque
| G = if AH and TT.flatGfx then
         | NeibSlope <= #@1111
         | TT.flatGfx
      else if $tiler><lay then
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
         | Elev = $tilerFn{}{Site X Y Z Me}
         | FB = TT.fallback
         | when esc FB.0><Elev and FB.1><AH:
           | Elev <= (FB.3){Site X Y Z Me}
           | Gs <= FB.2.gfxes
         | NeibSlope <= Elev.digits{2}
         | R = fxn Gs.NeibSlope
         | R
| BelowSlope <= NeibSlope
| BelowTile <= TT
| when G.is_list:
  | less $anim_wait: G <= G.(Variation%G.size)
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

get_tiler_fn Match Tiler =
  if Match><any then case Tiler
      corner     | &m_any_corner
      side       | &m_any_side
      cornerside | &m_any_cornerside
      Else       | 0
  else case Tiler
      corner    | &m_role_corner
      side      | &m_role_side
      lay       | &m_role_lay
      wall      | &m_role_wall
      stairs    | &m_role_stairs
      Else      | 0

tile.get_tile_sprite TileName SpriteName =
| Sprite = $main.sprites."tiles_[SpriteName]"
| less got Sprite: bad "Tile [TileName] references missing sprite [SpriteName]"
| Sprite

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
| when $tiler<>lay:
  | $gfxes_data <= dup 16 No
  | for Y LayMap.size:
    | Es = LayMap.Y
    | for X Es.size:
      | E = Es.X
      | Is = Lay.Y.X
      | if Is.is_list then
           | when Is.size: $gfxes_data.E <= Is{?^getFrame}
        else $gfxes_data.E <= Is^getFrame
| when $tiler><lay:
  | $gfxes_data <= map Is Lay: map _,I,F Is: getFrame{I},F
| when $flatGfx:
  | G = $get_tile_sprite{"[$bank]_[$type]" $flatGfx}.0
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
  | Tile = tile As Me K Id @As
  | Tile.tilerFn <= get_tiler_fn Tile.match Tile.tiler
  | less Tile.tilerFn: bad "tile [K] has invalid tiler=[Tile.tiler]"
  | $tiles.K <= Tile
| for K,T $tiles
  | when T.stack: T.stack <= T.stack{}{$tiles.?}
  | when T.plain:
    | T.plain <= $tiles.(T.plain)
    | less got T.plain: bad "tile [K] references unknown plain tile"
  | when T.indoor:
    | T.indoor <= $tiles.(T.indoor)
    | less got T.indoor: bad "tile [K] references unknown indoor tile"
  | when T.water:
    | T.water <= [T.water.0 $tiles.(T.water.1)]
    | less got T.water.1: bad "tile [K] references unknown water tile"
  | when T.back: T.back <= $tiles.(T.back)
  | when T.fallback.0:
    | FT = $tiles.(T.fallback.2)
    | when no FT: bad "tile [K] references unknown fallback tile"
    | T.fallback <= [T.fallback.0 T.fallback.1 FT FT.tilerFn]

export tile
