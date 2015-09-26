use gfx gui util widgets action macros isort_

ScreenXY = [0 0]
BrightFactor = 0
YDiv = No

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



unit.size = [37 37 70]

blit_item_from_unit U =
| X,Y,Z = U.xyz
| !X*32
| !Y*32
| !Z*8
| DX,DY = U.xy
| DDX = (DX+2*DY)/2
| DDY = 2*DY-DDX
| !X+DDX
| !Y+DDY
| XD,YD,ZD = U.size
| when U.mirror: swap XD YD
| make_blit_item X Y Z XD YD ZD U

unit.draw FB B =
| X = B.sx
| Y = B.sy
| G = $frame
| !X + $xy.0
| !Y + $xy.1
| XX = X+32-G.w/2
| YY = Y-16-G.h+$slope*16
| when $mirror: G.flop
| G.light{B.lx B.ly}
| when $sprite.shadow:
  | S = $world.shadow
  | ZZ = $xyz.2-$fix_z
  | I = min (ZZ/4).abs S.size-1
  | SGfx = S.I
  | ShadowDO = $draw_order-(ZZ</4)
  | FB.blit{X+8 Y-38+ZZ*8 SGfx.z{ShadowDO}}
| when $flyer
  | !YY-16
  | !Y-16
| G.brighten{$brighten}
| G.alpha{$alpha}
| FB.blit{XX YY G.z{$draw_order}}
| when $picked and $world.player.id >< $owner.id:
  | Wave = @int 20.0*(@sin: ($world.cycle%100).float/100.0*PI)
  | Mark = $main.img{ui_picked_mark}
  | PH = $sprite.pick_height
  | less PH: PH <= $height*8+16
  | PH <= PH + Mark.h + Wave
  | XX = X+32-Mark.w/2
  | YY = Y-PH
  | FB.blit{XX YY Mark.z{$draw_order}}
  | Icons = []
  | when $shell: push 2 Icons
  | when $poison: push 4 Icons
  | when $haste: push 5 Icons
  | when Icons.size
    | XX <= XX - Icons.size*8 + Mark.w/2
    | !YY-16
    | Fs = $main.effect.frames
    | for I Icons
      | F = Fs.I
      | FB.blit{XX YY F.z{$draw_order}}
      | !XX+16

tile.draw FB BlitItem =
| B = BlitItem
| G = B.data
| when B.flags^^#40: G.dither{1}
| G.light{B.lx B.ly}
| FB.blit{B.sx B.sy G}

type gfx_item

gfx_item.draw FB BlitItem =
| B = BlitItem
| G = B.data
| when B.flags^^#40: G.dither{1}
| FB.blit{B.sx B.sy G}

type special_blit{what}

special_blit.draw FB BlitItem =
| if $what >< box_front then draw_bounding_box_front #00FF00 FB BlitItem
  else if $what >< box_back then draw_bounding_box_back #FF0000 FB BlitItem
  else

Folded = 0
BlitItems = 0

render_pilar Me Wr X Y BX BY FB CursorXYZ RoofZ Explored =
| DrawnFold = 0
| less Folded: Folded <= Wr.main.img{ui_folded}
| Gs = Wr.gfxes.Y.X
| CurX = CursorXYZ.0
| CurY = CursorXYZ.1
| CursorZ = CursorXYZ.2
| CurH = (CurX+CurY)/2
| XY2 = (X+Y)/2
| AboveCursor = CurH >> XY2
| CurHH = YDiv*(XY2-CurH-2)+3
| CutZ = max CursorZ CurHH
| Cursor = same X CurX and Y >< CurY
| Z = 0
| UnitZ = 0
| Fog = Explored><1
| Br = @int -([CurX CurY]-[X Y]).abs
| !Br*BrightFactor
| LXY = (to_iso{X*8 Y*8 0}-to_iso{CurX*8 CurY*8 0}){?float}
| LXY = LXY{?int} ///(LXY*256.0/LXY.abs){?int}
| LX,LY = LXY
| LX = LX.clip{-127 127}
| LY = LY.clip{-127 127}
| for G Gs
  | T = Wr.tid_map.(Wr.get{X Y Z})
  | TH = T.height
  | ZZ = Z*$zunit
  | DrawCursor = Cursor and Z < CursorZ
  | when G.is_list: G <= G.((Wr.cycle/T.anim_wait)%G.size)
  | when DrawCursor:
    | B = make_blit_item X*32-2 Y*32-2 Z*8 64 64 T.height*8
                        special_blit{box_back}
    | B.sx <= BX
    | B.sy <= BY-G.h-ZZ
    | push B BlitItems
  | UnitZ <= Z + TH
  | TZ = UnitZ - 4
  | less T.invisible
    | G = G
    | if AboveCursor or TZ << CutZ then
      else if not DrawnFold then
        | DrawnFold <= 1
        | G <= Folded
      else G <= 0
    | when G
      | B = make_blit_item X*32 Y*32 Z*8 64 64 T.height*8 T
      | B.data <= G
      | B.sx <= BX
      | B.sy <= BY-G.h-ZZ
      | B.lx <= LX
      | B.ly <= LY
      | B.brighten <= Br
      | when Fog: B.flags <= #40 //dither
      | push B BlitItems
  | when DrawCursor:
    | B = make_blit_item X*32 Y*32 Z*8+2 64 64 T.height*8
          special_blit{box_front}
    | B.sx <= BX
    | B.sy <= BY-G.h-ZZ
    | push B BlitItems
  | Z <= UnitZ
  | when Z >> RoofZ: _goto for_break
| _label for_break
| Us = Wr.column_units_at{X Y}
| when Fog: Us <= Us.skip{(?owner.id or ?health or ?bank><effect)}
//| draw_text FB BX+32 BY-$zunit*Z-20 "[Explored]"
| for U Us: when U.frame.w > 1:
  | XYZ = U.xyz
  | UX,UY,Z = XYZ
  | TZ = Z-4
  | when TZ < RoofZ and (AboveCursor or TZ << CutZ) and UX><X and UY><Y:
    | B = blit_item_from_unit U
    | B.sx <= BX
    | B.sy <= BY-$zunit*Z
    | B.lx <= LX
    | B.ly <= LY
    | B.brighten <= Br
    | push B BlitItems

Unexplored = 0

render_unexplored Me Wr X Y BX BY FB =
| less Unexplored: Unexplored <= Wr.main.img{ui_unexplored}
/*| Key = (((max X Y))</24) + ((X*128+Y)</10)
| FB.blit{BX BY-$zunit-Unexplored.h Unexplored.z{Key}}*/

view.render_iso =
| Wr = $world
| BlitItems <= []
| Explored = Wr.human.sight
| FB = $fb
| Z = if $mice_click then $anchor.2 else $cursor.2
| RoofZ = Wr.roof{$cursor}
| YDiv <= $yunit/$zunit
| TX,TY = $blit_origin+[0 Z]%YDiv*$zunit + [0 32]
| VX,VY = $view_origin-[Z Z]/YDiv
| ScreenXY.init{[TX+32 TY]+to_iso{-VX*32 -VY*32 0}}
| WW = Wr.w
| WH = Wr.h
| VS = $view_size
| XUnit2 = $xunit/2
| YUnit2 = $yunit/2
| times YY VS
  | Y = YY + VY
  | when 0<Y and Y<<WH: times XX VS:
    | X = XX + VX
    | when 0<X and X<<WW: // FIXME: move this out of the loop
      | BX = TX + XX*XUnit2 - YY*XUnit2
      | BY = TY + XX*YUnit2 + YY*YUnit2
      | E = Explored.Y.X
      | if E then render_pilar Me Wr X Y BX BY FB $cursor RoofZ E
        else render_unexplored Me Wr X Y BX BY FB
| less BlitItems.end
  | DrawBoundingBox = $main.params.world.bounding_boxes
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
  | BBP = ScreenXY+[0 -2]
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
| BlitItems <= 0


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


Indicators = 0

view.draw_indicators =
| less Indicators: Indicators <= $main.img{ui_indicators}
| IX = ($w-Indicators.w)/2
| IY = 0
| P = $world.player
| Font = font medium
| when $mode <> play: !IX + 80
| less P.human or $mode <> play:
  | Font.draw{$fb IX+148 IY+16 "[P.name]"}
  | leave
| X,Y,Z = $cursor
| $fb.blit{IX IY Indicators}
| Font.draw{$fb IX+28 IY+1 "[P.mana]+[P.income-P.upkeep]-[-P.upkeep]"}
| Font.draw{$fb IX+148 IY+1 "[$world.turn]:[P.id]"}
| Font.draw{$fb IX+148 IY+16 "[P.name]"}
| Debug = $world.params.debug
| when got Debug: Font.draw{$fb IX+148 IY+32 "[Debug]"}
| C = 32
| Notes = $world.notes
| Clock = clock
| for [Expires Chars] $world.notes: when Clock < Expires:
  | Font.draw{$fb IX-16 IY+C "* [Chars.text]"}
  | !C+16
| Font = font small
| Font.draw{$fb IX+246 IY+1 "[X],[Y],[Z]"}
| Font.draw{$fb IX+246 IY+9 "[$world.at{X,Y,Z-1}.type]"}

view.render_frame =
| IsNight = $world.params.night><1
| BrightFactor <= if IsNight then 10 else 0
//| $fb.clear{#929292/*#00A0C0*/}
| $fb.blit{0 0 $main.img{ui_stars}}
| $render_iso
| /*when $mode >< play:*/ $draw_indicators
| InfoText = []
| when $param.show_frame: push "frame=[$frame]" InfoText
| when $param.show_cycle: push "cycle=[$world.cycle]" InfoText
| when $param.show_fps: push "fps=[$fps]" InfoText
| $infoText.value <= InfoText.infix{'; '}.text
| $infoText.draw{$fb 4 ($h-10)}
| $infoText.value <= ''

// calculates current framerate and adjusts sleeping accordingly
view.calc_fps StartTime FinishTime =
| when $frame%24 >< 0
  | T = StartTime
  | $fps <= @int 24.0/(T - $fpsT)
  | when $fps < $fpsGoal and $fpsD < $fpsGoal.float*2.0: !$fpsD+1.0
  | when $fps > $fpsGoal and $fpsD > $fpsGoal.float/2.0: !$fpsD-1.0
  | $fpsT <= T
| !$frame + 1
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
