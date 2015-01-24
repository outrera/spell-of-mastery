use gui util widgets


TileW = 64
TileH = 32

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
  blit_origin/[360 -170]
  mice_left
  mice_right
  mice_right_xy/[0 0]
  mice_left_xy/[0 0]
  mice_xy/[0 0]
  mice_z
  cell_xy/[0 0]
  cell_index
  brush/[0 0]
  mode/editor
  infoText/txt{'info'}
  fps/1
  fpsT/0.0
  speed/25.0 // frames per second
| $fb <= gfx W H

view.init =
| $fpsT <= clock
| $view_origin.init{-[$world.size $world.size]/2}
| $move{$view_origin} //normalize view

view.set_brush NewBrush = $brush.init{NewBrush}

view.world = $main.world

view.render =
| StartTime = clock
| $update
| FB = $fb
| FB.clear{#929292/*#00A0C0*/}
| TX,TY = $blit_origin
| VX,VY = $view_origin
| TileH2 = TileH/2
| BX = TX
| BY = TY
| Y = 0
| while Y < 32
  | VY = VY+Y
  | times N Y+1: $world.drawPilar{VX+N VY-N BX+N*TileW BY FB $cell_index}
  | !BX - TileH
  | !BY + TileH2
  | !Y + 1
| VX = VX+Y
| VY = VY+Y-1
| BX = BX + TileW
| while Y > 0
  | !Y - 1
  | VX = VX-Y
  | times N Y: $world.drawPilar{VX+N VY-N BX+N*TileW BY FB $cell_index}
  | !BX + TileH
  | !BY + TileH2
| when $frame%24 >< 0
  | T = StartTime
  | $fps <= @int 24.0/(T - $fpsT)
  | $fpsT <= T
| X,Y = $cell_xy
| Z = $world.height{X Y}
| $infoText.value <= "xyz=[X],[Y],[Z]; fps=[$fps]"
| $infoText.draw{FB 4,4}
| $infoText.value <= ''
| !$frame + 1
| FinishTime = clock
| SleepTime = 1.0/$speed - (FinishTime-StartTime)
//| when SleepTime > 0.0: get_gui{}.sleep{SleepTime}
| FB

view.worldToView P =
| [X Y] = P - $view_origin
| RX = (X*TileW - Y*TileW)/2
| RY = (X*TileH - Y*TileH)/2
| [RX RY] + $blit_origin

view.viewToWorld P =
| [X Y] = P - $blit_origin
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
| $cell_index
| $view_origin.init{NewXY}
//| [X Y] = NewXY
//| $view_origin.init{[X.clip{0 $world.size-1} Y.clip{0 $world.size-1}]}

view.center_at XY = $move{XY*32-[$w $h]/2}

view.update_editor X Y Z = 
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
| less $paused: $world.update

view.update =
| X,Y = $cell_xy
| Z = $world.height{X Y}
| if $mode >< editor then $update_editor{X Y Z} else $update_game{X Y Z}
| 1

view.input In = case In
  [mice_move _ XY]
    | !XY+[0 32]
    | $mice_xy.init{XY}
    | $cell_xy.init{$viewToWorld{$mice_xy}}
    | $cell_index <= $world.xy_to_index{$cell_xy}
  [mice left 1 XY]
    | $mice_left <= 1
    | $mice_left_xy.init{XY}
    | $mice_z <= $world.height{@$cell_xy}
  [mice left 0 XY]
    | $mice_left <= 0
  [mice right 1 XY]
    | $mice_right <= 1
    | $mice_right_xy.init{XY}
    | $mice_z <= $world.height{@$cell_xy}
  [mice right 0 XY]
    | $mice_right <= 0
  [key up    1] | $move{$view_origin-[1 1]}
  [key down  1] | $move{$view_origin+[1 1]}
  [key left  1] | $move{$view_origin-[1 -1]}
  [key right 1] | $move{$view_origin+[1 -1]}
  [key Name  S] | $keys.Name <= S

view.pause = $paused <= 1
view.unpause = $paused <= 0


export view
