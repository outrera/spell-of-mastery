use gfx gui util widgets macros isort_ unit_flags stack

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
| !X+DDX
| !Y+DDY
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
| XX = X+32-GW/2
| YY = Y-16-G.h
| when $mirror:
  | !XX - GW%2
  | G.flop
| S = $sprite
| when S.shadow:
  | S = $world.shadow
  | ZZ = $xyz.2-$fix_z
  | I = min (ZZ/4).abs S.size-1
  | SGfx = S.I
  | SGfx.brighten{B.brighten}
//  | SGfx.light{B.lx B.ly}
  | FB.blit{X+8 Y-38+ZZ*8 SGfx}
| Colors = $colors
| when Colors:
  | Rs = S.colors
  | when Rs:
    | CM = G.cmap{raw/1}
    | for I 5:
      | R = Rs.I
      | when got R: _ffi_set uint32_t CM R Colors.I
| when $flyer
  | !YY-16
  | !Y-16
| G.brighten{B.brighten}
//| G.light{B.lx B.ly}
| G.alpha{$alpha}
| FB.blit{XX YY G}
| less $pickable: leave
| RW,RH,RY = $sprite.rect
| RX = X+32 - RW/2
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
  | HBar = RW*$health/$class.hp
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
      | !XX+16

tile.draw FB BlitItem =
//| leave
| B = BlitItem
| G = B.data
| when B.flags^^#40: G.dither{1}
| G.brighten{B.brighten}
//| G.light{B.lx B.ly}
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

render_cursor Me Wr BX BY CursorXYZ =
| X,Y,CurZ = CursorXYZ
| Gs = Wr.gfxes.Y.X
| Z = 0
| UnitZ = 0
| for G Gs
  | T = Wr.at{X Y Z}
  | TH = T.height
  | when G.is_list: G <= G.((Wr.cycle/T.anim_wait)%G.size)
  | UnitZ <= Z + TH
  | TH = T.height
  | ZZ = Z*$zunit
  | B = make_blit_item X*32-2 Y*32-2 Z*8 64 64 TH*8
                       special_blit{box_back}
  | B.sx <= BX
  | B.sy <= BY-G.h-ZZ
  | push B BlitItems
  | B = make_blit_item X*32 Y*32 Z*8+2 64 64 TH*8
                       special_blit{box_front}
  | B.sx <= BX
  | B.sy <= BY-G.h-ZZ
  | push B BlitItems
  | Z <= UnitZ
  | when Z>>CurZ: _goto for_break
| _label for_break

XUnit2 =
YUnit2 =

render_pilar Me Wr X Y BX BY CursorXYZ RoofZ Explored =
| DrawnFold = 0
| less Folded: Folded <= Wr.main.img{ui_folded}
| Gs = Wr.gfxes.Y.X
| CurX,CurY,CurZ = CursorXYZ
| CurH = (CurX+CurY)/2
| XY2 = (X+Y)/2
| AboveCursor = CurH >> XY2
| CurHH = YDiv*(XY2-CurH-2)+3
| ZCut = max CurZ CurHH
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
| SkipZ = -1//if $mode<>play then -1 else 0
| for G Gs
  | T = Wr.at{X Y Z}
  | TH = T.height
  | ZZ = Z*$zunit
  | when G.is_list: G <= G.((Wr.cycle/T.anim_wait)%G.size)
  | UnitZ <= Z + TH
  | TZ = UnitZ - 4
  | less T.invisible
    | G = G
    | if AboveCursor or TZ << ZCut then
      else if not DrawnFold then
        | DrawnFold <= 1
        | G <= Folded
      else G <= 0
    | when G and Z>SkipZ:
      | Box = T.box
      | B = make_blit_item X*32 Y*32 Z*8 Box.0 Box.1 Box.2 T
      | B.data <= G
      | B.sx <= BX
      | B.sy <= BY-G.h-ZZ
      | B.lx <= LX
      | B.ly <= LY
      | B.brighten <= Br
      | when Fog: B.flags <= #40 //dither
      | push B BlitItems
  | Z <= UnitZ
  | when Z >> RoofZ: _goto for_break
| _label for_break
| Us = Wr.column_units_at{X Y}
| when Fog: Us <= Us.skip{(?owner.id or ?class.hp or ?bank><effect)}
//| draw_text FB BX+32 BY-$zunit*Z-20 "[Explored]"
| for U Us:
  | when no U.frame:
    | say U.type
  | when U.frame.w > 1:
    | XYZ = U.xyz
    | UX,UY,Z = XYZ
    | TZ = Z-4
    | when TZ < RoofZ and (AboveCursor or TZ << ZCut) and UX><X and UY><Y:
      | when not U.invisible or U.owner.id><$player.id or $mode<>play:
        | B = blit_item_from_unit U
        | FX,FY,FZ = U.fxyz
        | BX,BY = ScreenXY + to_iso{FX FY FZ}
        | B.sx <= BX - 32
        | B.sy <= BY
        | B.lx <= LX
        | B.ly <= LY
        | B.brighten <= Br
        | push B BlitItems

Unexplored = 0

render_unexplored Me Wr X Y BX BY =
| less Unexplored: Unexplored <= Wr.main.img{ui_unexplored}
| B = make_blit_item X*32 Y*32 0 64 64 4*8 gfx_item{}
| B.data <= Unexplored
| B.sx <= BX
| B.sy <= BY-$zunit-Unexplored.h
| push B BlitItems


point_in_rect [RX RY RW RH] [X Y] = RX<<X and X<RX+RW and RY<<Y and Y<RY+RH
rects_intersect [AX AY AW AH] [BX BY BW BH] =
| AX<BX+BW and AY<BY+BH and BX<AX+AW and BY<AY+AH

PickCount = 0

order_at Me XYZ Target =
| Player = $player
| Us = $picked.keep{U => U.owner.id >< Player.id}
| when Us.size: $world.effect{XYZ ack}
| Us = Us{U=>[(XYZ-U.xyz).abs U]}.sort{?0<??0}{?1}
| Used = []
| less Target and Target.owner.is_enemy{Player}: Target <= 0
| for U Us:
  | P = XYZ
  | less Target: less Used.end:
    | Found = $world.pathfind{1000 U XYZ | Dst => no Used.find{Dst.xyz}}
    | when Found: P <= Found.1
  | U.backtrack <= 0
  | U.order_at{P}
  | push P Used

order_act Me Act XYZ Target =
| $order_at{XYZ}
| $goal_act <= Act
| when Target:
  | $goal <= Target
  | $goal_serial <= Target.serial

handle_picked Me Rect Units = //Me is view
| $ui.on_unit_pick{$picked}
| Units = Units.keep{?seen}
| Act = $world.act
| when Act:
  | when $picked.end:
    | $world.act <= 0
    | leave
  | Affects = Act.affects
  | Outdoor = 0
  | NonLeader = 0
  | when Affects.is_list and Affects.0.is_list:
    | Ms = Affects.0
    | Affects <= Affects.1
    | for Mod Ms
      | if Mod >< outdoor then Outdoor <= 1
        else if Mod >< non_leader then NonLeader <= 1
        else
  | less $mice_click><pick:
    | when Affects><unit:
      | Cur = if Units.end then \ui_cursor_target else \ui_cursor_target2
      | get_gui{}.cursor <= $main.img{Cur}
    | leave
  | $mice_click <= 0
  | when Affects><unit and Units.end: leave
  | $world.act <= 0
  | Target = if Units.end then 0 else Units.0
  | XYZ = if Target and Affects><unit then Target.xyz else $cursor
  | Proceed = 1
  | when Outdoor and not $world.outdoor{XYZ}:
    | $player.notify{"Target should be outdoors."}
    | $main.sound{illegal}
    | Proceed <= 0
  | when NonLeader and Target and Target.leader><1:
    | $player.notify{"Cant target leader."}
    | $main.sound{illegal}
    | Proceed <= 0
  | when Proceed:
    | Blink = 1
    | for U $picked
      | when $world.seen{@XYZ.take{2}}:
        | when Target and Blink:
          | $world.blink.init{[4 Target]}
          | Blink <= 0
        | order_act U Act XYZ Target
  | leave
| get_gui{}.cursor <= $main.img{ui_cursor_point}
| less $mice_click:
  | less Units.end:
    | get_gui{}.cursor <= $main.img{ui_cursor_glass}
    //| $on_unit_pick{}{[Units.0]}
  | leave
| when $mice_click >< left: leave
| when $mice_click >< order:
  | $mice_click <= 0
  | XYZ = $cursor
  | if Units.end then order_at Me $cursor 0
    else | U = Units.0
         | $world.blink.init{[4 U]}
         | order_at Me U.xyz U
  | leave
| when $mice_click >< pick:
  | $mice_click <= 0
  | Shift = $keys.lshift><1 or $keys.rshift><1
  | Picked = if Shift then $picked.list else []
  | NewPicked = Units
  | when Rect:
    | $picked <= [@NewPicked @Picked]
    | leave
  | when NewPicked.size>1:
    | NewPicked <= [NewPicked.(PickCount%NewPicked.size)]
    | !PickCount+1
  | less NewPicked.end: $main.sound{ui_click}
  | $picked <= [@NewPicked @Picked]
  | leave

handle_picking Me UnitRects =
| MR = $mice_rect
| RX,RY,RW,RH = MR
| LargeEnough = RW>4 or RH>4
| when LargeEnough:
  | when $mice_click><left: $fb.rectangle{#00FF00 0 RX RY RW RH}
  | Units = []
  | for UnitRect,Unit UnitRects: when rects_intersect UnitRect MR:
    | when Unit.speed>0 and Unit.owner.id><$player.id:
      | push Unit Units
  | handle_picked Me 1 Units
  | leave
| Units = []
| MXY = $mice_xy
| for UnitRect,Unit UnitRects: when point_in_rect UnitRect MXY:
  | when not Unit.invisible or Unit.owner.id><$player.id:
    | push Unit Units
| handle_picked Me 0 Units 

world_to_view P =
| X,Y,Z = P
| RX = X - Y
| RY = (X + Y)/2
| [RX RY Z]

// still needs true 3d pipeline interpolate xyz across texture
view_to_z X Y Z =
| (X+Y+Z)*-256 + Z

draw_tile32x32 FB XY =
| A = XY+|world_to_view [0 0 0]
| B = XY+|world_to_view [0 32 0]
| C = XY+|world_to_view [32 32 0]
| D = XY+|world_to_view [32 0 0]
| FB.line{#00FF00 A B}
| FB.line{#00FF00 B C}
| FB.line{#00FF00 C D}
| FB.line{#00FF00 D A}

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
| YDiv <= $yunit/$zunit
| TX,TY = $blit_origin+[0 Z]%YDiv*$zunit + [0 32]
| VX,VY = $view_origin-[Z Z]/YDiv
| ScreenXY.init{[TX+32 TY]+to_iso{-VX*32 -VY*32 0}}
| WW = Wr.w
| WH = Wr.h
| VS = $view_size
| XUnit2 <= $xunit/2
| YUnit2 <= $yunit/2
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
| when $mice_click<>left or $mode<>play:
  | render_cursor Me Wr BX BY $cursor
/*| less BlitItems.end
  | Xs = BlitItems{B=>[(view_to_z B.x B.y B.z+B.z2) B]}
  | Xs <= Xs.sort{A B => A.0>B.0} //could be replaced with z-buffer
  | for X,B Xs
    | O = B.object
    | O.draw{FB B}*/
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
| when $mode><play: handle_picking Me UnitRects.list.flip
| BlitItems <= 0
| UnitRects <= 0



Indicators = 0

view.draw_indicators =
| less Indicators: Indicators <= $main.img{ui_indicators}
| IX = ($w-Indicators.w)/2
| IY = 0
| P = $player
| Font = font medium
| when $mode <> play: !IX + 80
| X,Y,Z = $cursor
| $fb.blit{IX IY Indicators}
| Font.draw{$fb IX+36 IY+2 "[P.mana]"}
| Font.draw{$fb IX+148 IY+2 "[P.lore]"}
| Debug = $world.params.debug
| when got Debug: Font.draw{$fb IX+148 IY+32 "[Debug]"}
| C = 34
| Notes = $world.notes
| Clock = clock
| for [Expires Chars] $world.notes: when Clock < Expires:
  | Font.draw{$fb 150 IY+C "* [Chars.text]"}
  | !C+16
| Font = font small
| Font.draw{$fb IX+210 IY+2 "[X],[Y],[Z]:[$world.at{X Y Z-1}.type]"}

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
| $infoText.render.draw{$fb 200 ($h-10)}
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
