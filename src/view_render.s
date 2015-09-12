use gfx gui util widgets action

BrightFactor = 0
YDiv = No

cursor_draw_back Me FB X Y Z Height =
| Bar = $main.img{mark_cell_red_bar}
| Corner = $main.img{mark_cell_red_corner}
| !Y-2
| !Y+($zunit*2)
| FB.blit{X Y-16 Corner.z{Z}}
| !Y-(Height*$zunit)
| FB.blit{X Y-16 Corner.z{Z}}
| for I Height:
  | YY = Y+I*$zunit
  | FB.blit{X+32 YY-16 Bar.z{Z}}

cursor_draw_front Me FB X Y Z Height =
| Bar = $main.img{mark_cell_green_bar}
| Corner = $main.img{mark_cell_green_corner}
| !Y+($zunit*2)
| !Y-2
| FB.blit{X Y Corner.z{Z}}
| !Y-(Height*$zunit)
| FB.blit{X Y Corner.z{Z}}
| for I Height:
  | YY = Y+I*$zunit
  | FB.blit{X YY Bar.z{Z}}
  | FB.blit{X+64 YY Bar.z{Z}}
  | FB.blit{X+32 YY+16 Bar.z{Z}}

draw_text FB X Y Msg =
| Font = font small
| ZB = FB.zbuffer
| FB.zbuffer <= 0
| Font.draw{FB X Y Msg}
| FB.zbuffer <= ZB

Folded = 0

render_pilar Me Wr X Y BX BY FB CursorXYZ RoofZ Explored =
| DrawnFold = 0
| less Folded: Folded <= Wr.main.img{ui_folded}
| VisibleUnits = []
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
| Key = (((max X Y))</24) + ((X*128+Y)</10)
| Fog = Explored><1
| Br = @int -([CurX CurY]-[X Y]).abs
| !Br*BrightFactor
| for G Gs
  | T = Wr.tid_map.(Wr.get{X Y Z})
  | TH = T.height
  | ZZ = Z*$zunit
  | Key = Key + (Z</4)
  | DrawCursor = Cursor and Z < CursorZ
  | when DrawCursor:
    | cursor_draw_back Wr FB BX BY-$yunit-ZZ Key TH
  | UnitZ <= Z + TH
  | TZ = UnitZ - 4
  | less T.invisible
    | if AboveCursor or TZ << CutZ then
        | when G.is_list:
          | G <= G.((Wr.cycle/T.anim_wait)%G.size)
        | when Fog: G.dither{1}
        | when Br: G.brighten{Br}
        | FB.blit{BX BY-G.h-ZZ G.z{Key}}
      else less DrawnFold:
        | DrawnFold <= 1
        | G = Folded
        | when Fog: G.dither{1}
        | when Br: G.brighten{Br}
        | FB.blit{BX BY-G.h-ZZ G.z{Key}}
        | FB.blit{BX BY-G.h-ZZ G.z{Key}}
  | when DrawCursor:
    | cursor_draw_front Wr FB BX BY-$yunit-ZZ Key TH
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
    | U.brighten <= Br
    | push [U BX BY-$zunit*Z] VisibleUnits
| VisibleUnits

Unexplored = 0

render_unexplored Me Wr X Y BX BY FB =
| less Unexplored: Unexplored <= Wr.main.img{ui_unexplored}
| Key = (((max X Y))</24) + ((X*128+Y)</10)
| FB.blit{BX BY-$zunit-Unexplored.h Unexplored.z{Key}}

view.render_iso =
| Wr = $world
| VisibleUnits = []
| Explored = Wr.human.sight
| FB = $fb
| FB.zbuffer <= $zbuffer
| ffi_memset $zbuffer 0 4*FB.w*FB.h
| Z = if $mice_click then $anchor.2 else $cursor.2
| RoofZ = Wr.roof{$cursor}
| BlitOrigin = [$w/2 170]
| YDiv <= $yunit/$zunit
| TX,TY = $blit_origin+[0 Z]%YDiv*$zunit + [0 32]
| VX,VY = $view_origin-[Z Z]/YDiv
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
      | if E then
          | VUs = render_pilar Me Wr X Y BX BY FB $cursor RoofZ E
          | when VUs.size: push VUs VisibleUnits
        else render_unexplored Me Wr X Y BX BY FB
| for Us VisibleUnits: for U,BX,BY Us: U.draw{FB BX BY}
| FB.zbuffer <= 0

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
