use gfx gui util widgets macros unit_flags stack fxn

ScreenXY = [0 0]
BrightFactor = 0
BlitItems = 0
BlitUnits = 0
PickedRects = 0
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
CellsSeen =
SeenMask = 0
ExplMask = 0

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

type special_blit{what x y z}

special_blit.draw FB BlitItem =
| if $what >< box_front then draw_bounding_box_front #00FF00 FB Me
  else if $what >< box_back then draw_bounding_box_back #FF0000 FB Me
  else

draw_text FB X Y Msg =
| Font = font small
| ZB = FB.zbuffer
| FB.zbuffer <= 0
| Font.draw{FB X Y Msg}
| FB.zbuffer <= ZB

B_ID = 0
B_OBJECT = 1
B_DATA = 2
B_SX = 3 // screen x,y
B_SY = 4
B_FLAGS = 5
B_DEPS = 6
B_COVER = 7

blit_item Object X Y Z =
| R = [fxn{(X+Y+Z)*1000 - Z} Object 0 0 0 0 [] []]
| push R BlitItems
| R

blit_item_from_unit Me = fxn:
| X,Y,Z = $fxyz
| DX,DY = $box_xy
| DDX = (DX+2*DY)/2
| DDY = 2*DY-DDX
| X += DDX
| Y += DDY
| BI = blit_item Me X Y Z+7  //Z+7 is a hack to avoid cursor cluttering
| $blitem <= BI
| BI

FloatDYs = [0 0 1 2 3 3 2 1]

unit.draw FB B =
//| NDrawnUnits++
| X = fxn B.B_SX
| Y = fxn B.B_SY
| G = $frame
| GW = G.w
| XX = fxn X+XUnit2-GW/2
| YY = fxn Y-YUnit2-G.h
| fxn: YY += $zhack
| when $mirror:
  | XX -= GW%2
  | G.flop
| S = $sprite
| Colors = $colors
| when Colors:
  | Rs = S.colors
  | when Rs:
    | CM = G.raw_cmap
    | times I 5:
      | R = fxn Rs.I
      | when got R: _ffi_set uint32_t CM R Colors.I
| when $active:
  | when S.shadow:
    | S = $site.shadow
    | ZZ = fxn: $cell-$floor
    | I = fxn: min (ZZ/16).abs S.nframes-1
    | SGfx = S.I
    | fxn: FB.blit{X+8 Y-38+ZZ*ZUnit SGfx}
  | fxn: when $flyer
    | YY -= 16
    | Y -= 16
    | less $class.inbornFlyer: //floating animation
      | C = $site.cycle
      | YY += FloatDYs.((C/3+$id)%FloatDYs.size)
    | when $flying: YY -= 64
  | Alpha = $alpha
  | when $invisible:
    | Alpha <= 127
    | C = $site.cycle
    | Alpha -= 20*FloatDYs.((C/4+$id)%FloatDYs.size)
    | Alpha <= max 0 Alpha
  | G.alpha{Alpha}
  | when $class.text:
    | Font = font trigger
    | TX,TY = $class.text_xy
    | Font.draw{FB XX+TX YY+TY $class.text}
| fxn: when B.B_FLAGS&&&#80:
  | CutH = 48
  | CY = max G.h-48 0
  | G.rect{0 CY G.w CutH}
  | YY += CY
| fxn: when B.B_FLAGS&&&#40: G.brighten{-64} //G.dither{1}
| FB.blit{XX YY G}
| fxn: for TB B.B_COVER:
  | TB.B_DEPS <= TB.B_DEPS.skip{$id}
  | when TB.B_DEPS.end:
    | O = TB.B_OBJECT
    | if _tag O then O.draw{FB TB}
      else draw_tile O FB TB
| $blitem <= 0
| less $pickable: leave
| RW,RH,RY = $sprite.rect
| when $picked:
  | RX = X+XUnit2 - RW/2
  | RY = Y+RY-RH
  | when $flying: RY -= 64
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
    | when $flags.bit{Flag}: push Icon Icons
  | when Icons.size
    | XX = RX + RW/2 - Icons.size*8
    | YY = RY - 16
    | Fs = $main.unit_effects_sprite
    | for I Icons
      | F = Fs.I
      | FB.blit{XX YY F}
      | XX += 16

draw_tile Cell FB BlitItem =
//| NDrawnTiles++
| B = BlitItem
| G = fxn B.B_DATA
| Cell.blitem <= 0
| fxn: when B.B_FLAGS&&&#140:
  | G.brighten{if B.B_FLAGS&&&#100 then -250 else -64}
| fxn FB.blit{B.B_SX B.B_SY G}
| Us = fxn B.B_COVER
| when Us.end: leave
| for U Us:
  | UB = U.blitem
  | when UB: //multi-cell objects can be already drawn
    | UB.B_DEPS <= UB.B_DEPS.skip{Cell}
    | when UB.B_DEPS.end: U.draw{FB UB}

type gfx_item

gfx_item.draw FB BlitItem =
| B = BlitItem
| G = B.B_DATA
//| when B.B_FLAGS&&&#40: G.brighten{-64} //G.dither{1}
| FB.blit{B.B_SX B.B_SY G}

render_cursor Me Wr BX BY CursorXYZ =
| X,Y,CurZ = CursorXYZ
| Z = 0
| UnitZ = 0
| EndZ = min CurZ Wr.height{X Y}
| Cell = Wr.cell{X Y 0}
| fxn: while Z < EndZ:
  | G = Cell.gfx
  | T = Cell.tile
  | TH = T.height
  | Cell += TH
  | when G.is_list: G <= G.((Wr.cycle/T.anim_wait)%G.size)
  | UnitZ <= Z + TH
  | TH = T.height
  | ZZ = Z*ZUnit
  | GH = if G then G.h else YUnit
  | SB = special_blit box_back X*CS-2 Y*CS-2 Z*CS
  | B = blit_item SB X*CS-2 Y*CS-2 Z*CS
                       
  | B.B_SX <= BX
  | B.B_SY <= BY-GH-ZZ
  | SB = special_blit box_front X*CS Y*CS Z*CS+2
  | B = blit_item SB X*CS Y*CS Z*CS+2
                       
  | B.B_SX <= BX
  | B.B_SY <= BY-GH-ZZ
  | Z <= UnitZ

render_pilar Me Wr X Y BX BY RoofZ =
| FBH = $fb.h
| EndZ = min RoofZ Wr.height{X Y}
| when fxn BY-((EndZ-1)*ZUnit) > FBH: leave
| Cur = $cursor
| CurX = fxn Cur.0
| CurY = fxn Cur.1
| CurH = fxn (CurX+CurY)/2
| AboveCursor = fxn CurH >> (X+Y)/2
/*| DXY = [X Y]-[CurX CurY]
| when DXY.0 and DXY.1:
  | A = DXY.0.float
  | B = DXY.1.float
  | when A<B: swap A B
  | when (A/B).abs>2.0:
    | AboveCursor <= 1*/
| ZCut = fxn: max Cur.2-1 0
| Fog = 0
| Cell = Wr.cell{X Y 0}
| Us = Cell.units.unheap
| fxn: for U Us: when U.frame: //render units
  | XYZ = U.xyz
  | UX,UY,Z = XYZ
  | TZ = Z-1
  | Seen = U.floor.seen
  | if (Seen&&&SeenMask)><SeenMask then Fog <= 0
    else
    | when (Seen&&&ExplMask)<>ExplMask or U.fow_hides: _goto skip_unit
    | Fog <= 1
  | when TZ < RoofZ and (AboveCursor or TZ << ZCut) and UX><X and UY><Y:
    | when not U.invisible or $player.is_ally{U.owner} or $brush.0:
      | B = blit_item_from_unit U
      | FX,FY,FZ = U.fxyz
      | BX,BY = esc ScreenXY + to_iso{FX FY FZ}
      | B.B_SX <= BX - XUnit2
      | B.B_SY <= BY
      | when U.foldable and
              not (TZ+2 < RoofZ and (AboveCursor or TZ+2 << ZCut)):
        | B.B_FLAGS <= #80 //cut
      | when Fog: B.B_FLAGS <= B.B_FLAGS---#40 //dither
      | push U BlitUnits
  | _label skip_unit
| NextZ = 0
| TH = 0
| fxn: while NextZ < EndZ: //render tiles
  | Z = NextZ
  | G = Cell.gfx
  | T = Cell.tile
  | TH <= T.height
  | NextZ <= Z + TH
  | Seen = Cell.seen
  | if (Seen&&&SeenMask)><SeenMask then Fog <= 0
    else
    | Fog <= if (Seen&&&ExplMask)<>ExplMask then #140 else #40
  | when G:
    | SZ = Z*ZUnit
    | when G.is_list: G <= G.((Wr.cycle/T.anim_wait)%G.size)
    | SY = BY-SZ
    | less SY>FBH:
      | less AboveCursor or NextZ-1 << ZCut: _goto out
      | B = blit_item Cell X*CS Y*CS Z*CS 
      | B.B_SX <= BX
      | B.B_SY <= SY-G.h
      | B.B_DATA <= G
      | B.B_FLAGS <= Fog
      | Cell.blitem <= B
  | _label skip_cell
  | Cell += TH
| _label out
| fxn: less AboveCursor or NextZ-1 << ZCut: //draw folded column marker
  | Z = ZCut+1
  | Z = if NextZ-TH < Z then NextZ-TH else Z
  | Cell = Wr.cell{X Y Z}
  | T = Cell.tile
  | Seen = Cell.seen
  | when (Seen&&&ExplMask)<>ExplMask: _goto skip_fold
  | when T.id and not T.proxy:
    | SZ = Z*ZUnit
    | SY = BY-SZ
    | B = blit_item Cell X*CS Y*CS Z*CS 
    | B.B_SX <= BX
    | B.B_SY <= SY-Folded.h
    //| when Fog: B.B_FLAGS <= #40 //dither
    | B.B_DATA <= Folded
    | Cell.blitem <= B
  | _label skip_fold

render_unexplored Me Wr X Y BX BY =
| B = blit_item gfx_item{} X*CS Y*CS 0
| B.B_DATA <= Unexplored
| B.B_SX <= BX
| B.B_SY <= BY-$zunit-Unexplored.h

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
| push Cell $blitem.B_DEPS
| push Me CB.B_COVER

unit.find_blit_deps =
| X,Y,ZZ = $xyz
| when $form:
  | Mirror = $facing >< 5
  | for DX,DY,DZ $form:
    | XX,YY,ZZ = $xyz + if Mirror then [-DY DX DZ] else [DX -DY DZ]
    | $add_dep{$site.cell{XX YY ZZ-1}}
    | when $height>1:
      | $add_dep{$site.cell{XX-1 YY ZZ+1}}
      | $add_dep{$site.cell{XX YY-1 ZZ+1}}
      | $add_dep{$site.cell{XX-1 YY-1 ZZ+1}}
    | when $height<<1:
      | $add_dep{$site.cell{XX-1 YY ZZ}}
      | $add_dep{$site.cell{XX YY-1 ZZ}}
      | $add_dep{$site.cell{XX-1 YY-1 ZZ}}
  | leave
| fxn:
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
  | when $blitem.B_DEPS.end: leave
  | when $active: //FIXME: hack
    | for U $cell.units: when U.draworder<$draworder:
      | CB = U.blitem
      | when CB:
        | $blitem.B_DEPS <= [U.id @$blitem.B_DEPS]
        | CB.B_COVER <= [$blitem @CB.B_COVER]
  | Cell = $site.cell{X+1 Y+1 ZZ}
  | less Cell.invisible:
    | CB = Cell.blitem
    | when CB:
      | CB.B_DEPS <= [$id @CB.B_DEPS]
      | $blitem.B_COVER <= [CB @$blitem.B_COVER]
  | for U Cell.units:
    | CB = U.blitem
    | when CB:
      | CB.B_DEPS <= [$id @CB.B_DEPS]
      | $blitem.B_COVER <= [CB @$blitem.B_COVER]


view.find_blit_deps = for U BlitUnits: less U.mark: U.find_blit_deps

view.render_iso =
| Wr = $site
| BlitItems <= []
| BlitUnits <= []
| PickedRects <= stack 256
| ExplMask <= $player.explored_mask
| SeenMask <= $player.seen_mask
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
| FBW = FB.w
| fxn: times YY VS
  | Y = YY + VY
  | XXX = TX - YY*XUnit2
  | YYY = TY + YY*YUnit2
  | when 0<Y and Y<<WH: times XX VS:
    | X = XX + VX
    | when 0<X and X<<WW: // FIXME: move this out of the loop
      | BX = XXX + XX*XUnit2
      | less BX < -64 or BX>FBW:
        | BY = YYY + XX*YUnit2
        | less BY < 0: render_pilar Me Wr X Y BX BY RoofZ
| when $mice_click<>left or $brush.0:
  | BX = TX + VY + CurX*XUnit2 - CurY*XUnit2
  | BY = TY + VY + CurX*YUnit2 + CurY*YUnit2
  | render_cursor Me Wr BX BY $cursor
| less BlitItems.end
  | BlitItems <= BlitItems.list
  | $find_blit_deps
  | Bs = BlitItems.qsort_{A B => fxn A.B_ID<B.B_ID}
  | fxn: for B Bs: when B.B_DEPS.end:
    | O = B.B_OBJECT
    | if _tag O then O.draw{FB B} else draw_tile O FB B
| draw_picked_rects FB PickedRects.list.flip
| draw_overlay FB Wr
| PickedRects <= 0
| BlitItems <= 0
| BlitUnits <= 0
| CellsSeen <= 0

view.render_frame =
| IsNight = $site.data.night><1
| BrightFactor <= if IsNight then 10 else 0
//| $fb.clear{#929292/*#00A0C0*/}
| $fb.blit{0 0 $main.img{ui_stars}}
| $render_iso
| when $make_screenshot:
  | $make_screenshot <= 0
  | I = 0
  | fn I = "screenshots/[I].png"
  | while fn{I}.exists: I++
  | $fb.save{fn{I}}
  | say "Saved [fn{I}]"
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

NextUpdate = 0.0
NextRender = 0.0

view.draw FB X Y =
| $fb <= FB
| NDrawnTiles <= 0
| NDrawnUnits <= 0
| GUI = get_gui
| StartTime = GUI.ticks
| if StartTime<NextUpdate then $update{0} //just update input
  else | $update{1}
       | NextUpdate <= StartTime + 1.0/$main.cfg.ui.game_fps.float
| when StartTime < NextRender: GUI.sleep{NextRender-StartTime}
| $render_frame
| FinishTime = GUI.ticks
| SleepSeconds = $calc_fps{StartTime FinishTime}
| $fb <= 0 //no framebuffer outside of view.draw
| when SleepSeconds > 0.0: GUI.sleep{SleepSeconds}

view.render = Me
