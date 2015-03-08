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
  cursor
  keys/(t)
  view_origin/[0 0]
  blit_origin/[W/2 -170]
  mice_left
  mice_right
  mice_right_xy/[0 0]
  mice_left_xy/[0 0]
  mice_xy/[0 0]
  mice_z
  cell_xy/[0 0]
  cell_z
  brush/[0 0]
  mode/brush
  pick_count // used to pick different units from the same cell
  infoText/txt{'info'}
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
| $view_origin.init{-[$h/32 $h/32]}
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

render_pilar Wr X Y BX BY Heap CursorXY CursorZ =
| Gs = Wr.gfxes.Y.X
| CurX = CursorXY.0
| CurY = CursorXY.1
| CurH = (CurX+CurY)/2
| XY2 = (X+Y)/2
| AboveCursor = CurH >> XY2
| CurHH = XY2-CurH-2
| Cursor = same X CurX and Y >< CurY
| Z = 0
| UnitZ = 0
| Key = ((X+Y)</40)
| for G Gs: if G.is_int
  then | when Cursor
         | BY = BY-YUnit-Z*ZUnit
         | Key = Key + (Z</30)
         | Heap.push{Key [G BX BY #4000+(G</16)]}
         | Heap.push{Key+1 [G BX BY #8000+(G</16)]}
       | !Z+G
  else | T = Wr.tid_map.(Wr.get{X Y Z})
       | TH = T.height
       | ZZ = Z*ZUnit
       | Key = Key + ((Z*2)</30)
       | when Cursor | Heap.push{Key-1 [G BX BY-YUnit-ZZ #4000+(TH</16)]}
       | UnitZ <= Z + TH
       | TZ = UnitZ - 4
       | when AboveCursor or TZ << CursorZ or CurHH-TZ/YDiv >> 0:
         | Heap.push{Key [G BX BY-G.h-ZZ 0]}
         | for U Wr.units_at{X,Y,UnitZ}: U.render{Heap BX BY-ZUnit*UnitZ}
       | when Cursor | Heap.push{Key+1 [G BX BY-YUnit-ZZ #8000+(TH</16)]}
       | Z <= UnitZ
| for U Wr.column_units_at{X Y}
  | Z = U.xyz.2
  // FIXME: should we always display flying units? even underground?
  | when Z > UnitZ
    | !Z+1
    | U.render{Heap BX BY-ZUnit*Z-ZUnit}
    | S = Wr.shadows.(2-min{(@abs (Z-UnitZ)/2-2) 2})
    | Key = Key + (UnitZ</30) + 1
    | Heap.push{Key [S BX-S.w/2+32 BY-S.h-UnitZ*ZUnit 0]}

view.render_iso = 
| Wr = $world
| XUnit = XUnit
| YUnit = YUnit
| ZUnit = ZUnit
| FB = $fb
| Z = if $mice_left or $mice_right then $mice_z else $cell_z
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
  | when 0<<Y and Y<WH: times XX VS:
    | X = XX + VX
    | when 0<<X and X<WW: // FIXME: moved this out of the loop
      | BX = XX*XUnit2 - YY*XUnit2
      | BY = XX*YUnit2 + YY*YUnit2
      | render_pilar Wr X Y BX BY Heap $cell_xy $cell_z
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
  //| Font.draw{FB BX+18 BY+4 red "[Order]"}
  //| !Order+1

view.render_frame =
| $fb.clear{#929292/*#00A0C0*/}
| $render_iso
| X,Y = $cell_xy
| Z = $world.height{X Y}
| InfoText = []
| when $param.show_tile: push "tile=[$world.at{X,Y,Z-1}.type]" InfoText
| when $param.show_xyz: push "xyz=[X],[Y],[Z]" InfoText
| when $param.show_frame: push "frame=[$frame]" InfoText
| when $param.show_cycle: push "cycle=[$world.cycle]" InfoText
| when $param.show_turn: push "turn=[$world.turn]" InfoText
| push "power=[$world.player.power]" InfoText
| push "moves=[$world.player.moves]" InfoText
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
| [RX.clip{0 $world.w-1} RY.clip{0 $world.h-1}]

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

view.select_unit X Y Z = 
| for U $world.picked^uncons{picked}: U.picked <= 0
| $world.picked <= 0
| Us = $world.units_at{X,Y,Z}.skip{?aux}
| when Us.size
  | !$pick_count+1
  | $world.picked <= [Us.($pick_count%Us.size)]^cons{picked}
| $on_unit_pick{}{$world.picked}

view.update_pick X Y Z = 
| when $mice_left
  | $select_unit{X Y Z}
  | $mice_left <= 0
| when $mice_right
  | $mice_right <= 0
| $main.update

view.update_brush X Y Z = 
| when $mice_left and Z << $mice_z: case $brush
  [obj Bank,Type]
    | ClassName = if $keys.r >< 1
                  then "[Bank]_[$main.classes_banks.Bank.rand]"
                  else "[Bank]_[Type]"
    | Class = $main.classes.ClassName
    | Us = $world.units_at{X,Y,Z}
    | Place = if Class.unit then not Us.any{?unit}
              else if $keys.r >< 1 then Us.end
              else not Us.any{?class^address >< Class^address}
    | when Place
      | U = $world.alloc_unit{ClassName}
      | U.pick_facing{if $keys.m >< 1 then 5 else 3}
      | when $keys.t >< 1: U.facing <= 3.rand
      | U.move{X,Y,Z}
  [tile Type]
    | Tile = $main.tiles.Type
    | less Tile.empty
      | for U $world.units_at{X,Y,Z}: U.move{X,Y,Z+Tile.height}
    | $world.push{X,Y $main.tiles.Type}
| when $mice_right and Z >> $mice_z: case $brush
  [obj Type] | for U $world.units_at{X,Y,Z}: U.free
  [tile Type]
  | when Z > 1:
    | Tile = $world.at{X,Y,Z-1}
    | when Z > 1: $world.pop{X,Y}
    | for U $world.units_at{X,Y,Z}: U.move{X,Y,Z-Tile.height}

unit.guess_order_at XYZ =
| Us = $world.units_at{XYZ}
| Mark = Us.find{?type.take{5} >< mark_}
| less got Mark: leave
| Path = cons path: map M Mark^uncons{path}.lead.flip
  | Node = $world.alloc_unit{mark_node}
  | Node.move{M.xyz}
  | Node
| case Mark.type
  mark_move
   | $order.init{act/move at/XYZ path/Path}
  mark_attack
   | Target = Us.skip{?empty}.0
   | $order.init{act/attack target/Target at/XYZ path/Path}
  mark_swap
   | Target = Us.skip{?empty}.0
   | $order.init{act/swap target/Target at/XYZ path/Path}

view.update_play X Y Z =
| Player = $world.player
| less Player.human
  | less Player.ai.update: $world.end_turn
  | $main.update
  | leave
| when $mice_left
  | $select_unit{X Y Z}
  | $mice_left <= 0
| when $mice_right
  | when $world.picked: $world.picked.guess_order_at{X,Y,Z}
  | $mice_right <= 0
| $main.update

Dirs2d = [[0 -1] [1 0] [0 1] [-1 0]]

unit.mark_moves =
| Marks = []
| I = 0
| Ms = $moves.deep_copy
| O = Ms.size/2
| advance Prev XY =
  | Ns = Dirs2d{?+XY}.keep{Ms.?0.?1}
  | for X,Y Ns: Ms.X.Y <= 0
  | Ns{[Prev XY ?]}
| Stack = advance 0 [O O]
| till Stack.end
  | [Prev SX,SY DX,DY] = pop Stack
  | Src = $xyz + [SX-O SY-O 0]
  | Dst = $xyz + [DX-O DY-O 0]
  | Mark = 0
  | Blocked = Dst.0 < 0 or Dst.1 < 0
  | less Blocked
    | !Dst.2 - 1
    | while $world.at{Dst}.empty: !Dst.2 - 1
    | !Dst.2 + 1
    | less $can_move{Src Dst 0}
      | AboveDst = Dst + [0 0 $world.at{Dst}.height]
      | when $can_move{Src AboveDst 0}: Dst <= AboveDst
    | less $can_move{Src Dst 1}:
      | when got!it $world.block_at{Dst}:
        | when $can_move{Src Dst 0}
          | if  $owner.id >< it.owner.id
            then | when $owner.moves >> max{$level it.level}
                        and it.moves.size
                        and it.can_move{Dst Src 0}:
                   | Mark <= $world.alloc_unit{mark_swap}
            else when it.hits < it.health:
                 | Mark <= $world.alloc_unit{mark_attack}
      | Blocked <= 1
  | less Blocked
    | Mark <= $world.alloc_unit{mark_move}
    | for N (advance Mark [DX DY]): push N Stack
  | when Mark
    | Mark.move{Dst}
    | Mark.path <= Prev
    | push Mark Marks
| Marks.list

world.update_picked = 
| SanitizedPicked = $picked^uncons{picked}.skip{?removed}
| $picked <= [$nil @SanitizedPicked]^cons{picked}
| for I $marks.size:
  | M = $marks.I
  | when M:
    | M.free
    | $marks.I <= 0
| Picked = $picked
| less Picked and Picked.moves and Picked.moved<>$turn and $player.moves > 0:
  | Picked <= 0
| when Picked and Picked.picked and Picked.action.class_name >< idle:
  | for I,M Picked.mark_moves.i: $marks.I <= M

view.update =
| when $paused: leave
| $world.update_picked
| X,Y = $cell_xy
| Z = $world.height{X Y}
| case $mode
    play | $update_play{X Y Z}
         | $main.update
    brush | $update_brush{X Y Z}
    pick | $update_pick{X Y Z}
         | $main.update //ensure deleted units get updated
    Else | bad "bad view mode ([$mode])"
| 1

view.input In =
| case In
  [mice_move _ XY]
    | !XY+[0 32]
    | $mice_xy.init{XY}
    | $cell_xy.init{$viewToWorld{$mice_xy}}
    | $cell_z <= $world.height{@$cell_xy}
  [mice left 1 XY]
    | $mice_left <= 1
    | $mice_left_xy.init{XY}
    | $mice_z <= $world.height{@$cell_xy}
    | $cell_z <= $mice_z
  [mice left 0 XY]
    | $mice_left <= 0
  [mice right 1 XY]
    | $mice_right <= 1
    | $mice_right_xy.init{XY}
    | $mice_z <= $world.height{@$cell_xy}
    | $cell_z <= $mice_z
  [mice right 0 XY]
    | $mice_right <= 0
  [key up    1] | $move{$view_origin-[1 1]*2*$param.scroll_speed}
  [key down  1] | $move{$view_origin+[1 1]*2*$param.scroll_speed}
  [key left  1] | $move{$view_origin-[1 -1]*$param.scroll_speed}
  [key right 1] | $move{$view_origin+[1 -1]*$param.scroll_speed}
  [key Name  S] | $keys.Name <= S

view.pause = $paused <= 1
view.unpause = $paused <= 0

view.wants_focus = 1

export view
