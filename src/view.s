use gui util widgets


TileW = 64
TileH = 32

ViewDim = 32 // render 32x32 world chunk

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
  mode/editor
  editor_mode/brush
  pick_count // used to pick different units from the same cell
  infoText/txt{'info'}
  fps/1
  fpsT/0.0
  fpsGoal/24 // goal frames per second
  fpsD/30.0
  param
  on_unit_pick/(Picked=>)
| $fb <= gfx W H
| $fpsGoal <= $main.params.ui.fps
| $fpsD <= $fpsGoal.float+8.0
| $param <= $main.params.ui

view.init =
| $fpsT <= clock
| $view_origin.init{-[$h/32 $h/32]}
| $move{$view_origin} //normalize view

view.set_brush NewBrush = $brush.init{NewBrush}

view.world = $main.world

view.render_iso = 
| Wr = $world
| FB = $fb
| WorldParams = $main.params.world
| ZUnit = WorldParams.z_unit
| YDiv = WorldParams.y_unit/ZUnit
| Z = if $mice_left or $mice_right then $mice_z else $cell_z
| TX,TY = $blit_origin+[0 Z]%YDiv*ZUnit
| VX,VY = $view_origin-[Z Z]/YDiv
| TileH2 = TileH/2
| BX = TX
| BY = TY
| Y = 0
| while Y < ViewDim
  | VY = VY+Y
  | !Y + 1
  | times N Y: Wr.drawPilar{VX+N VY-N BX+N*TileW BY FB $cell_xy $cell_z}
  | !BX - TileH
  | !BY + TileH2
| VX = VX+Y
| VY = VY+Y-1
| BX = BX + TileW
| while Y > 0
  | !Y - 1
  | VX = VX-Y
  | times N Y: Wr.drawPilar{VX+N VY-N BX+N*TileW BY FB $cell_xy $cell_z}
  | !BX + TileH
  | !BY + TileH2

view.render_frame =
| $fb.clear{#929292/*#00A0C0*/}
| $render_iso
| X,Y = $cell_xy
| Z = $world.height{X Y}
| InfoText = []
| when $param.show_xyz: push "xyz=[X],[Y],[Z]" InfoText
| when $param.show_frame: push "frame=[$frame]" InfoText
| when $param.show_cycle: push "cycle=[$world.cycle]" InfoText
| when $param.show_turn: push "turn=[$world.turn]" InfoText
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
| RX = (X*TileW - Y*TileW)/2
| RY = (X*TileH - Y*TileH)/2
| [RX RY] + $blit_origin

view.viewToWorld P =
| [X Y] = P - $blit_origin - [0 $main.params.world.z_unit*4]
| !X - 32
| WH = TileW*TileH
| RX = (Y*TileW + X*TileH)/WH
| RY = (Y*TileW - X*TileH)/WH
| [RX RY] = [RX RY] + $view_origin
| S = $world.size
| [RX.clip{0 S-1} RY.clip{0 S-1}]

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
//| $view_origin.init{[X.clip{0 $world.size-1} Y.clip{0 $world.size-1}]}

view.center_at XY = $move{XY*32-[$w $h]/2}

view.update_editor_pick X Y Z = 
| when $mice_left
  | for U $world.picked^uncons{picked}: U.picked <= 0
  | $world.picked <= 0
  | Us = $world.units_at{X,Y,Z}
  | when Us.size
    | !$pick_count+1
    | $world.picked <= [Us.($pick_count%Us.size)]^cons{picked}
  | $on_unit_pick{}{$world.picked}
  | $mice_left <= 0
| when $mice_right
  | when $world.picked: $world.picked.order.init{move X,Y,Z}
  | $mice_right <= 0
| $main.update

view.update_editor_brush X Y Z = 
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
      | when $keys.t >< 1: U.flipX <= 1.rand
      | when $keys.m >< 1: U.flipX <= 1
      | U.move{X,Y,Z}
  [tile Type] | $world.push{X,Y $main.tiles.Type}
| when $mice_right and Z >> $mice_z: case $brush
  [obj Type] | for U $world.units_at{X,Y,Z}: U.free
  [tile Type] | when Z > 1: $world.pop{X,Y}

view.update_game X Y Z = 
| $main.update

view.update =
| when $paused: leave 0
| SanitizedPicked = $world.picked^uncons{picked}.skip{?removed}
| $world.picked <= [$world.nil @SanitizedPicked]^cons{picked}
| X,Y = $cell_xy
| Z = $world.height{X Y}
| if $mode >< editor
  then if $editor_mode >< pick
       then $update_editor_pick{X Y Z}
       else $update_editor_brush{X Y Z}
  else $update_game{X Y Z}
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
