use macros util gui

order_at Me XYZ =
| Player = $player
| U = $picked
| when not U.id or U.owner.id <> Player.id: leave
| $site.visual{XYZ ack}
| $site.last_picked <= 0
| U.order_at{XYZ 0}

view.handle_picked_act2 Actor Act XYZ Target =
//| when Target: $site.blink.init{[4 Target]}
| $site.last_picked <= 0
| when Act.menu:
  | when Act.onMenu: Actor.effect{Act.onMenu Target XYZ}
  | Actor.set{menu [Act.name XYZ if Target then Target.serial else No]}
  | leave
| Actor.set{menuact Actor.get{menu}}
| Actor.strip{menu}
| Actor.order_at{(Target or XYZ) Act}

view.handle_picked_act Target =
| less $mice_click><pick:
  | when $site.act.check.has{unit}:
    | Cur = if Target then \ui_cursor_target else \ui_cursor_target2
    | get_gui{}.cursor <= $main.img{Cur}
  | leave
| [Actor ActUnitOldSerial] = $site.act_unit
| when Actor.serial><ActUnitOldSerial: //is actor alive?
  | $handle_picked_act2{Actor $site.act $cursor Target}
| $site.act <= 0
| $mice_click <= 0


view.handle_pick =
| Unit = $site.nil
| when@@it $site.cell{@$cursor}.block:
  | when it.ai><unit and it.pickable:
    | less it.invisible and it.owner.is_enemy{$site.human}:
      | Unit <= it
| Player = $player
| less Player.seen{Unit.xyz}: Unit <= $site.nil
| $ui.on_unit_pick{$picked}
| Target = if Unit.id then Unit else 0
| when $site.act:
  | $handle_picked_act{Target}
  | leave
| get_gui{}.cursor <=
  if $main.ui.inputBlocker.show then $main.img{ui_cursor_hourglass}
  else $main.img{ui_cursor_point}
| less $mice_click:
  //| when Target: get_gui{}.cursor <= $main.img{ui_cursor_glass}
  | leave
| when $mice_click >< rightup: leave
| when $mice_click >< left: leave
| when $mice_click >< order:
  | $mice_click <= 0
  | XYZ = $cursor
  | less $paused:
    | if not Target then order_at Me $cursor
      else //| $site.blink.init{[4 Target]}
           | order_at Me Target.xyz
  | leave
| when $mice_click >< pick:
  | $mice_click <= 0
  | when Unit.id: $main.sound{ui_click}
  | when $picked.id: $picked.picked <= 0
  | $picked <= Unit
  | $site.last_picked <= 0
  | leave

view.siteToView P =
| X,Y = P - $view_origin
| RX = (X*$xunit - Y*$xunit)/2
| RY = (X*$yunit + Y*$yunit)/2
| [RX RY] + $blit_origin

view.viewToSite P =
| X,Y = P - $blit_origin - [$yunit -$yunit+$zunit]
| WH = $xunit*$yunit
| RX = (Y*$xunit + X*$yunit)/WH
| RY = (Y*$xunit - X*$yunit)/WH
| [RX RY] = [RX RY] + $view_origin
| [RX.clip{1 $site.w} RY.clip{1 $site.h}]

view.viewToSitePixels P =
| X,Y = P - $blit_origin - [$yunit -$yunit+$zunit]
| WH = $xunit*$yunit
| RX = (Y*$xunit + X*$yunit)/$yunit
| RY = (Y*$xunit - X*$yunit)/$xunit
| RX,RY = [RX RY] + [$view_origin.0*$xunit $view_origin.1*$yunit]
| [RX/2 RY]

view.mice_rect =
| AX,AY = $mice_xy_anchor
| MX,MY = $mice_xy
| X = min AX MX
| Y = min AY MY
| U = max AX MX
| V = max AY MY
| MW = U-X
| MH = V-Y
| less MW>4 or MH>4: leave 0
| [X Y MW MH]


view.update_play =
| less $brush.0: case $mice_click
  leftup | $mice_click <= \pick
  right | when $picked.id:
          | $mice_click <= \order
        | when $site.act:
          | $site.act <= 0
          | $mice_click <= 0
  rightup
    | $mice_click <= 0

site.clear_marks ClearBlessed =
| ReAdd = []
| for M $marks.list:
  | if ClearBlessed or not M.blessed then
      | M.remove
      | $free_marks.push{M}
    else push M ReAdd
| $marks.clear
| for M ReAdd: $marks.push{M}

site.set_mark XYZ Bless Type =
| M = 0
| if $free_marks.used then
    | M <= $free_marks.pop
    | when Type <> M.type:
      | M.alpha <= 0
      | M.morph{Type}
      | M.mark <= 1
  else
    | M <= $human.alloc_unit{Type}
    | M.mark <= 1
| M.move{XYZ}
| M.pick_facing{3}
| M.blessed <= Bless
| $marks.push{M}
| M

site.update_picked =
| U = $human.picked
| when $last_pickedXYZ<>U.xyz:
  | $last_picked <= 0
  | $last_pickedXYZ.init{U.xyz}
| when U.id and U.invisible and U.owner.is_enemy{$human}:
  | U.picked <= 0
  | $human.picked <= $nil
| when U.id: U.picked <= 1
| when not U.id or $last_picked<>U.serial or not U.alive: U.picked <= 0
| ClearBlessed = not U.id or not U.idle or $last_picked<>U.serial
| $clear_marks{ClearBlessed}
| less ClearBlessed: leave
| less U.id: leave
| less U.idle:
  | $last_picked <= 0
  | leave
| $last_picked <= U.serial
| less $act:
  | for What,Cell U.reachable:
    | when What><attack
      | B = Cell.block
      | when B and B.invisible: What <= \move
    | $set_mark{Cell.xyz 1 "mark_[What]"}
  | leave
| when $act.range >> 9000: leave
| UX,UY,UZ = U.xyz
| for X,Y points_in_diamond{$act.range}
  | XX = UX+X
  | YY = UY+Y
  | passable Cell =
    | when Cell.empty: leave 1
    | P = $proxy_at{Cell.xyz}
    | when P and P.passCursor: leave 1
    | 0
  | when XX >> 1 and YY >> 1:
    | Cell = $cell{XX YY 1}
    | while Cell.z < $d-1:
      | P = $proxy_at{Cell.xyz}
      | if passable Cell then
          | P = $proxy_below{Cell.xyz}
          | less P and P.passCursor:
            | $set_mark{Cell.xyz 1 mark_cast}
          | while Cell.z < $d-1 and passable Cell: Cell++
        else
          | while Cell.z < $d-1 and not passable Cell: Cell++

site.update_cursor =
| CXYZ = $view.cursor
| if $act
  then | $set_mark{CXYZ 0 mark_cursor_target}
  else | $set_mark{CXYZ 0 mark_cursor0}
       | $set_mark{CXYZ 0 mark_cursor1}
| case $view.brush
  [obj Bank,Type] | $update_cursor_brush{Bank Type CXYZ}

view.update UpdatePlay =
| GUI = get_gui
| case $key{pause} 1:
  | $paused <= not $paused
  | $key_set{pause 0}
  | $main.sound{pause}
| case $key{up} 1: $center_at{$center-[1 1 0]}
| case $key{down} 1: $center_at{$center+[1 1 0]}
| case $key{left} 1: $center_at{$center-[1 -1 0]}
| case $key{right} 1: $center_at{$center+[1 -1 0]}
//| $cursor.0 <= $cursor.0.clip{1 $site.w}
//| $cursor.1 <= $cursor.1.clip{1 $site.h}
| case $key{floor_down} 1:
  | NewZ = $site.down{$cursor}
  | when NewZ:
    | $cursor.2 <= NewZ
  | $zlock <= $cursor.2
  | $key_set{floor_down 0}
| case $key{floor_up} 1:
  | NewZ = $site.up{$cursor}
  | when NewZ:
    | $cursor.2 <= NewZ
  | $zlock <= $cursor.2
  | $key_set{floor_up 0}
| case $key{screenshot} 1:
  | $key_set{screenshot 0}
  | $make_screenshot <= 1
| when $brush.0:
  | case $key{edit_down} 1:
    | $zfix <= 0
    | when $cursor.2>1: $cursor.2--
    | $key_set{edit_down 0}
    | $zlock <= $cursor.2
  | case $key{edit_up} 1:
    | $zfix <= 0
    | when $cursor.2<$site.d-2: $cursor.2++
    | $key_set{edit_up 0}
  | case $key{edit_zfix} 1:
    | $zfix <= 1
    | $key_set{edit_zfix 0}
| X,Y,Z = $cursor
| less $brush.0: $handle_pick
| $site.update_picked
| $site.update_cursor
| when $brush.0: $update_brush
| when UpdatePlay
  | $update_play
  | less $paused:
    | times I $main.cfg.ui.game_speed: $main.update
| 1

view.floor XYZ =
| less $zfix: leave XYZ.2
| when $key{edit_over_empty}: leave $site.floor_void{XYZ}
| Z = $site.floor{XYZ}
| P = $site.proxy_below{XYZ.0,XYZ.1,Z}
| when P and P.passCursor: leave P.xyz.2
| Z

view.mice_move XY =
| Ds = 0
| NewZ = 0
| $mice_xy.init{XY}
| when $key{edit_fine_xy}: leave
| less $mice_click: $mice_xy_anchor.init{XY}
| CX,CY = $viewToSite{$mice_xy}
| when ($mice_click><left or $mice_click><pick) and not $brush.0: leave
| CZ = $cursor.2
| when not $mice_click or $site.at{@$anchor}.empty:
  | CZ <= $floor{$cursor}
| less $brush.0
  | P = $site.proxy_at{CX,CY,CZ}
  | when P and P.passCursor: _goto end
| NewZ <= CZ
| while NewZ and NewZ>>$zlock:
  | CZ <= NewZ
  | NewZ <= $site.down{CX,CY,CZ}
| NewZ <= CZ
| while NewZ and NewZ<<$zlock:
  | CZ <= NewZ
  | NewZ <= $site.up{CX,CY,CZ}
| Ds <= [[1 0] [0 1] [-1 0] [0 -1]]
| NewZ <= CZ
| while NewZ>$zlock+1:
  | less Ds.all{[XD YD] => $site.at{CX+XD CY+YD NewZ}.empty}:
    | CZ <= NewZ
  | NewZ--
| _label end
| less $brush.0:
  | less $site.human.seen{CX,CY,CZ}: CZ <= $cursor.2
| $cursor.init{CX,CY,CZ}

view.input In =
//| when $paused: leave
| case In
  [mice_move _ XY] | $mice_move{XY}
  [mice left State XY]
    | less $site.human.seen{$cursor}: leave
    | $lmb_count++
    | $zfix <= 1
    | $mice_click <= if State then \left else \leftup
    | if State then $anchor.init{$cursor}
      else when $site.at{@$cursor}.empty: $cursor.2 <= $floor{$cursor}
    | when State: $mice_xy_anchor.init{XY}
  [mice right State XY]
    | less $site.human.seen{$cursor}: leave
    | $zfix <= 1
    | $site.last_picked <= 0
    | $mice_click <= if State then \right else \rightup
    | if State then $anchor.init{$cursor}
      else when $site.at{@$cursor}.empty:
           | $cursor.2 <= $floor{$cursor}
           | $anchor.init{$cursor}
    | when State: $mice_xy_anchor.init{XY}
  [key Name S]
    | $keys.Name <= S
| when $brush.0: $mice_xy_anchor.init{$mice_xy}

view.pause = $paused <= 1
view.unpause = $paused <= 0

view.wants_focus = 1
