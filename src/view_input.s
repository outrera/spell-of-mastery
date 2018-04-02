use macros util gui

PickCount = 0

order_at Me XYZ Target =
| Player = $player
| Us = $picked.keep{U => U.owner.id >< Player.id}
| when Us.size: $world.visual{XYZ ack}
| Us = Us{U=>[(XYZ-U.xyz).abs U]}.sort{?0<??0}{?1}
| Used = []
| less Target and Target.owner.is_enemy{Player}: Target <= 0
| Cell = $world.cell{@XYZ}
| when Us.size><1: less Target:
  | Below = (Cell-1).tile
  | when Below.unit and (Cell-Below.height).block.ai><remove:
    | U = Us.0
    | XYZ = Cell.xyz
    | U.order_at{XYZ 0}
    | leave
| for U Us:
  | P = Cell
  | less Target: less Used.end:
    | Found = $world.find{1000 U Cell | Dst => no Used.find{Dst}}
    | when Found: P <= Found
  | U.order_at{P.xyz 0}
  | push P Used

view.handle_picked_act2 Actor Act XYZ Target =
| when Target: $world.blink.init{[4 Target]}
| when Act.menu:
  | when Act.onMenu: Actor.effect{Act.onMenu Target XYZ}
  | Actor.set{menu [Act.name XYZ if Target then Target.serial else No]}
  | leave
| Actor.set{menuact Actor.get{menu}}
| Actor.strip{menu}
| Actor.order_at{(Target or XYZ) Act}

view.handle_picked_act Target =
| less $mice_click><pick:
  | when $world.act.check.unit:
    | Cur = if Target then \ui_cursor_target else \ui_cursor_target2
    | get_gui{}.cursor <= $main.img{Cur}
  | leave
| [Actor ActUnitOldSerial] = $world.act_unit
| when Actor.serial><ActUnitOldSerial: //is actor alive?
  | $handle_picked_act2{Actor $world.act $cursor Target}
| $world.act <= 0
| $mice_click <= 0

view.handle_picked Rect Units =
| $ui.on_unit_pick{$picked}
| Player = $player
| Units = Units.keep{U=>Player.seen{U.xyz}}
| Target = if Units.end then 0 else Units.0
| when $world.act:
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
    | if not Target then order_at Me $cursor 0
      else | $world.blink.init{[4 Target]}
           | order_at Me Target.xyz Target
  | leave
| when $mice_click >< pick:
  | $mice_click <= 0
  | Picked = []
  | NewPicked = Units
  | when Rect:
    | $picked <= [@NewPicked @Picked]
    | leave
  | when NewPicked.size>1:
    | NewPicked <= [NewPicked.(PickCount%NewPicked.size)]
    | PickCount++
  | less NewPicked.end: $main.sound{ui_click}
  | $picked <= [@NewPicked @Picked]
  | leave

view.handle_pick UnitRects =
| Units = []
| when@@it $world.cell{@$cursor}.block: Units <= [it]
| $handle_picked{0 Units}

view.worldToView P =
| X,Y = P - $view_origin
| RX = (X*$xunit - Y*$xunit)/2
| RY = (X*$yunit + Y*$yunit)/2
| [RX RY] + $blit_origin

view.viewToWorld P =
| X,Y = P - $blit_origin - [$yunit -$yunit+$zunit]
| WH = $xunit*$yunit
| RX = (Y*$xunit + X*$yunit)/WH
| RY = (Y*$xunit - X*$yunit)/WH
| [RX RY] = [RX RY] + $view_origin
| [RX.clip{1 $world.w} RY.clip{1 $world.h}]

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

view.units_get XYZ = $world.units_get{XYZ}.skip{?mark}

LMB_Count = 0
AnchorHack = -1

place_object Me Bank Type =
| X,Y,Z = $cursor
| less Z << $anchor.2: leave
| Cell = $world.cell{X Y Z}
| Mirror = $key{edit_place_mirrored}
| PlaceRandom = $key{edit_place_random}
| ClassName = if PlaceRandom
              then "[Bank]_[$main.classes_banks.Bank.rand]"
              else "[Bank]_[Type]"
| Class = $main.classes.ClassName
| when Class.item><1:
  | Cell.add_item{ClassName 1}
  | leave
| when Z+Class.height>>$world.d: leave
| Place = 1
| for XX,YY,ZZ Class.form: when Place:
  | XYZ = [X Y Z] + if Mirror then [-YY XX ZZ] else [XX -YY ZZ]
  | Us = $world.units_get{XYZ}.skip{?bank><mark}
  | Place <= if not $world.valid{@XYZ} then 0
             else if not Class.empty then Us.all{?empty}
             else if PlaceRandom then Us.end
             else not Us.any{?class^address >< Class^address}
  | when Place:
    | X,Y,Z = XYZ
    | H = if Class.passable then Class.height else 2
    | Place <= H.list.all{I=>$world.get{X,Y,Z+I}.empty}
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

world_place_tile_walls Me X Y Z Tile =
| Wall = $main.tiles.(Tile.wall)
| for DX,DY Dirs:
  | XX = X+DX
  | YY = Y+DY
  | DTile = $at{XX YY Z}
  | when DTile.dig or DTile.empty:
    | when $at{XX YY Z-1}.type <> Wall.around:
      | $clear_tile{XX YY Z}
      | world_place_tile Me XX YY Z Wall

world_place_tile Me X Y Z Tile =
| when X<1 or Y<1 or X>$w or Y>$h: leave
| $set{X Y Z Tile}
| for U $units_get{X,Y,Z}: U.move{X,Y,Z+Tile.height}
| world_place_tile_deco Me X Y Z Tile

world_place_tile_deco Me X Y Z Tile =
| when Tile.roof.is_list:
  | H,RoofTile = Tile.roof
  | for DX,DY [0,0 @Dirs]:
    | world_place_tile Me X+DX Y+DY Z+H RoofTile
| when Tile.wall: world_place_tile_walls Me X Y Z Tile

place_tile Me Type =
| $cursor.2 <= $floor{$cursor}
| X,Y,Z = $cursor
| Tile = $main.tiles.Type
| IsBridge = $key{edit_bridge}
| IsEmpty = $key{edit_over_empty} or Tile.empty
| when IsBridge
  | EmptyTile = $main.tiles.void
  | when LMB_Count<>AnchorHack:
    | AZ = max 1 $anchor.2-Tile.height
    | $anchor.2 <= AZ
    | AnchorHack <= LMB_Count
  | Z = 0
  | while Z<$anchor.2:
    | when $world.at{X Y Z}.type >< void:
      | $world.set{X Y Z EmptyTile}
    | Z++
  | till $world.at{X Y Z}.empty: Z++
  | $cursor.2 <= Z
| less IsBridge
  | if Tile.embed then
      | when Tile.wall
        | Below = $world.at{X Y $cursor.2-1}
        | while $cursor.2 > 1 and (Below.around or Below.roof
                                   or Below.type><void):
          | H = $world.at{X Y $cursor.2-1}.height
          | $cursor.2 -= H
          | $anchor.2 <= $cursor.2
          | $world.clear_tile{@$cursor}
          | Below <= $world.at{X Y $cursor.2-1}
      | when $cursor.2<<$anchor.2:
        | Below = $world.at{X Y $cursor.2-1}
        | less Below.empty
          | $world.set{X Y $cursor.2-1 Tile owner/$world.human}
          | world_place_tile_deco $world X Y $cursor.2 Tile
          | leave
    else
      | when $world.at{X Y $cursor.2-1}.embed: 
        | Z = $cursor.2-1
        | when AnchorHack<>LMB_Count:
          | $anchor.2 <= Z
          | AnchorHack <= LMB_Count
        | while Z>>0 and $world.at{X Y Z}.embed:
          | $world.set{X Y Z-- Tile owner/$world.human}
        | leave
  | AnchorHack <= LMB_Count
| while 1
  | Z <= $cursor.2
  | less Z << $anchor.2 and $world.at{X Y Z}.empty: leave
  | when Z+Tile.height>>$world.d: leave
  | world_place_tile $world X Y Z Tile
  | when Tile.empty:
    | when Tile.id><0: leave
    | when IsEmpty: leave
  | $cursor.2 <= $floor{$cursor}
  | when IsBridge: leave

remove_object_or_tile Me =
| X,Y,Z = $cursor
| Brush = $brush
| T = $world.at{X Y Z-1}
| Us = $units_get{X,Y,Z}
| when T.unit and not Us.size:
  | while $world.at{X Y Z}.type >< T.type: Z++
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
    | less $world.at{X Y Z}.empty: when Z>1
      | $world.clear_tile{X Y Z-1}
      | $cursor.2 <= Z-1
    | while 1
      | Z <= $cursor.2
      | less Z >> $anchor.2 and Z > 1: leave
      | less Z > 1: leave
      | Tile = $world.at{X Y Z-1}
      | less Tile.height: leave
      | $world.clear_tile{X Y Z-1}
      | $cursor.2 <= $floor{$cursor}
      | for U $world.units_get{X,Y,Z}: U.move{$cursor}

view.update_brush =
| when $mice_click><leftup or $mice_click><rightup:
  | $mice_click <= 0
  | leave
| when $mice_click><left: case $brush
  [obj Bank,Type] | place_object Me Bank Type
  [tile Type] | place_tile Me Type
| when $mice_click><right: remove_object_or_tile Me

view.update_play =
| less $brush.0: case $mice_click
  leftup | $mice_click <= \pick
  right | when $picked.size:
          | $mice_click <= \order
        | when $world.act:
          | $world.act <= 0
          | $mice_click <= 0
  rightup
    | $mice_click <= 0

world.update_picked =
| for M $marks: M.free
| $marks.heapfree
| $marks <= []
| less $human.picked.size: leave
| U = $human.picked.0
| less U.idle: leave
| Marks = []
| when $act:
  | when $act.range >< 9000: leave
  | UX,UY,UZ = U.xyz
  | for X,Y points_in_diamond{$act.range}
    | XX = UX+X
    | YY = UY+Y
    | when XX >> 1 and YY >> 1:
      | Cell = $cell{XX YY 1}
      | while Cell.z < $d-1:
        | if Cell.empty then
            | Mark = $human.alloc_unit{"mark_cast"}
            | Mark.move{Cell.xyz}
            | push Mark Marks
            | while Cell.z < $d-1 and Cell.empty: Cell++
          else
            | while Cell.z < $d-1 and not Cell.empty: Cell++
  | $marks <= Marks.enheap
  | leave
| for What,Cell U.reachable:
  | Mark = $human.alloc_unit{"mark_[What]"}
  | Mark.move{Cell.xyz}
  | push Mark Marks
| $marks <= Marks.enheap

world.update_cursor =
| View = $view
| CXYZ = View.cursor
| Marks = $marks.unheap
| P = $human
| if $act
  then | push P.alloc_unit{mark_cursor_target}.move{CXYZ} Marks
  else | push P.alloc_unit{mark_cursor0}.move{CXYZ} Marks
       | push P.alloc_unit{mark_cursor1}.move{CXYZ} Marks
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
      | M = P.alloc_unit{mark_cube}
      | M.sprite <= Class.default_sprite
      | M.animate{idle}
      | M.pick_facing{Facing}
      | M.move{XYZ}
      | M.alpha <= 110
      | push M Marks
| for M Marks: M.mark <= 1
| $marks.heapfree
| $marks <= Marks.enheap

view.update =
| case $key{pause} 1:
  | $paused <= not $paused
  | $key_set{pause 0}
  | $main.sound{pause}
| case $key{up} 1: $center_at{$center-[1 1 0]}
| case $key{down} 1: $center_at{$center+[1 1 0]}
| case $key{left} 1: $center_at{$center-[1 -1 0]}
| case $key{right} 1: $center_at{$center+[1 -1 0]}
//| $cursor.0 <= $cursor.0.clip{1 $world.w}
//| $cursor.1 <= $cursor.1.clip{1 $world.h}
| case $key{floor_down} 1:
  | NewZ = $world.down{$cursor}
  | when NewZ:
    | $cursor.2 <= NewZ
  | $zlock <= $cursor.2
  | $key_set{floor_down 0}
| case $key{floor_up} 1:
  | NewZ = $world.up{$cursor}
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
    | when $cursor.2<$world.d-2: $cursor.2++
    | $key_set{edit_up 0}
  | case $key{edit_zfix} 1:
    | $zfix <= 1
    | $key_set{edit_zfix 0}
| X,Y,Z = $cursor
| $world.update_picked
| $world.update_cursor
| when $brush.0: $update_brush
| $update_play
| less $paused: $main.update
| 1

view.floor XYZ =
| less $zfix: leave XYZ.2
| if $key{edit_over_empty} then $world.floor_void{XYZ} else $world.floor{XYZ}

view.input In =
//| when $paused: leave
| case In
  [mice_move _ XY]
    | $mice_xy.init{XY}
    | less $mice_click: $mice_xy_anchor.init{XY}
    | CX,CY = $viewToWorld{$mice_xy}
    | when $brush.0 or $world.human.sight.CY.CX:
      | less ($mice_click><left or $mice_click><pick) and not $brush.0:
        | $cursor.init{[CX CY $cursor.2]}
        | $cursor.2 <= $floor{$cursor}
        | NewZ = $cursor.2
        | while NewZ and NewZ>>$zlock:
          | $cursor.2 <= NewZ
          | NewZ <= $world.down{$cursor}
        | NewZ = $cursor.2
        | while NewZ and NewZ<<$zlock:
          | $cursor.2 <= NewZ
          | NewZ <= $world.up{$cursor}
        | Ds = [[1 0] [0 1] [-1 0] [0 -1]]
        | X,Y,NewZ = $cursor
        | while NewZ>$zlock+1:
          | less Ds.all{[XD YD] => $world.at{X+XD Y+YD NewZ}.empty}:
            | $cursor.2 <= NewZ
          | NewZ--
  [mice left State XY]
    | LMB_Count++
    | $zfix <= 1
    | $mice_click <= if State then \left else \leftup
    | if State then $anchor.init{$cursor}
      else when $world.at{@$cursor}.empty: $cursor.2 <= $floor{$cursor}
    | when State: $mice_xy_anchor.init{XY}
  [mice right State XY]
    | $zfix <= 1
    | $mice_click <= if State then \right else \rightup
    | if State then $anchor.init{$cursor}
      else when $world.at{@$cursor}.empty:
           | $cursor.2 <= $floor{$cursor}
           | $anchor.init{$cursor}
    | when State: $mice_xy_anchor.init{XY}
  [key Name S]
    | $keys.Name <= S
| when $brush.0: $mice_xy_anchor.init{$mice_xy}

view.pause = $paused <= 1
view.unpause = $paused <= 0

view.wants_focus = 1
