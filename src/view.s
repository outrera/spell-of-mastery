use gui util widgets heap action


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
  pick_count // used to pick different units from the same cell
  infoText/txt{small info}
  fps/1
  fpsT/0.0
  fpsGoal/24 // goal frames per second
  fpsD/30.0
  param
  on_unit_pick/(Picked=>)
  view_size/32  // render 32x32 world chunk
  center/[0 0 0]
  zfix/1
| $fb <= gfx W H
| $fpsGoal <= $main.params.ui.fps
| $fpsD <= $fpsGoal.float+8.0
| $param <= $main.params.ui
| Wr = $world
| Wr.view <= Me
| XUnit <= Wr.xunit
| YUnit <= Wr.yunit
| ZUnit <= Wr.zunit
| YDiv <= YUnit/ZUnit
| $fpsT <= clock

view.mode = $world.mode
view.`!mode` V = $world.mode <= V

view.clear =
| $zfix <= 1
| $center_at{[0 0 0]}
| $blit_origin.init{[$w/2 -170]}
| $mice_xy.init{[0 0]}
| $cursor.init{[1 1 1]}
| $anchor.init{[1 1 1]}
| $pick_count <= 0
| Leader = $world.player.units.find{?leader}
| when got Leader: $center_at{Leader.xyz}

view.center_at XYZ cursor/0 =
| X,Y,Z = XYZ
| X = X.clip{1 $world.w}
| Y = Y.clip{1 $world.h}
| Z = Z.clip{1 64}
| $center.init{X,Y,Z}
| when Cursor: $cursor.init{X,Y,Z}
| VO = -[$h/32 $h/32]+[X Y]-[Z/8 Z/8]+[6 6]
| when Z > 31: !VO+[2 2] //hack to improve high altitude centering
| $view_origin.init{VO}

view.set_brush NewBrush = $brush.init{NewBrush}

view.world = $main.world

type cursor{color front height}

cursor.draw FB X Y =
| V = $color
| Front = $front
| H = $height
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
| Key = (((max X Y))</54) + ((X*128+Y)</38)
| for G Gs
  | T = Wr.tid_map.(Wr.get{X Y Z})
  | TH = T.height
  | ZZ = Z*ZUnit
  | Key = Key + ((Z*2)</30)
  | DrawCursor = Cursor and Z < CursorZ
  | when DrawCursor:
    | G = cursor #FF0000 0 TH
    | Heap.push{Key-1 [G BX BY-YUnit-ZZ 0]}
  | UnitZ <= Z + TH
  | TZ = UnitZ - 4
  | less T.invisible
    | when AboveCursor or TZ << CutZ:
      | Heap.push{Key [G BX BY-G.h-ZZ 0]}
  | when DrawCursor:
    | G = cursor #00FF00 1 TH
    | Heap.push{Key+1 [G BX BY-YUnit-ZZ 0]}
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


Unexplored = 0

render_unexplored Wr X Y BX BY Heap =
| less Unexplored: Unexplored <= Wr.main.img{ui_unexplored}
| Key = (((max X Y))</54) + ((X*128+Y)</38)
| Heap.push{Key [Unexplored BX BY-ZUnit-Unexplored.h 0]}

view.render_iso =
| Wr = $world
| Explored = Wr.human.sight
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
      | E = Explored.Y.X
      | if E then render_pilar Wr X Y BX BY Heap $cursor RoofZ
        else render_unexplored Wr X Y BX BY Heap
      //| Key = (X+Y)*WW*WH+X
      //| Heap.push{Key [Gs.0 BX BY 0]}
//| Font = font small
//| Order = 0
| while!it Heap.pop:
  | [G BX BY F] = it.value
  | BX = TX + BX
  | BY = TY + BY
  | when F: // check flags
     | when F ^^ #2
       | FB.rectangle{#00FF00 0 BX BY G.w G.h}
       | !F -- #2
  | FB.blit{BX BY G}
  //| Font.draw{FB BX+18 BY+4 "[Order]"}
  //| !Order+1

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
| $fb.clear{#929292/*#00A0C0*/}
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

world.update_pick Units =
| for U $picked^uncons{picked}: U.picked <= 0
| $picked <= Units^cons{picked}

view.select_unit XYZ = 
| Picked = []
| Us = $world.units_at{XYZ}.skip{?aux}
| when $mode >< play: Us <= Us.keep{?show}
| when not $world.picked or $world.picked.xyz <> XYZ: $pick_count <= 0
| when Us.size
  | !$pick_count+1
  | Picked <= [Us.($pick_count%Us.size)]
| $world.update_pick{Picked}

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

view.update_pick =
| when $mice_click >< left: $select_unit{$cursor}
| $mice_click <= 0
| Picked = $world.picked
| less Picked: Picked <= $world.nil
| $on_unit_pick{}{Picked}
  // FIXME: following line is outdated
| $main.update //ensures deleted units get updated

action_list_moves Me Picked Act =
| A = action Picked
| A.init{@Act.list.join}
| Affects = Act.affects
| Path = []
| Moves = []
| R = Act.range
| less got R: leave Moves
| PXYZ = Picked.xyz
| Points = if R.is_int then points_in_circle R else points_in_matrix R.tail
| for X,Y Points
  | XYZ = PXYZ+[X Y 0]
  | X = XYZ.0
  | Y = XYZ.1
  | when X>0 and X<<$w and Y>0 and Y<<$h:
    | XYZ.2 <= $fix_z{XYZ}
    | Target = $block_at{XYZ}^~{No 0}
    | Valid = 1
    | when Target and Affects >< empty: Valid <= 0
    | when not Target and Affects >< unit: Valid <= 0
    | A.xyz.init{XYZ}
    | A.target <= Target
    | if Valid and A.valid
      then push XYZ Moves
      else push XYZ Path
| [Moves Path]

update_lmb Me Player =
| less $world.act:
  | $select_unit{$cursor}
  | leave
| Picked = $world.picked
| less Picked.id and Picked.owner.id >< Player.id:
  | $world.act <= 0
  | leave
| Act = $world.act.deep_copy
| less Act.range >< any
  | Ms = action_list_moves{$world Picked Act}.0
  | when no Ms.find{$cursor}: leave
| Act.target <= $world.block_at{$cursor}^~{No 0}
| Act.at <= $cursor
| Picked.order.init{@Act.list.join}
| $world.act <= 0

update_rmb Me Player =
| when $world.act:
  | $world.act <= 0
  | leave
| Picked = $world.picked
| when Picked.id and Picked.owner.id >< Player.id:
  | $world.picked.guess_order_at{$cursor}

view.update_play =
| Player = $world.player
| if not $world.picked.idle or $world.waiting then
  else if not Player.human then Player.ai.update
  else
  | case $mice_click
    left | update_lmb Me Player
    right | update_rmb Me Player
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
| less Picked and Picked.moves and Picked.moved<$turn:
  | Picked <= 0
| when Picked and Picked.picked and Picked.action.type >< idle:
  | Marks = if $act and $act.range <> any
    then | Ms,Path = action_list_moves{Me Picked $act}
         | As = map XYZ Ms
           | Mark = $alloc_unit{"mark_magic_hit"}
           | Mark.move{XYZ}
           | Mark
         | Bs = map XYZ Path
           | Mark = $alloc_unit{"mark_magic"}
           | Mark.move{XYZ}
           | Mark
         | [@As @Bs]
    else Picked.mark_moves
  | $marks <= [$nil @Marks]^cons{mark}

world.update_cursor CXYZ Brush Mirror =
| Marks = $marks^uncons{mark}.flip
| if $act
  then | push $alloc_unit{mark_cursor_target}.move{CXYZ} Marks
  else | push $alloc_unit{mark_cursor0}.move{CXYZ} Marks
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
| case $keys.up 1: $center_at{$center-[1 1 0]}
| case $keys.down 1: $center_at{$center+[1 1 0]}
| case $keys.left 1: $center_at{$center-[1 -1 0]}
| case $keys.right 1: $center_at{$center+[1 -1 0]}
//| $cursor.0 <= $cursor.0.clip{1 $world.w}
//| $cursor.1 <= $cursor.1.clip{1 $world.h}
| case $keys.`[` 1:
  | $zfix <= 0
  | when $cursor.2>1: !$cursor.2 - 1
  | $keys.`[` <= 0
| case $keys.`]` 1:
  | $zfix <= 0
  | when $cursor.2<62: !$cursor.2 + 1
  | $keys.`]` <= 0
| case $keys.p 1:
  | $zfix <= 1
  | $keys.p <= 0
| X,Y,Z = $cursor
| $world.update_picked
| Brush = if $mode >< brush then $brush else 0
| Mirror = $keys.m >< 1
| $world.update_cursor{$cursor Brush Mirror}
| case $mode
    play | $update_play
    brush | $update_brush
    pick | $update_pick
    Else | bad "bad view mode ([$mode])"
| 1

view.fix_z XYZ =
| less $zfix: leave XYZ.2
| if $keys.e><1 then $world.fix_z_void{XYZ} else $world.fix_z{XYZ}

view.input In =
//| when $paused: leave
| case In
  [mice_move _ XY]
    | !XY+[0 32]
    | $mice_xy.init{XY}
    | CX,CY = $viewToWorld{$mice_xy}
    | when $mode <> play or $world.human.sight.CY.CX:
      | $cursor.init{[CX CY $cursor.2]}
      | $cursor.2 <= $fix_z{$cursor}
  [mice left State XY]
    | $zfix <= 1
    | $mice_click <= if State then \left else 0
    | if State then $anchor.init{$cursor} else $cursor.2 <= $fix_z{$cursor}
  [mice right State XY]
    | $zfix <= 1
    | $mice_click <= if State then \right else 0
    | if State then $anchor.init{$cursor} else $cursor.2 <= $fix_z{$cursor}
  [key Name S]
    | $keys.Name <= S

view.pause = $paused <= 1
view.unpause = $paused <= 0

view.wants_focus = 1

export view
