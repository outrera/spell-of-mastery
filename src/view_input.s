use util action

view.worldToView P =
| X,Y = P - $view_origin
| RX = (X*$xunit - Y*$xunit)/2
| RY = (X*$yunit + Y*$yunit)/2
| [RX RY] + $blit_origin

view.viewToWorld P =
| X,Y = P - $blit_origin - [32 -32+$main.params.world.z_unit*4]
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
| [X Y U-X V-Y]

view.units_at XYZ = $world.units_at{XYZ}.skip{?mark}

view.update_brush =
| $cursor.2 <= $fix_z{$cursor}
| X,Y,Z = $cursor
| when $mice_click><left: case $brush
  [obj Bank,Type]
    | less Z << $anchor.2: leave
    | Mirror = $keys.m >< 1
    | ClassName = if $keys.r >< 1
                  then "[Bank]_[$main.classes_banks.Bank.rand]"
                  else "[Bank]_[Type]"
    | Class = $main.classes.ClassName
    | Place = 1
    | for XX,YY,ZZ Class.form: when Place:
      | XYZ = [X Y Z] + if Mirror then [-YY XX ZZ] else [XX -YY ZZ]
      | Us = $world.units_at{XYZ}.skip{?bank><mark}
      | Place <= if XYZ.any{?<0} then 0
                 else if not Class.empty then Us.all{?empty}
                 else if $keys.r >< 1 then Us.end
                 else not Us.any{?class^address >< Class^address}
    | when Place
      | U = $player.alloc_unit{ClassName}
      | Facing = if Mirror then 5 else 3
      | Reverse = $keys.n >< 1
      | when Reverse: Facing <= if Mirror then 1 else 6
      | U.pick_facing{Facing}
      | when $keys.t >< 1: U.facing <= 3.rand
      | U.move{X,Y,Z}
  [tile Type]
    | while 1
      | Z <= $cursor.2
      | less Z << $anchor.2 and $world.at{X Y Z}.empty: leave
      | Tile = $main.tiles.Type
      | less Tile.empty
        | for U $world.units_at{X,Y,Z}: U.move{X,Y,Z+Tile.height}
      | $world.set{X Y Z $main.tiles.Type}
      | when Tile.empty and (Tile.id><0 or $keys.e<>1): leave
      | $cursor.2 <= $fix_z{$cursor}
| when $mice_click><right:
  | Brush = $brush
  | T = $world.at{X Y Z-1}
  | Us = $units_at{X,Y,Z}
  | when T.unit and not Us.size:
    | ZZ = Z - T.height
    | BelowUs = $units_at{X,Y,ZZ}
    | when BelowUs.size:
      | $mice_click <= 0
      | for U BelowUs: U.free
      | leave
  | case Brush
    [obj Type]
      | for U Us: U.free
    [tile Type]
      | while 1
        | Z <= $cursor.2
        | less Z >> $anchor.2 and Z > 1: leave
        | less Z > 1: leave
        | Tile = $world.at{X Y Z-1}
        | less Tile.height: leave
        | $world.clear_tile{X,Y,Z-1 $world.void}
        | for U $world.units_at{X,Y,Z}: U.move{X,Y,Z-Tile.height}
        | $cursor.2 <= $fix_z{$cursor}

view.update_pick = //FIXME

view.update_play =
| Player = $player
| case $mice_click
  leftup | $mice_click <= \pick
  right | $mice_click <= \order
        | when $world.act:
          | $world.act <= 0
          | $mice_click <= 0
| when $keys.a><1:
  | for U $picked: when U.owner.id >< Player.id and U.xyz <> $cursor:
    | when U.damage: U.order_at{$cursor act/attack}
| $main.update

world.update_picked =
| for M $marks^uncons{mark}: M.free
| $marks <= $nil
| Picked = $human.picked
| when Picked.size <> 1: leave
| U = Picked.0
| Marks =
  if $act and $act.range <> any then
    | Ms,Path = action_list_moves{U $act}
    | Ms = Ms.keep{X,Y,Z=>$seen{X Y}}
    | Path = Path.keep{X,Y,Z=>$seen{X Y}}
    | As = map XYZ Ms
      | Mark = $human.alloc_unit{"mark_magic_hit"}
      | Mark.move{XYZ}
      | Mark
    | Bs = map XYZ Path
      | Mark = $human.alloc_unit{"mark_magic"}
      | Mark.move{XYZ}
      | Mark
    | [@As @Bs]
  else if U.path then
    | map XYZ U.path{}{?unheap}
      | MarkType = \move
      | B = $block_at{XYZ}
      | when got B:
        | MarkType <= if B.owner.is_enemy{U.owner}
                      then \attack
                      else \swap
      | Mark = $human.alloc_unit{"mark_[MarkType]"}
      | Mark.move{XYZ}
      | Mark
  else []
| $marks <= [$nil @Marks]^cons{mark}

world.update_cursor CXYZ Brush Mirror =
| Marks = $marks^uncons{mark}.flip
| P = $human
| if $act
  then | when $act.affects<>unit:
         | push P.alloc_unit{mark_cursor_target}.move{CXYZ} Marks
  else when $view.mode<>play:
       | push P.alloc_unit{mark_cursor0}.move{CXYZ} Marks
       | push P.alloc_unit{mark_cursor1}.move{CXYZ} Marks
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
      | when Place: push P.alloc_unit{mark_cube}.move{XYZ} Marks
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
    | $mice_xy.init{XY}
    | less $mice_click: $mice_xy_anchor.init{XY}
    | CX,CY = $viewToWorld{$mice_xy}
    | when $mode <> play or $world.human.sight.CY.CX:
      | $cursor.init{[CX CY $cursor.2]}
      | $cursor.2 <= $fix_z{$cursor}
  [mice left State XY]
    | $zfix <= 1
    | $mice_click <= if State then \left else \leftup
    | if State then $anchor.init{$cursor} else $cursor.2 <= $fix_z{$cursor}
    | when State: $mice_xy_anchor.init{XY}
  [mice right State XY]
    | $zfix <= 1
    | $mice_click <= if State then \right else 0
    | if State then $anchor.init{$cursor} else $cursor.2 <= $fix_z{$cursor}
  [key Name S]
    | $keys.Name <= S
| when $mode <> play: $mice_xy_anchor.init{$mice_xy}

view.pause = $paused <= 1
view.unpause = $paused <= 0

view.wants_focus = 1
