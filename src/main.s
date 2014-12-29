use util heap octree gui widgets view macros

type main{Data} world data/Data sounds/"[Data]sounds"
                view_w/448 view_h/448 cursor rect_back rect_front
                cache/(t) cycle
                acts obj_types unit_types editor_types
                tiles aux_tiles
| $cursor <= gfx "[Data]/misc/cursor.png"
| $rect_back <= gfx "[Data]/misc/rect_back.png"
| $rect_front <= gfx "[Data]/misc/rect_front.png"
| $acts <= $load_types{act "[Data]/act/"}
| $obj_types <= $load_types{act "[Data]/obj/"}
| $unit_types <= $load_types{act "[Data]/units/"}
| $load_tiles

transparentize Base Alpha =
| Empty = rgba 0 0 0 255
| as R Base.copy
  | for [X Y] points{0 0 64 64}: when X^^1 >< Y^^1: R.set{X Y Empty}


TileW = 64
TileH = 32

GetSideElev =
GetCornerElev =
GetCornerTrns =
DummyGfx = gfx 1 1

genTransition M F T = //Mask From To
| Alpha = rgba 0 0 0 255
| as R T.copy
  | for [X Y] points{0 0 64 32}: less M.get{X Y} >< Alpha: R.put{X Y F.get{X Y}}

type tile{Type Role Tid Elev Trn Empty Tiling Lineup Renderer Ds Ms Us Trns Base}
  type/Type role/Role tid/Tid elev/Elev trn/Trn empty/Empty tiler neib_elevs/[0 0 0 0]
  lineup/Lineup renderer/Renderer ds/Ds ms/Ms us/Us trns/Trns base/Base
| $tiler <= case Tiling side(=>GetSideElev) _(=>GetCornerElev)

tile.slope = case $neib_elev
  []+[1 1 1 1]+[0 0 0 0] | 0
  _ | 16

tile.render P Z D U S = if $renderer >< none then DummyGfx else
| DE = D.empty
| DR = D.role
| UH = U.heavy
| UR = U.role
| UPad = UR >< pad
| Gs = if DR <> $role then $ds
       else if UR <> $role and not UPad then $us
       else $ms
| G = if $lineup and (UH or UPad or UR >< $role)
        then | $neib_elevs.init{[1 1 1 1]}
             | Gs.$neib_elevs
      else | $neib_elevs.init{($tiler P Z){E => if E < $elev then 0 else 1}}
           | R = Gs.$neib_elevs
           | less got R
             | Gs.$neib_elevs.init{[1 1 1 1]}
             | R <= Gs.$neib_elevs
           | R
| G = G.(S%G.len)
| when not $trn or $neib_elevs <> [1 1 1 1]: leave G
| Rs = GetCornerTrns{P Z $role}
| when Rs.all{1}: leave G
| genTransition $trns.Rs.0 G $base

tile.heavy = not $empty

main.load_tiles =
| G = gfx "[$data]/til/gfx.png"
| Tiles = t
| $aux_tiles <= t
| cutTile N = G.cut{N%20*64 N/20*64 64 64}
| for [Type CornersElevation @Rest] cfg."[$data]/til/map.txt"
  | [Is As] = Rest.div{is.['/'@_]}.xs{0,1}{?^~{[]}}
  | CE = CornersElevation.digits.pad{4 0}
  | less Is.size: bad "one of [Type] tiles misses gfxes"
  | Tile = Tiles->Type
  | Gs = case Is [stack @Is] | Tile.stack <= Is
                             | []
              Else | Is{&cutTile}
  | for X As{?tail}: case X
    [alpha Alpha] | Gs <= Gs{(transparentize ? Alpha)}
    [aux Value] | $aux_tiles.Type <= Value
    [Arg Value] | Tile.Arg <= Value
  | when Gs.size: Tile->gfxes.CE <= Gs
| Trns = Tiles.trns.gfxes
| Base = Tiles.base.gfxes.[1 1 1 1].0
| $tiles <= t size/1024
| for [K V] Tiles
  | [Ds Ms Us] = case V.gfxes
                      T<1^got | [T T T]
                      Else | V.stack{}{Tiles.?.gfxes}
  | $tiles.K <= tile K V.role^~{K} V.tid V.elev^~{1}
                     V.trn V.empty V.tiling V.no_lineup^~{0}^not V.renderer
                     Ds Ms Us Trns Base


main.load_types What Dir = 

M = main: main_root
World = No

set_skin "[M.data]ui"


T = octree 128
T.set{3,3,3 123}
//say T.get{3,3,3}
say T.neibs{3,3,3}

/*
Tabs = No
GameMenu = No
View = view M.view_w M.view_h M

GameMenu <=
| Save = button 'Save (F11)' w_size/small state/disabled (=>)
| Load = button 'Load (F12)' w_size/small state/disabled (=>)
| Show = dlg: mtx
  |   0   0 | spacer 640 480
  | 270 100 | img 'panel/dlg1'
  | 346 110 | txt size/medium 'Game Menu'
  | 285 140 | lay v 8: list
              lay{h 12 [Save Load]}
              button{'Options (F5)' state/disabled (=>)}
              button{'Help (F1)' state/disabled (=>)}
              button{'Scenario Objectives' state/disabled (=>)}
              (button 'End Scenario': =>
                | View.pause
                | GameMenu.pick{hide}
                | set_skin "[M.data]ui/orc"
                | (get_gui).cursor <= skin_cursor{point}
                | Tabs.pick{main})
              spacer{1 20}
              (button 'Return to Game (Esc)': =>
                 | View.unpause
                 | GameMenu.pick{hide})
| Hide = spacer 0 0
| tabs hide: t show(Show) hide(Hide)


MenuBG = gfx "[M.data]/ui/default/image/menu.png"

pud_desc Path =
| Cs = Path.get^(@r$[] [4/M.utf8 4/L.u4 L/D @Xs] => [[M D] @Xs^r])
| less Cs^is{[[\TYPE _]@_]}: bad "Invalid PUD file: [Path]"
| for [T D] Cs: when T >< 'DESC': leave D.take{D.locate{0}^~{32}}.utf8
| ''

type res_indicator.widget{Res View} w/1 h/1 view/View res/Res icon/skin{"res/[Res]"}

res_indicator.draw G P =
| G.blit{P $icon}
| F = font small
| F.draw{G P.0+$icon.w+4 P.1 white $view.player.resources.$res.as_text}

Ingame = dlg: mtx
  |   0   0 | spacer 640 480
  |   0   0 | lay h 0: list
                (lay v 0: list img{'panel/buttonbg'}
                               (dlg: mtx |  0 0 | img{'panel/minimap'}
                                         | 24 2 | minimap M: XY => View.center_at{XY}
                                      )
                               img{'panel/info'}
                               img{'panel/filler'})
                (lay v 0: list img{'panel/top'}
                               View
                               img{'panel/bottom'})
                img{'panel/right'}
  |  24   2 | button 'Menu (F10)' w_size/large h_size/small: =>
              | View.pause
              | GameMenu.pick{show}
  |   6 166 | View.panel
  |   8 340 | lay v 2: View.panel.act_icons.group{3}{(lay h 2 ?)}
  | 266   0 | res_indicator gold View
  | 356   0 | res_indicator wood View
  | 446   0 | res_indicator oil View
  |   0   0 | GameMenu

ScenarioMenu =
| Desc = txt ''
| File = No
| Start = button 'Start Game' state/disabled: =>
          | World <= world M
          | World.load_pud{File}
          | set_skin "[M.data]ui/[World.player.side]"
          | (get_gui).cursor <= skin_cursor{point}
          | Tabs.pick{ingame}
          | View.init
| dlg: mtx
  |   0   0 | MenuBG
  | 230 220 | txt size/medium 'Custom Game Setup'
  |  40 256 | txt 'Your Race:'
  |  40 272 | droplist ['Map Default' 'Orc' 'Human']
  | 220 256 | txt 'Resources:'
  | 220 272 | droplist ['Low' 'Medium' 'High']
  | 400 256 | txt 'Units:'
  | 400 272 | droplist w/160 ['Map Default' 'One Peasant only']
  |  40 306 | txt 'Game Type:'
  |  40 322 | droplist ['Map Default']
  | 220 306 | txt 'Game Type:'
  | 220 322 | droplist ['Map Default' 'Forest' 'Winter' 'Wasteland' 'Swamp']
  |  14 400 | txt 'Description:'
  |  32 416 | Desc
  | 320   0 | folder_widget "[M.data]/maps": P =>
              | if P.url.2 >< pud
                then | Start.state <= \normal
                     | File <= P
                     | Desc.value <= pud_desc P
                else | Start.state <= \disabled
                     | Desc.value <= ''
  | 400 370 | lay v 8 [Start (button 'Cancel Game': => Tabs.pick{main})]

MainMenu = dlg: mtx
  |   0   0 | MenuBG
  |  60 460 | txt 'SymCraft v0.1 by Nikita Sadkov'
  | 208 240 | lay v 8: list
              button{'New Campaign'    state/disabled (=>)}
              button{'Custom Scenario' (=>Tabs.pick{scenario})}
              button{'Multi Player'    state/disabled (=>)}
              button{'Load Game'       state/disabled (=>)}
              button{'Map Editor'      state/disabled (=>)}
              button{'Exit Program'    (=>get_gui{}.exit)}

Tabs <= tabs scenario: t main(MainMenu) scenario(ScenarioMenu) ingame(Ingame)

gui Tabs cursor/skin_cursor{point}
*/
