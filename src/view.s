use gui util widgets


type view.widget{W H M} g w/W h/H xy main/M player paused/1 last_click
                        units notes speed/20 frame cursor selection
                        keys/(t) mice_xy/[0 0] anchor
| $g <= gfx W H

view.init =
| $paused <= 0
| $selection <= []
| $notes <= []
| $clear_clicks
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
| G

view.mice_to_cell XY =
| [X Y] = ($xy+XY)/32
| $world.get{X.clip{0 $world.w-1} Y.clip{0 $world.h-1}}


view.mice_rect =
| [AX AY] = if $anchor then $anchor else $mice_xy
| [BX BY] = $mice_xy
| X = min AX BX
| Y = min AY BY
| U = max AX BX
| V = max AY BY
| [X Y U-X V-Y]

view.pick_cursor =
| $cursor <= skin_cursor if $act.0 then \ch_red
                         else if $anchor then \cross
                         //else if $input_select_single{$mice_xy}.size then \glass
                         else \point

view.input In = case In
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
  [key Name  S] | $keys.Name <= S

view.pause = $paused <= 1
view.unpause = $paused <= 0

view.update =
| when $paused: leave 1
| 1

export view
