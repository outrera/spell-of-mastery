use macros util gui

order_at Me XYZ =
| Player = $player
| U = $picked
| when not U.id or U.owner.id <> Player.id: leave
| $site.visual{XYZ ack}
| $site.last_picked <= 0
| U.order_at{XYZ 0}

view.handle_picked_act2 Actor Act XYZ Target =
| when Target: $site.blink.init{[4 Target]}
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
  | when $site.act.check.unit:
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
  | less it.invisible: Unit <= it
| Player = $player
| less Player.seen{Unit.xyz}: Unit <= $site.nil
| $ui.on_unit_pick{$picked}
| Target = if Unit.id then Unit else 0
| when $site.act:
  | $handle_picked_act{Target}
  | leave
| get_gui{}.cursor <= $main.img{ui_cursor_point}
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
      else | $site.blink.init{[4 Target]}
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

view.units_get XYZ = $site.units_get{XYZ}.skip{?mark}

LMB_Count = 0
AnchorHack = -1

place_object Me Bank Type =
| X,Y,Z = $cursor
| less Z << $anchor.2: leave
| Cell = $site.cell{X Y Z}
| Mirror = $key{edit_place_mirrored}
| ClassName = "[Bank]_[Type]"
| Class = $main.classes.ClassName
| when Class.item><1:
  | Cell.add_item{ClassName 1}
  | leave
| when Z+Class.height>>$site.d: leave
| Place = 1
| Form = if Class.form then Class.form else [[0 0 0]]
| for XX,YY,ZZ Form: when Place:
  | XYZ = [X Y Z] + if Mirror then [-YY XX ZZ] else [XX -YY ZZ]
  | Us = $site.units_get{XYZ}.skip{?bank><mark}
  | Place <= if not $site.valid{@XYZ} then 0
             else if not Class.empty then Us.all{?empty}
             else not Us.any{?class^address >< Class^address}
  | when Place:
    | X,Y,Z = XYZ
    | H = if Class.passable then Class.height else 2
    | Place <= H.list.all{I=>$site.get{X,Y,Z+I}.empty}
    | less Place: $main.sound{illegal}
| when Place
  | U = $player.alloc_unit{ClassName}
  | Facing = if Mirror then 5 else 3
  | Reverse = $key{edit_place_reversed}
  | when Reverse: Facing <= if Mirror then 1 else 6
  | U.pick_facing{Facing}
  | when $key{edit_random_facing}: U.facing <= 3.rand
  | U.move{X,Y,Z}
  | U.run_genes{place}
  | U.animate{idle}

site_place_tile_walls Me X Y Z Tile =
| Wall = $main.tiles.(Tile.wall)
| for DX,DY Dirs:
  | XX = X+DX
  | YY = Y+DY
  | DTile = $at{XX YY Z}
  | when DTile.dig or DTile.empty:
    | when $at{XX YY Z-1}.type <> Wall.around:
      | $clear_tile{XX YY Z}
      | site_place_tile Me XX YY Z Wall

site_place_tile Me X Y Z Tile =
| when X<1 or Y<1 or X>$w or Y>$h: leave
| $set{X Y Z Tile}
| for U $units_get{X,Y,Z}: U.move{X,Y,Z+Tile.height}
| site_place_tile_deco Me X Y Z Tile

site_place_tile_deco Me X Y Z Tile =
| when Tile.roof.is_list:
  | H,RoofTile = Tile.roof
  | for DX,DY [0,0 @Dirs]:
    | site_place_tile Me X+DX Y+DY Z+H RoofTile
| when Tile.wall: site_place_tile_walls Me X Y Z Tile

site.place_struct XYZ Tile =
| XX,YY,ZZ = XYZ
| Tiles = (Tile.structTiles){N=>$main.tiles.N}
| IIIs = Tile.struct.tail
| for Y IIIs.size:
  | IIs = IIIs.Y
  | for X IIs.size:
    | Is = IIs.X
    | Is = if Is.is_int then [Is] else Is.tail
    | for Z Is.size
      | I = Is.Z
      | when I:
        | site_place_tile Me XX+X YY+Y ZZ+Z Tiles.(I-1)

view.place_tile Type =
| $cursor.2 <= $floor{$cursor}
| Tile = $main.tiles.Type
| when Tile.struct:
  | $site.place_struct{$cursor Tile}
  | $mice_click <= 0
  | leave
| X,Y,Z = $cursor
| IsBridge = $key{edit_bridge}
| IsEmpty = $key{edit_over_empty} or Tile.empty
| IsEmbed = $key{edit_place_embed}
| when IsBridge
  | EmptyTile = $main.tiles.void
  | when LMB_Count<>AnchorHack:
    | AZ = max 1 $anchor.2-Tile.height
    | $anchor.2 <= AZ
    | AnchorHack <= LMB_Count
  | Z = 0
  | while Z<$anchor.2:
    | when $site.at{X Y Z}.type >< void:
      | $site.set{X Y Z EmptyTile}
    | Z++
  | till $site.at{X Y Z}.empty: Z++
  | $cursor.2 <= Z
| less IsBridge
  | when Tile.embed: IsEmbed <= not IsEmbed
  | if IsEmbed then
      | when Tile.wall
        | Below = $site.at{X Y $cursor.2-1}
        | while $cursor.2 > 1 and (Below.around or Below.roof><self
                                   or Below.type><void):
          | H = $site.at{X Y $cursor.2-1}.height
          | $cursor.2 -= H
          | $anchor.2 <= $cursor.2
          | $site.clear_tile{@$cursor}
          | Below <= $site.at{X Y $cursor.2-1}
      | when $cursor.2<<$anchor.2:
        | Below = $site.at{X Y $cursor.2-1}
        | less Below.empty
          | $site.set{X Y $cursor.2-1 Tile owner/$site.human}
          | site_place_tile_deco $site X Y $cursor.2 Tile
          | leave
    else
      | when $site.at{X Y $cursor.2-1}.embed><1 and not Tile.embed: 
        | Z = $cursor.2-1
        | when AnchorHack<>LMB_Count:
          | $anchor.2 <= Z
          | AnchorHack <= LMB_Count
        | while Z>>0 and $site.at{X Y Z}.embed><1 and not Tile.embed:
          | $site.set{X Y Z-- Tile owner/$site.human}
        | leave
  | AnchorHack <= LMB_Count
| while 1
  | Z <= $cursor.2
  | less Z << $anchor.2 and $site.at{X Y Z}.empty: leave
  | when Z+Tile.height>>$site.d: leave
  | site_place_tile $site X Y Z Tile
  | when Tile.empty:
    | when Tile.id><0: leave
    | when IsEmpty: leave
  | $cursor.2 <= $floor{$cursor}
  | when IsBridge: leave

remove_object_or_tile Me =
| X,Y,Z = $cursor
| Brush = $brush
| T = $site.at{X Y Z-1}
| Us = $units_get{X,Y,Z}
| when T.unit and not Us.size:
  | while $site.at{X Y Z}.type >< T.type: Z++
  | ZZ = Z - T.height
  | BelowUs = $units_get{X,Y,ZZ}
  | when BelowUs.size:
    | $mice_click <= 0
    | for U BelowUs: U.free
    | leave
| case Brush
  [obj Type]
    | for U Us: U.free
  [tile Type]
    | less $site.at{X Y Z}.empty: when Z>1
      | $site.clear_tile{X Y Z-1}
      | $cursor.2 <= Z-1
    | while 1
      | Z <= $cursor.2
      | less Z >> $anchor.2 and Z > 1: leave
      | less Z > 1: leave
      | Tile = $site.at{X Y Z-1}
      | less Tile.height: leave
      | $site.clear_tile{X Y Z-1}
      | $cursor.2 <= $floor{$cursor}
      | for U $site.units_get{X,Y,Z}: U.move{$cursor}

view.update_brush =
| when $mice_click><leftup or $mice_click><rightup:
  | $mice_click <= 0
  | leave
| when $mice_click><left: case $brush
  [obj Bank,Type] | place_object Me Bank Type
  [tile Type] | $place_tile{Type}
| when $mice_click><right: remove_object_or_tile Me

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
| M.blessed <= Bless
| $marks.push{M}
| M

site.update_picked =
| U = $human.picked
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
  | when XX >> 1 and YY >> 1:
    | Cell = $cell{XX YY 1}
    | while Cell.z < $d-1:
      | if Cell.empty then
          | $set_mark{Cell.xyz 1 mark_cast}
          | while Cell.z < $d-1 and Cell.empty: Cell++
        else
          | while Cell.z < $d-1 and not Cell.empty: Cell++


site.update_cursor =
| View = $view
| CXYZ = View.cursor
| P = $human
| if $act
  then | $set_mark{CXYZ 0 mark_cursor_target}
  else | $set_mark{CXYZ 0 mark_cursor0}
       | $set_mark{CXYZ 0 mark_cursor1}
| case View.brush
  [obj Bank,Type]
    | Mirror = View.key{edit_place_mirrored}
    | Reverse = View.key{edit_place_reversed}
    | ClassName = "[Bank]_[Type]"
    | Class = $main.classes.ClassName
    | XYZ = CXYZ //+ if Mirror then [-Y X Z] else [X -Y Z]
    | Us = XYZ.0 >> 0 and XYZ.1 >> 0 and $units_get{XYZ}
    | Place = if not Us then 0
              else if Class.unit then not Us.any{?unit}
              else not Us.any{?class^address >< Class^address}
    | when Place:
      | ClassName = "[Bank]_[Type]"
      | Class = $main.classes.ClassName
      | Facing = if Mirror then 5 else 3
      | when Reverse: Facing <= if Mirror then 1 else 6
      | M = $set_mark{XYZ 0 mark_cube}
      | M.sprite <= Class.default_sprite
      | M.colors <= $human.colors
      | M.animate{idle}
      | M.pick_facing{Facing}
      | M.alpha <= 110

view.update =
| GUI = get_gui
| StartTime = GUI.ticks
| when $wakeupTime>StartTime: leave 1
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
| when $brush.0:
  | case $key{edit_down} 1:
    | $zfix <= 0
    | when $cursor.2>1: $cursor.2--
    | $key_set{edit_down 0}
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
| $update_play
| less $paused:
  | times I $main.cfg.ui.game_speed: $main.update
| FinishTime = GUI.ticks
| Wait = 1.0/$fpsGoal.float - (FinishTime-StartTime)
| when Wait > 0.0: $wakeupTime <= FinishTime+Wait
| 1

view.floor XYZ =
| less $zfix: leave XYZ.2
| if $key{edit_over_empty} then $site.floor_void{XYZ} else $site.floor{XYZ}

view.input In =
//| when $paused: leave
| case In
  [mice_move _ XY]
    | $mice_xy.init{XY}
    | less $mice_click: $mice_xy_anchor.init{XY}
    | CX,CY = $viewToSite{$mice_xy}
    | when $brush.0 or $site.human.sight.CY.CX:
      | less ($mice_click><left or $mice_click><pick) and not $brush.0:
        | $cursor.init{[CX CY $cursor.2]}
        | $cursor.2 <= $floor{$cursor}
        | NewZ = $cursor.2
        | while NewZ and NewZ>>$zlock:
          | $cursor.2 <= NewZ
          | NewZ <= $site.down{$cursor}
        | NewZ = $cursor.2
        | while NewZ and NewZ<<$zlock:
          | $cursor.2 <= NewZ
          | NewZ <= $site.up{$cursor}
        | Ds = [[1 0] [0 1] [-1 0] [0 -1]]
        | X,Y,NewZ = $cursor
        | while NewZ>$zlock+1:
          | less Ds.all{[XD YD] => $site.at{X+XD Y+YD NewZ}.empty}:
            | $cursor.2 <= NewZ
          | NewZ--
  [mice left State XY]
    | LMB_Count++
    | $zfix <= 1
    | $mice_click <= if State then \left else \leftup
    | if State then $anchor.init{$cursor}
      else when $site.at{@$cursor}.empty: $cursor.2 <= $floor{$cursor}
    | when State: $mice_xy_anchor.init{XY}
  [mice right State XY]
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
