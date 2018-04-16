use gfx gui util widgets macros unit_flags stack

ScreenXY = [0 0]
BrightFactor = 0
BlitItems = 0
BlitUnits = 0
XUnit2 =
YUnit2 =
XUnit =
YUnit =
ZUnit =
CS =
Folded = 0
Marked = 0
Unexplored = 0
NDrawnUnits = 0
NDrawnTiles = 0

to_iso X Y Z = [X-Y (X+Y)/2-Z]

/* Bounding Box Format:
           1    
         /   \      
       /       \ 
     2           3 
     | \   8   / |
     |   \   /   |
     |     4     |
     | /   |   \ |
     5     |     6
       \   |   /
         \ | /    
           7
*/

draw_bounding_box_front Color FB B =
| X2,Y2 = B.x-32, B.y-32
| ZD = 32
| P = ScreenXY
| P2 = to_iso{X2 B.y B.z} - [0 ZD] + P
| P3 = to_iso{B.x Y2 B.z} - [0 ZD] + P
| P4 = to_iso{B.x B.y B.z} - [0 ZD] + P
| P5 = to_iso{X2 B.y B.z} + P
| P6 = to_iso{B.x Y2 B.z} + P
| P7 = to_iso{B.x B.y B.z} + P
| for A,B [P2,P4 P4,P3 P3,P6 P6,P7 P7,P5 P5,P2 P4,P7]
  | FB.line{Color A B}


draw_bounding_box_back Color FB B =
| X2,Y2 = B.x-32, B.y-32
| ZD = 32
| P = ScreenXY
| P1 = to_iso{X2 Y2 B.z} - [0 ZD] + P
| P2 = to_iso{X2 B.y B.z} - [0 ZD] + P
| P3 = to_iso{B.x Y2 B.z} - [0 ZD] + P
| P5 = to_iso{X2 B.y B.z} + P
| P6 = to_iso{B.x Y2 B.z} + P
| P8 = to_iso{X2 Y2 B.z} + P
| for A,B [P2,P1 P1,P3 P3,P6 P6,P8 P8,P5 P5,P2 P1,P8]
  | FB.line{Color A B}

type special_blit{what}

special_blit.draw FB BlitItem =
| if $what >< box_front then draw_bounding_box_front #00FF00 FB BlitItem
  else if $what >< box_back then draw_bounding_box_back #FF0000 FB BlitItem
  else

draw_text FB X Y Msg =
| Font = font small
| ZB = FB.zbuffer
| FB.zbuffer <= 0
| Font.draw{FB X Y Msg}
| FB.zbuffer <= ZB

type blit_item{object x y z}
  id
  data
  sx sy // screen x,y
  cut // cut this sprite height, to avoid obsucring units behind
  flags
  brighten
  deps/[] //what items must be drawn before this one
  cover/[] //what itms must be drwan after this one

make_blit_item X Y Z Object =
| blit_item Object X Y Z

blit_item_from_unit Me =
| X,Y,Z = $fxyz
| DX,DY = $box_xy
| DDX = (DX+2*DY)/2
| DDY = 2*DY-DDX
| X += DDX
| Y += DDY
| BI = make_blit_item X Y Z+7 Me //Z+7 is a hack to avoid cursor cluttering
| $blitem <= BI
| BI

UnitRects = 0
PickedRects = 0

unit.draw FB B =
| NDrawnUnits++
| X = B.sx
| Y = B.sy
| G = $frame
| GW = G.w
| XX = X+XUnit2-GW/2
| YY = Y-YUnit2-G.h
| YY += $zhack
| when $mirror:
  | XX -= GW%2
  | G.flop
| S = $sprite
| when S.shadow:
  | S = $site.shadow
  | ZZ = $cell-$floor
  | I = min (ZZ/16).abs S.size-1
  | SGfx = S.I
  | SGfx.brighten{B.brighten}
  | FB.blit{X+8 Y-38+ZZ*ZUnit SGfx}
| Colors = $colors
| when Colors:
  | Rs = S.colors
  | when Rs:
    | CM = G.cmap{raw/1}
    | for I 5:
      | R = Rs.I
      | when got R: _ffi_set uint32_t CM R Colors.I
| when $flyer
  | YY -= 16
  | Y -= 16
| G.brighten{B.brighten}
| G.alpha{$alpha}
| when B.cut:
  | CutH = 48
  | CY = max G.h-48 0
  | G.rect{0 CY G.w CutH}
  | YY += CY
| FB.blit{XX YY G}
| for TB B.cover:
  | TB.deps <= TB.deps.skip{$id}
  | when TB.deps.end: TB.object.draw{FB TB}
| $blitem <= 0
| less $pickable: leave
| RW,RH,RY = $sprite.rect
| RX = X+XUnit2 - RW/2
| RY = Y+RY-RH
| UnitRects.push{[RX RY RW RH],Me}
| less $picked: leave
| PickedRects.push{[RX RY RW RH],Me}


PickCorner = 0

draw_bar FB BGColor FGColor X Y W H Cur Max =
| Filled = min{W W*Cur/max{1 Max}}
| FB.rectangle{FGColor 1 X Y Filled H}
| FB.rectangle{BGColor 1 X+Filled Y W-Filled H} 

draw_picked_rects FB PickedRects =
| for [RX RY RW RH],Me PickedRects
  | less PickCorner:
    | PickCorner <= $main.img{ui_picked_corner}
  | PW = PickCorner.w
  | PH = PickCorner.h
  | FB.blit{RX RY PickCorner}
  | FB.blit{RX+RW-PW RY PickCorner.flop}
  | FB.blit{RX RY+RH-PW PickCorner.flip}
  | FB.blit{RX+RW-PW RY+RH-PW PickCorner.flip.flop}
  //| draw_bar FB #000000 #00FF00 RX RY+RH RW 4 $health $class.hp
  | Icons = []
  | for [_ Flag Icon] getUnitFlags{}: when Icon>>0:
    | when $flags^get_bit{Flag}: push Icon Icons
  | when Icons.size
    | XX = RX + RW/2 - Icons.size*8
    | YY = RY - 16
    | Fs = $main.effect.frames
    | for I Icons
      | F = Fs.I
      | FB.blit{XX YY F}
      | XX += 16

tile.draw FB BlitItem =
| NDrawnTiles++
| B = BlitItem
| G,Cell = B.data
| Cell.blitem <= 0
| when B.flags&&&#40: G.dither{1}
| G.brighten{B.brighten}
| FB.blit{B.sx B.sy G}
| for U B.cover:
  | UB = U.blitem
  | UB.deps <= UB.deps.skip{Cell}
  | when UB.deps.end: U.draw{FB UB}

type gfx_item

gfx_item.draw FB BlitItem =
| B = BlitItem
| G = B.data
| when B.flags&&&#40: G.dither{1}
| FB.blit{B.sx B.sy G}

render_cursor Me Wr BX BY CursorXYZ =
| X,Y,CurZ = CursorXYZ
| Z = 0
| UnitZ = 0
| EndZ = min CurZ Wr.height{X Y}
| Cell = Wr.cell{X Y 0}
| while Z < EndZ:
  | G = Cell.gfx
  | T = Cell.tile
  | TH = T.height
  | Cell += TH
  | when G.is_list: G <= G.((Wr.cycle/T.anim_wait)%G.size)
  | UnitZ <= Z + TH
  | TH = T.height
  | ZZ = Z*ZUnit
  | GH = if G then G.h else YUnit
  | B = make_blit_item X*CS-2 Y*CS-2 Z*CS
                       special_blit{box_back}
  | B.sx <= BX
  | B.sy <= BY-GH-ZZ
  | push B BlitItems
  | B = make_blit_item X*CS Y*CS Z*CS+2
                       special_blit{box_front}
  | B.sx <= BX
  | B.sy <= BY-GH-ZZ
  | push B BlitItems
  | Z <= UnitZ

render_pilar Me Wr X Y BX BY CursorXYZ RoofZ Explored =
| DrawnFold = 0
| CurX,CurY,CurZ = CursorXYZ
| CurH = (CurX+CurY)/2
| XY2 = (X+Y)/2
| AboveCursor = CurH >> XY2
| ZCut = max CurZ 0
| Z = 0
| UnitZ = 0
| Fog = Explored><1
| Br = @int -([CurX CurY]-[X Y]).abs
| Br *= BrightFactor
| SkipZ = -1//if $brush.0 then -1 else 0
| Us = Wr.column_units_get{X Y}
| when Fog: Us <= Us.skip{(?owner.id or ?class.hp or ?bank><effect)}
//| draw_text FB BX+XUnit2 BY-ZUnit*Z-20 "[Explored]"
| for U Us:
  | if U.frame.w > 1 then
    | XYZ = U.xyz
    | UX,UY,Z = XYZ
    | TZ = Z-1
    | when TZ < RoofZ and (AboveCursor or TZ << ZCut) and UX><X and UY><Y:
      | when not U.invisible or U.owner.id><$player.id or $brush.0:
        | B = blit_item_from_unit U
        | FX,FY,FZ = U.fxyz
        | BX,BY = ScreenXY + to_iso{FX FY FZ}
        | B.sx <= BX - XUnit2
        | B.sy <= BY
        | B.brighten <= Br
        | B.cut <= U.foldable
                   and not (TZ+2 < RoofZ and (AboveCursor or TZ+2 << ZCut))
        | push B BlitItems
        | push U BlitUnits
    else
| Cell = Wr.cell{X Y 0}
| EndZ = min RoofZ Wr.height{X Y}
| FBW = $fb.w
| FBH = $fb.h
| while Z < EndZ:
  | G = Cell.gfx
  | T = Cell.tile
  | TH = T.height
  | UnitZ <= Z + TH
  | when G:
    | ZZ = Z*ZUnit
    | when G.is_list: G <= G.((Wr.cycle/T.anim_wait)%G.size)
    | TZ = UnitZ - 1
    | SY = BY-ZZ
    | less SY < 0 or BX < -64 or BX>FBW or SY>FBH or T.invisible:
      | if AboveCursor or TZ << ZCut then
        else if not DrawnFold then
          | DrawnFold <= 1
          | G <= Folded
        else G <= 0
      | when G and Z>SkipZ:
          | B = make_blit_item X*CS Y*CS Z*CS T
          | B.data <= G,Cell
          | B.sx <= BX
          | B.sy <= SY-G.h
          | B.brighten <= Br
          | when Fog: B.flags <= #40 //dither
          | push B BlitItems
          | Cell.blitem <= B
  | Cell += TH
  | Z <= UnitZ

render_unexplored Me Wr X Y BX BY =
| B = make_blit_item X*CS Y*CS 0 gfx_item{}
| B.data <= Unexplored
| B.sx <= BX
| B.sy <= BY-$zunit-Unexplored.h
| push B BlitItems

colorize G Layer Color =
| Alpha = Color >>> 24
| Color <= Color &&& #FFFFFF
| Layer.cmap <= dup 256 Color
| LW = Layer.w
| LH = Layer.h
| WN = (G.w+LW-1)/LW
| HN = (G.h+LH-1)/LH
| times X LW: times Y LH:
  | Layer.alpha{Alpha}
  | G.blit{X*LH Y*LH Layer}

draw_overlay FB Wr =
| CO = Wr.color_overlay
| when CO.end: leave
| S = Wr.color_overlay_step
| Wr.color_overlay_step <= S+1
| K = 0
| for (I = 0; K<CO.size; K++):
  | D = CO.K.0
  | when I << S and S < I+D: done
  | I += D
| when K><CO.size:
  | Wr.set_color_overlay{[]}
  | leave
| colorize FB Wr.main.img{"ui_colorizer"} CO.K.1

ShakeXY = [[10 10] [0 10] [0 -10] [0 0] [-10 -10] [10 0] [-10 0]]

unit.add_dep Cell =
| when Cell.invisible: leave
| CB = Cell.blitem
| when not CB: leave
| push Cell $blitem.deps
| push Me CB.cover

unit.find_blit_deps =
| X,Y,ZZ = $xyz
| C = $cell+1
| Z = ZZ+1
| EndZ = min $site.d Z+3
| while C.invisible and Z<EndZ:
  | $add_dep{$site.cell{X-1 Y Z}}
  | $add_dep{$site.cell{X Y-1 Z}}
  | $add_dep{$site.cell{X-1 Y-1 Z}}
  | C++
  | Z++
| C = $site.cell{X Y+1 ZZ}+1
| EndZ <= Z
| Z <= ZZ+1
| while C.invisible and Z<EndZ:
  | $add_dep{$site.cell{X-1 Y+1 Z}}
  | C++
  | Z++
| C = $site.cell{X+1 Y ZZ}+1
| EndZ <= Z
| Z <= ZZ+1
| while C.invisible and Z<EndZ:
  | $add_dep{$site.cell{X+1 Y-1 Z}}
  | C++
  | Z++
| when $blitem.deps.end: leave
| Cell = $site.cell{X+1 Y+1 ZZ}
| less Cell.invisible:
  | CB = Cell.blitem
  | when CB:
    | push $id CB.deps
    | push CB $blitem.cover
| for U Cell.units:
  | CB = U.blitem
  | when CB:
    | push $id CB.deps
    | push CB $blitem.cover


view.find_blit_deps = for U BlitUnits: U.find_blit_deps

view.render_iso =
| Wr = $site
| BlitItems <= []
| BlitUnits <= []
| PickedRects <= stack 256
| UnitRects <= stack 1024
| Explored = Wr.human.sight
| FB = $fb
| Z = if $mice_click then $anchor.2 else $cursor.2
| RoofZ = Wr.roof{$cursor}
| CurX,CurY,CurZ = $cursor
| XUnit <= $xunit
| YUnit <= $yunit
| ZUnit <= $zunit
| XUnit2 <= XUnit/2
| YUnit2 <= YUnit/2
| CS <= $d
| TX,TY = $blit_origin + [0 YUnit] + [0 Z]*ZUnit
| VX,VY = $view_origin
| when Wr.cycle < Wr.shake_end:
  | D = Wr.cycle - Wr.shake_start
  | ShkX,ShkY = ShakeXY.(D%ShakeXY.size)
  | TX += ShkX
  | TY += ShkY
| ScreenXY.init{[TX+XUnit2 TY]+to_iso{-VX*XUnit2 -VY*YUnit 0}}
| WW = Wr.w
| WH = Wr.h
| VS = $view_size
| less Folded:
  | Folded <= Wr.main.img{ui_cell_folded}
  | Marked <= Wr.main.img{ui_cell_marked}
  | Unexplored <= Wr.main.img{ui_cell_unexplored}
| times YY VS
  | Y = YY + VY
  | XXX = TX - YY*XUnit2
  | YYY = TY + YY*YUnit2
  | when 0<Y and Y<<WH: times XX VS:
    | X = XX + VX
    | when 0<X and X<<WW: // FIXME: move this out of the loop
      | BX = XXX + XX*XUnit2
      | BY = YYY + XX*YUnit2
      | E = Explored.Y.X
      | if E then render_pilar Me Wr X Y BX BY $cursor RoofZ E
        else render_unexplored Me Wr X Y BX BY
| when $mice_click<>left or $brush.0:
  | BX = TX + VY + CurX*XUnit2 - CurY*XUnit2
  | BY = TY + VY + CurX*YUnit2 + CurY*YUnit2
  | render_cursor Me Wr BX BY $cursor
| less BlitItems.end
  | BlitItems <= BlitItems.list
  | $find_blit_deps
  | for B BlitItems: B.id <= (B.x+B.y+B.z)*1000 - B.z
  | Bs = BlitItems.qsort_{A B => A.id<B.id}
  | for B Bs: when B.deps.end: B.object.draw{FB B}
| draw_picked_rects FB PickedRects.list.flip
| draw_overlay FB Wr
| less $brush.0: $handle_pick{UnitRects.list.flip}
| BlitItems <= 0
| BlitUnits <= 0
| UnitRects <= 0

view.render_frame =
| IsNight = $site.data.night><1
| BrightFactor <= if IsNight then 10 else 0
//| $fb.clear{#929292/*#00A0C0*/}
| $fb.blit{0 0 $main.img{ui_stars}}
| $render_iso
| InfoText = []
| when $cfg.show_frame: push "Frame=[$frame]" InfoText
| when $cfg.show_cycle: push "Cycle=[$site.cycle]" InfoText
| when $cfg.show_fps: push "FPS=[$fps]" InfoText
| when $cfg.show_load:
  | push "DrawnTiles=[NDrawnTiles]" InfoText
  | push "DrawnUnits=[NDrawnUnits]" InfoText
| $infoText.value <= InfoText.infix{'; '}.text
| $infoText.render.draw{$fb 200 ($h-50)}
| $infoText.value <= ''

// calculates current framerate and adjusts sleeping accordingly
view.calc_fps StartTime FinishTime =
| DT = FinishTime-StartTime
| $fpsT += DT
| when $frame%24 >< 0
  | $fps <= @int 24.0/$fpsT
  | $fpsT <= 0.0
  | when $fps < $fpsGoal and $fpsD < $fpsGoal.float*2.0: $fpsD += 1.0
  | when $fps > $fpsGoal and $fpsD > $fpsGoal.float/2.0: $fpsD -= 1.0
| $frame++
| SleepTime = 1.0/$fpsD - DT
| SleepTime

view.draw FB X Y =
| $fb <= FB
| NDrawnTiles <= 0
| NDrawnUnits <= 0
| GUI = get_gui
| StartTime = GUI.ticks
| $update
| $render_frame
| FinishTime = GUI.ticks
| $calc_fps{StartTime FinishTime}
| $fb <= 0 //no framebuffer outside of view.draw

view.render = Me
