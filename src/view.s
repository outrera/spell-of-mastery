use gui util widgets


TileW = 64
TileH = 32

type view.widget{M W H}
  main/M g w/W h/H cursor
  view_origin/[0 0] blit_origin/[360 -170] mice_xy/[0 0] mice_z cell_xy/[0 0] cell_index
  brush/[tile base]
| $g <= gfx W H

view.init =
| $move{$xy} //normalize view

view.world = $main.world

view.move NewXY =
| XY = $xy
| XY.init{NewXY}
| [X Y] = XY
| WW = $world.w*32
| WH = $world.h*32
| XY.init{[X.clip{0 WW-$g.w} Y.clip{0 WH-$g.h}]}

view.center_at XY = $move{XY*32-[$w $h]/2}

view.render =
| G = $g
| G.clear{#929292/*#00A0C0*/}
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
| [RX.clip{0 S} RY.clip{0 S}]

view.mice_rect =
| [AX AY] = if $anchor then $anchor else $mice_xy
| [BX BY] = $mice_xy
| X = min AX BX
| Y = min AY BY
| U = max AX BX
| V = max AY BY
| [X Y U-X V-Y]

view.pick_cursor =
| $cursor <= skin_cursor /*if $act.0 then \ch_red
                         else if $anchor then \cross
                         //else if $input_select_single{$mice_xy}.size then \glass
                         else*/ \point

view.input In = /*case In
  [mice_move _ XY]
    | $mice_xy.init{XY}
    | $pick_cursor 
  [mice left 1 XY]
    | when $act.0: leave 0
    | $anchor <= XY
    | $pick_cursor 
  [mice left 0 XY]
    | $mice_xy.init{XY}
    | C = $mice_to_cell{$mice_xy}
    | if $act.0
      then | [Actor What Type] = $act
           | $anchor <= $mice_xy
           | Target = $input_select^($No [U@_]=>U)^~{No C}
           | when Target.is_unit
             | $target_blink.init{[Target $world.cycle+12 $world.cycle+24]}
           | Actor.order{What Type Target}
           | $act.init{[0 0 0]}
      else | $selection <= $input_select
    | $anchor <= 0
    | $pick_cursor 
  [mice right 1 XY]
    | if $act.0
      then | $act.init{[0 0 0]}
           | $pick_cursor
      else
  [key up    1] | $move{$xy-[0 64]}
  [key down  1] | $move{$xy+[0 64]}
  [key left  1] | $move{$xy-[64 0]}
  [key right 1] | $move{$xy+[64 0]}
  [key Name  S] | $keys.Name <= S*/

view.pause = $paused <= 1
view.unpause = $paused <= 0

view.update =
| when $paused: leave 1
| 1

export view
