use gui util widgets


TileW = 64
TileH = 32

type view.widget{M W H}
  main/M
  g
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
| $g <= gfx W H

view.init =
| $view_origin.init{-[$world.size $world.size]/2}
| $move{$view_origin} //normalize view

view.set_brush NewBrush = $brush.init{NewBrush}

view.world = $main.world

view.render =
| $update
| G = $g
| G.clear{#929292/*#00A0C0*/}
| Blit = X Y Src FX => G.blit{X,Y Src flipX(FX)}
| D = 32
| [TX TY] = $blit_origin
| Y = 0
| YY = D
| while Y < D
  | times N Y+1
    | BX = TX - Y*TileH + N*TileW
    | BY = TY + Y*TileH/2
    | $world.drawPilar{$view_origin+[N Y-N] BX BY Blit $cell_index}
  | !Y + 1
| while YY > 0
  | !YY - 1
  | times N YY
    | BX = TX - (YY-1)*TileH + N*TileW
    | BY = TY + Y*TileH/2
    | $world.drawPilar{$view_origin+[D-YY+N D-N-1] BX BY Blit $cell_index}
  | !Y + 1
| !$frame + 1
| G

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

view.update =
| X,Y = $cell_xy
| Z = $world.height{X Y}
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
  [tile Type] | $world.pop{X,Y}
| $world.update
| when $paused: leave 1
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
