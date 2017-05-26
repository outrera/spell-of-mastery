use gfx gui util widgets macros isort_ unit_flags stack

ScreenXY = [0 0]
BrightFactor = 0
BlitItems = 0
XUnit2 =
YUnit2 =
XUnit =
YUnit =
ZUnit =
CS =
CS2 =
Folded = 0
Marked = 0
Unexplored = 0

draw_text FB X Y Msg =
| Font = font small
| ZB = FB.zbuffer
| FB.zbuffer <= 0
| Font.draw{FB X Y Msg}
| FB.zbuffer <= ZB

type blit_item{object x y z x2 y2 z2}
  id
  data
  sx sy // screen x,y
  flags
  brighten
  lx ly

make_blit_item X Y Z XD YD ZD Object =
| blit_item Object X Y Z X-XD/2 Y-YD/2 Z+ZD


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
| ZD = B.z2-B.z
| P = ScreenXY
| P2 = to_iso{B.x2 B.y B.z} - [0 ZD] + P
| P3 = to_iso{B.x B.y2 B.z} - [0 ZD] + P
| P4 = to_iso{B.x B.y B.z} - [0 ZD] + P
| P5 = to_iso{B.x2 B.y B.z} + P
| P6 = to_iso{B.x B.y2 B.z} + P
| P7 = to_iso{B.x B.y B.z} + P
| for A,B [P2,P4 P4,P3 P3,P6 P6,P7 P7,P5 P5,P2 P4,P7]
  | FB.line{Color A B}


draw_bounding_box_back Color FB B =
| ZD = B.z2-B.z
| P = ScreenXY
| P1 = to_iso{B.x2 B.y2 B.z} - [0 ZD] + P
| P2 = to_iso{B.x2 B.y B.z} - [0 ZD] + P
| P3 = to_iso{B.x B.y2 B.z} - [0 ZD] + P
| P5 = to_iso{B.x2 B.y B.z} + P
| P6 = to_iso{B.x B.y2 B.z} + P
| P8 = to_iso{B.x2 B.y2 B.z} + P
| for A,B [P2,P1 P1,P3 P3,P6 P6,P8 P8,P5 P5,P2 P1,P8]
  | FB.line{Color A B}

blit_item_from_unit Me =
| X,Y,Z = $fxyz
| DX,DY = $box_xy
| DDX = (DX+2*DY)/2
| DDY = 2*DY-DDX
| X += DDX
| Y += DDY
| XD,YD,ZD = $size
| when $mirror: swap XD YD
| make_blit_item X Y Z+7 XD YD ZD Me //Z+7 is a hack to avoid cursor cluttering

UnitRects = 0
PickedRects = 0

unit.draw FB B =
| X = B.sx
| Y = B.sy
| G = $frame
| GW = G.w
| XX = X+XUnit2-GW/2
| YY = Y-YUnit2-G.h
| when $mirror:
  | XX -= GW%2
  | G.flop
| S = $sprite
| when S.shadow:
  | S = $world.shadow
  | ZZ = $cell-$floor
  | I = min (ZZ/16).abs S.size-1
  | SGfx = S.I
  | SGfx.brighten{B.brighten}
//  | SGfx.light{B.lx B.ly}
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
//| G.light{B.lx B.ly}
| G.alpha{$alpha}
| FB.blit{XX YY G}
| less $pickable: leave
| RW,RH,RY = $sprite.rect
| RX = X+XUnit2 - RW/2
| RY = Y+RY-RH
| UnitRects.push{[RX RY RW RH],Me}
| less $picked: leave
| PickedRects.push{[RX RY RW RH],Me}

PickCorner = 0

draw_picked_rects FB PickedRects =
| for [RX RY RW RH],Me PickedRects
  //| FB.rectangle{#FFFFFF 0 RX RY RW RH}
  | less PickCorner:
    | PickCorner <= $main.img{ui_picked_corner}
  | PW = PickCorner.w
  | PH = PickCorner.h
  | FB.blit{RX RY PickCorner}
  | FB.blit{RX+RW-PW RY PickCorner.flop}
  | FB.blit{RX RY+RH-PW PickCorner.flip}
  | FB.blit{RX+RW-PW RY+RH-PW PickCorner.flip.flop}
  | HP = $class.hp
  | Health = $health
  | HBar = RW*$health/max{1 $class.hp}
  | FB.rectangle{#00FF00 1 RX RY+RH HBar 4}
  | FB.rectangle{#000000 1 RX+HBar RY+RH RW-HBar 4} 
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
//| leave
| B = BlitItem
| G = B.data
| when B.flags&&&#40: G.dither{1}
| G.brighten{B.brighten}
//| G.light{B.lx B.ly}
| FB.blit{B.sx B.sy G}

type gfx_item

gfx_item.draw FB BlitItem =
| B = BlitItem
| G = B.data
| when B.flags&&&#40: G.dither{1}
| FB.blit{B.sx B.sy G}

type special_blit{what}

special_blit.draw FB BlitItem =
| if $what >< box_front then draw_bounding_box_front #00FF00 FB BlitItem
  else if $what >< box_back then draw_bounding_box_back #FF0000 FB BlitItem
  else

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
  | B = make_blit_item X*CS-2 Y*CS-2 Z*CS CS2 CS2 TH*CS
                       special_blit{box_back}
  | B.sx <= BX
  | B.sy <= BY-GH-ZZ
  | push B BlitItems
  | B = make_blit_item X*CS Y*CS Z*CS+2 CS2 CS2 TH*CS
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
| LXY = (to_iso{X*8 Y*8 0}-to_iso{CurX*8 CurY*8 0}){?float}
| LXY = LXY{?int} ///(LXY*256.0/LXY.abs){?int}
| LX,LY = LXY
| LX = LX.clip{-127 127}
| LY = LY.clip{-127 127}
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
        | B.lx <= LX
        | B.ly <= LY
        | B.brighten <= Br
        | push B BlitItems
    else
| Cell = Wr.cell{X Y 0}
| EndZ = min RoofZ Wr.height{X Y}
| while Z < EndZ:
  | G = Cell.gfx
  | T = Cell.tile
  | TH = T.height
  | Cell += TH
  | ZZ = Z*ZUnit
  | when G.is_list: G <= G.((Wr.cycle/T.anim_wait)%G.size)
  | UnitZ <= Z + TH
  | TZ = UnitZ - 1
  | less T.invisible
    | G = G
    | if AboveCursor or TZ << ZCut then
      else if not DrawnFold then
        | DrawnFold <= 1
        | G <= Folded
      else G <= 0
    | when G and Z>SkipZ:
      | Box = T.box
      | B = make_blit_item X*CS Y*CS Z*CS Box.0 Box.1 Box.2 T
      | B.data <= G
      | B.sx <= BX
      | B.sy <= BY-G.h-ZZ
      | B.lx <= LX
      | B.ly <= LY
      | B.brighten <= Br
      //| B.brighten <= LM.at{X Y Z}
      | when Fog: B.flags <= #40 //dither
      | push B BlitItems
  | Z <= UnitZ

render_unexplored Me Wr X Y BX BY =
| B = make_blit_item X*CS Y*CS 0 CS2 CS2 CS gfx_item{}
| B.data <= Unexplored
| B.sx <= BX
| B.sy <= BY-$zunit-Unexplored.h
| push B BlitItems

// still needs true 3d pipeline interpolate xyz across texture
view_to_z X Y Z = (X+Y+Z)*-256 + Z

view.render_iso =
| Wr = $world
| BlitItems <= []
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
| CS2 <= CS*2
| TX,TY = $blit_origin + [0 YUnit] + [0 Z]*ZUnit
| VX,VY = $view_origin
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
  | when 0<Y and Y<<WH: times XX VS:
    | X = XX + VX
    | when 0<X and X<<WW: // FIXME: move this out of the loop
      | BX = TX + XX*XUnit2 - YY*XUnit2
      | BY = TY + XX*YUnit2 + YY*YUnit2
      | E = Explored.Y.X
      | if E then render_pilar Me Wr X Y BX BY $cursor RoofZ E
        else render_unexplored Me Wr X Y BX BY
| BX = TX + VY + CurX*XUnit2 - CurY*XUnit2
| BY = TY + VY + CurX*YUnit2 + CurY*YUnit2
| when $mice_click<>left or $brush.0:
  | render_cursor Me Wr BX BY $cursor
/*| less BlitItems.end
  | Xs = BlitItems{B=>[(view_to_z B.x B.y B.z+B.z2) B]}
  | Xs <= Xs.sort{A B => A.0>B.0} //could be replaced with z-buffer
  | for X,B Xs
    | O = B.object
    | O.draw{FB B}*/
| less BlitItems.end
  | DrawBoundingBox = $main.params.world.bounding_boxes><1
  | BL = BlitItems.list
  | isort_begin
  | for I,B BL.i: isort_add I 0 B.x B.y B.z B.x2 B.y2 B.z2
  | ResultSize = isort_end
  | Result = isort_result
  | less DrawBoundingBox: for I ResultSize:
      | N = _ffi_get int Result I
      | B = BL.N
      | O = B.object
      | O.draw{FB B}
  | when DrawBoundingBox: for I ResultSize:
      | N = _ffi_get int Result I
      | B = BL.N
      | O = B.object
      | ZD = B.z2-B.z
      | Color = if O.is_unit then #0000FF else #00FF00
      | draw_bounding_box_back Color FB B
      | O.draw{FB B}
      | draw_bounding_box_front Color FB B
  | isort_free_result
| draw_picked_rects FB PickedRects.list.flip
| less $brush.0: $handle_pick{UnitRects.list.flip}
| BlitItems <= 0
| UnitRects <= 0

view.render_frame =
| IsNight = $world.params.night><1
| BrightFactor <= if IsNight then 10 else 0
//| $fb.clear{#929292/*#00A0C0*/}
| $fb.blit{0 0 $main.img{ui_stars}}
| $render_iso
| InfoText = []
| when $param.show_frame: push "frame=[$frame]" InfoText
| when $param.show_cycle: push "cycle=[$world.cycle]" InfoText
| when $param.show_fps: push "fps=[$fps]" InfoText
| $infoText.value <= InfoText.infix{'; '}.text
| $infoText.render.draw{$fb 200 ($h-50)}
| $infoText.value <= ''

// calculates current framerate and adjusts sleeping accordingly
view.calc_fps StartTime FinishTime =
| when $frame%24 >< 0
  | T = StartTime
  | $fps <= @int 24.0/(T - $fpsT)
  | when $fps < $fpsGoal and $fpsD < $fpsGoal.float*2.0: $fpsD += 1.0
  | when $fps > $fpsGoal and $fpsD > $fpsGoal.float/2.0: $fpsD -= 1.0
  | $fpsT <= T
| $frame++
| SleepTime = 1.0/$fpsD - (FinishTime-StartTime)
| when SleepTime > 0.0: get_gui{}.sleep{SleepTime}

view.draw FB X Y =
| $fb <= FB
| GUI = get_gui
| StartTime = GUI.ticks
| $update
| $render_frame
| FinishTime = GUI.ticks
| $calc_fps{StartTime FinishTime}
| $fb <= 0 //no framebuffer outside of view.draw

view.render = Me
