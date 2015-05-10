use gui util widgets heap 


XUnit = No
YUnit = No
ZUnit = No
YDiv = No

type view.widget{M W H}
  main/M
  fb // frame buffer
  w/W
  h/H
  frame
  paused
  keys/(t)
  view_origin/[0 0]
  blit_origin/[W/2 -170]
  mice_click
  mice_xy/[0 0]
  cursor/[1 1 1]
  anchor/[1 1 1]
  brush/[0 0]
  mode/brush
  pick_count // used to pick different units from the same cell
  infoText/txt{small info}
  fps/1
  fpsT/0.0
  fpsGoal/24 // goal frames per second
  fpsD/30.0
  param
  on_unit_pick/(Picked=>)
  view_size/32  // render 32x32 world chunk
| $fb <= gfx W H
| $fpsGoal <= $main.params.ui.fps
| $fpsD <= $fpsGoal.float+8.0
| $param <= $main.params.ui
| Wr = $world
| XUnit <= Wr.xunit
| YUnit <= Wr.yunit
| ZUnit <= Wr.zunit
| YDiv <= YUnit/ZUnit

view.init =
| $fpsT <= clock
| $view_origin.init{-[$h/32 $h/32]+[6 6]}
| $move{$view_origin} //normalize view

view.set_brush NewBrush = $brush.init{NewBrush}

view.world = $main.world

draw_cursor V Front FB X Y H =
| !H*ZUnit
| !Y - H
| !Y - 2
| !Y+YUnit/2
| A = [X Y]
| B = [X+XUnit/2 if Front then Y+YUnit/2 else Y-YUnit/2]
| C = [X+XUnit Y]
| FB.line{V A B}
| FB.line{V B C}
| FB.line{V A+[0 H] B+[0 H]}
| FB.line{V B+[0 H] C+[0 H]}
| FB.line{V A A+[0 H]}
| FB.line{V B B+[0 H]}
| FB.line{V C C+[0 H]}

render_pilar Wr X Y BX BY Heap CursorXYZ RoofZ =
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
| Key = ((X+Y)</40)
| for G Gs
  | T = Wr.tid_map.(Wr.get{X Y Z})
  | TH = T.height
  | ZZ = Z*ZUnit
  | Key = Key + ((Z*2)</30)
  | DrawCursor = Cursor and Z < CursorZ
  | when DrawCursor: Heap.push{Key-1 [G BX BY-YUnit-ZZ #4000+(TH</16)]}
  | UnitZ <= Z + TH
  | TZ = UnitZ - 4
  | less T.invisible
    | when AboveCursor or TZ << CutZ:
      | Heap.push{Key [G BX BY-G.h-ZZ 0]}
  | when DrawCursor: Heap.push{Key+1 [G BX BY-YUnit-ZZ #8000+(TH</16)]}
  | Z <= UnitZ
  | when Z >> RoofZ: _goto for_break
| _label for_break
| for U Wr.column_units_at{X Y}
  | XYZ = U.xyz
  | UX,UY,Z = XYZ
  | TZ = Z-4
  | when TZ < RoofZ and (AboveCursor or TZ << CutZ) and UX><X and UY><Y:
    | DrawShadow = Z > UnitZ
    | U.render{Heap BX BY-ZUnit*Z}
    | when DrawShadow
      | S = Wr.shadows.(2-min{(@abs (Z-UnitZ)/2-2) 2}).3
      | Key = Key + (UnitZ</30) + 1
      | Heap.push{Key [S BX-S.w/2+32 BY-S.h-UnitZ*ZUnit-10 0]}

world.roof XYZ =
| X,Y,Z = XYZ
| while $fast_at{X,Y,Z}.empty and Z < 63: !Z+1
| Z

view.render_iso =
| Wr = $world
| XUnit = XUnit
| YUnit = YUnit
| ZUnit = ZUnit
| FB = $fb
| Z = if $mice_click then $anchor.2 else $cursor.2
| RoofZ = Wr.roof{$cursor}
| BlitOrigin = [$w/2 170]
| TX,TY = $blit_origin+[0 Z]%YDiv*ZUnit + [0 32]
| VX,VY = $view_origin-[Z Z]/YDiv
| Heap = heap
| WW = Wr.w
| WH = Wr.h
| VS = $view_size
| XUnit2 = XUnit/2
| YUnit2 = YUnit/2
| times YY VS
  | Y = YY + VY
  | when 0<Y and Y<<WH: times XX VS:
    | X = XX + VX
    | when 0<X and X<<WW: // FIXME: move this out of the loop
      | BX = XX*XUnit2 - YY*XUnit2
      | BY = XX*YUnit2 + YY*YUnit2
      | render_pilar Wr X Y BX BY Heap $cursor RoofZ
      //| Key = (X+Y)*WW*WH+X
      //| Heap.push{Key [Gs.0 BX BY 0]}
//| Font = font small
//| Order = 0
| while!it Heap.pop:
  | [G BX BY F] = it.value
  | BX = TX + BX
  | BY = TY + BY
  | if F then // check flags
     | when F ^^ #2
       | FB.rect{#00FF00 0 BX BY G.w G.h}
       | !F -- #2
     | if F ^^ #1 then FB.blit{BX,BY G flipX/1}
       else if F ^^ #4000 then draw_cursor{#FF0000 0 FB BX BY F/>16}
       else if F ^^ #8000 then draw_cursor{#00FF00 1 FB BX BY F/>16}
       else FB.blitRaw{BX BY G}
    else FB.blitRaw{BX BY G}
  //| Font.draw{FB [BX+18 BY+4] "[Order]"}
  //| !Order+1

Indicators = 0

view.draw_indicators =
| less Indicators: Indicators <= $main.img{ui_indicators}
| X,Y,Z = $cursor
| IP = [($w-Indicators.w)/2 0]
| $fb.blit{IP Indicators}
| Font = font medium
| P = $world.player
| Font.draw{$fb IP+[28 1] "[P.mana]+[P.power]"}
| Font.draw{$fb IP+[148 1] "[$world.turn]:[P.id]:[P.moves]"}
| Font.draw{$fb IP+[148 16] "[P.name]"}
| Font = font small
| Font.draw{$fb IP+[246 1] "[X],[Y],[Z]"}
| Font.draw{$fb IP+[246 9] "[$world.at{X,Y,Z-1}.type]"}

view.render_frame =
| $fb.clear{#929292/*#00A0C0*/}
| $render_iso
| /*when $mode >< play:*/ $draw_indicators
| InfoText = []
| when $param.show_frame: push "frame=[$frame]" InfoText
| when $param.show_cycle: push "cycle=[$world.cycle]" InfoText
| when $param.show_fps: push "fps=[$fps]" InfoText
| $infoText.value <= InfoText.infix{'; '}.text
| $infoText.draw{$fb 4,($h-10)}
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

view.render =
| GUI = get_gui
| StartTime = GUI.ticks
| $update
| $render_frame
| FinishTime = GUI.ticks
| $calc_fps{StartTime FinishTime}
| $fb

view.worldToView P =
| [X Y] = P - $view_origin
| RX = (X*XUnit - Y*XUnit)/2
| RY = (X*YUnit + Y*YUnit)/2
| [RX RY] + $blit_origin

view.viewToWorld P =
| [X Y] = P - $blit_origin - [0 $main.params.world.z_unit*4]
| !X - 32
| WH = XUnit*YUnit
| RX = (Y*XUnit + X*YUnit)/WH
| RY = (Y*XUnit - X*YUnit)/WH
| [RX RY] = [RX RY] + $view_origin
| [RX.clip{1 $world.w} RY.clip{1 $world.h}]

view.mice_rect =
| [AX AY] = if $anchor then $anchor else $mice_xy
| [BX BY] = $mice_xy
| X = min AX BX
| Y = min AY BY
| U = max AX BX
| V = max AY BY
| [X Y U-X V-Y]

view.move NewXY =
| $view_origin.init{NewXY}
//| [X Y] = NewXY
//| $view_origin.init{[X.clip{0 $world.w-1} Y.clip{0 $world.h-1}]}

view.center_at XY = $move{XY*32-[$w $h]/2}

world.update_pick Units =
| for U $picked^uncons{picked}: U.picked <= 0
| $picked <= Units^cons{picked}

view.select_unit XYZ = 
| Picked = []
| Us = $world.units_at{XYZ}.skip{?aux}
| when Us.size
  | !$pick_count+1
  | Picked <= [Us.($pick_count%Us.size)]
| $world.update_pick{Picked}

view.update_pick XYZ =
| when $mice_click >< left: $select_unit{$cursor}
| $mice_click <= 0
  // FIXME: following line is outdated
| $main.update //ensures deleted units get updated

view.update_brush = 
| $cursor.2 <= $fix_z{$cursor}
| X,Y,Z = $cursor
| when $mice_click><left: case $brush
  [obj Bank,Type]
    | Mirror = $keys.m >< 1
    | ClassName = if $keys.r >< 1
                  then "[Bank]_[$main.classes_banks.Bank.rand]"
                  else "[Bank]_[Type]"
    | Class = $main.classes.ClassName
    | Place = 1
    | for XX,YY,ZZ Class.form: when Place:
      | XYZ = [X Y Z] + if Mirror then [-YY XX ZZ] else [XX -YY ZZ]
      | Us = $world.units_at{XYZ}
      | Place <= if XYZ.any{?<0} then 0
                 else if Class.unit then Us.all{?empty}
                 else if $keys.r >< 1 then Us.end
                 else not Us.any{?class^address >< Class^address}
    | when Place
      | U = $world.alloc_unit{ClassName}
      | U.pick_facing{if Mirror then 5 else 3}
      | when $keys.t >< 1: U.facing <= 3.rand
      | U.move{X,Y,Z}
  [tile Type]
    | while 1
      | Z <= $cursor.2
      | less Z << $anchor.2 and $world.fast_at{X,Y,Z}.empty: leave
      | Tile = $main.tiles.Type
      | less Tile.empty
        | for U $world.units_at{X,Y,Z}: U.move{X,Y,Z+Tile.height}
      | $world.set{X Y Z $main.tiles.Type}
      | when Tile.empty and (Tile.id><0 or $keys.e<>1): leave
      | $cursor.2 <= $fix_z{$cursor}
| when $mice_click><right: case $brush
  [obj Type] | for U $world.units_at{X,Y,Z}.skip{?mark}: U.free
  [tile Type]
    | while 1
      | Z <= $cursor.2
      | less Z >> $anchor.2 and Z > 1: leave
      | less Z > 1: leave
      | Tile = $world.at{X,Y,Z-1}
      | less Tile.height: leave
      | $world.clear_tile{X,Y,Z-1}
      | for U $world.units_at{X,Y,Z}: U.move{X,Y,Z-Tile.height}
      | $cursor.2 <= $fix_z{$cursor}

view.update_play =
| Player = $world.player
| if not $world.picked.idle or $world.waiting then
  else if not Player.human then Player.ai.update
  else if Player.moves << 0 then $world.end_turn
  else
  | case $mice_click
    left | $select_unit{$cursor}
    right | when $world.picked: $world.picked.guess_order_at{$cursor}
  | $mice_click <= 0
  | Picked = $world.picked
  | less Picked: Picked <= $world.nil
  | $on_unit_pick{}{Picked}
| $main.update

world.update_picked = 
| SanitizedPicked = $picked^uncons{picked}.skip{?removed}
| $picked <= [$nil @SanitizedPicked]^cons{picked}
| for M $marks^uncons{mark}: M.free
| $marks <= $nil
| Picked = $picked
| less Picked and Picked.moves and Picked.moved<$turn and $player.moves > 0:
  | Picked <= 0
| when Picked and Picked.picked and Picked.action.class_name >< idle:
  | $marks <= [$nil @Picked.mark_moves]^cons{mark}

world.update_cursor CXYZ Brush Mirror =
| Marks = $marks^uncons{mark}.flip
| push $alloc_unit{mark_cursor0}.move{CXYZ} Marks
| push $alloc_unit{mark_cursor1}.move{CXYZ} Marks
| case Brush
  [obj Bank,Type]
    | ClassName = "[Bank]_[Type]"
    | Class = $main.classes.ClassName
    | for X,Y,Z Class.form:
      | XYZ = CXYZ + if Mirror then [-Y X Z] else [X -Y Z]
      | Us = XYZ.0 >> 0 and XYZ.1 >> 0 and $units_at{XYZ}
      | Place = if not Us then 0
                else if Class.unit then not Us.any{?unit}
                else not Us.any{?class^address >< Class^address}
      | when Place: push $alloc_unit{mark_cube}.move{XYZ} Marks
| $marks <= Marks.flip^cons{mark}

view.update =
| when $paused: leave
| case $keys.up 1: $move{$view_origin-[1 1]}
| case $keys.down 1: $move{$view_origin+[1 1]}
| case $keys.left 1: $move{$view_origin-[1 -1]}
| case $keys.right 1: $move{$view_origin+[1 -1]}
| X,Y,Z = $cursor
| $world.update_picked
| Brush = if $mode >< brush then $brush else 0
| Mirror = $keys.m >< 1
| $world.update_cursor{$cursor Brush Mirror}
| case $mode
    play | $update_play
    brush | $update_brush
    pick | $update_pick{X Y Z}
    Else | bad "bad view mode ([$mode])"
| 1

view.fix_z XYZ =
| if $keys.e><1 then $world.fix_z_void{XYZ} else $world.fix_z{XYZ}

view.input In =
//| when $paused: leave
| case In
  [mice_move _ XY]
    | !XY+[0 32]
    | $mice_xy.init{XY}
    | CX,CY = $viewToWorld{$mice_xy}
    | $cursor.init{[CX CY $cursor.2]}
    | $cursor.2 <= $fix_z{$cursor}
  [mice left State XY]
    | $mice_click <= if State then \left else 0
    | if State then $anchor.init{$cursor} else $cursor.2 <= $fix_z{$cursor}
  [mice right State XY]
    | $mice_click <= if State then \right else 0
    | if State then $anchor.init{$cursor} else $cursor.2 <= $fix_z{$cursor}
  [key Name S] | $keys.Name <= S

view.pause = $paused <= 1
view.unpause = $paused <= 0

view.wants_focus = 1

export view
