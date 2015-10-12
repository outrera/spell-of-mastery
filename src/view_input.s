use util action

view.worldToView P =
| [X Y] = P - $view_origin
| RX = (X*$xunit - Y*$xunit)/2
| RY = (X*$yunit + Y*$yunit)/2
| [RX RY] + $blit_origin

view.viewToWorld P =
| [X Y] = P - $blit_origin - [0 $main.params.world.z_unit*4]
| !X - 32
| WH = $xunit*$yunit
| RX = (Y*$xunit + X*$yunit)/WH
| RY = (Y*$xunit - X*$yunit)/WH
| [RX RY] = [RX RY] + $view_origin
| [RX.clip{1 $world.w} RY.clip{1 $world.h}]

view.mice_rect =
| [AX AY] = if $anchor then $anchor else $mice_xy
| [BX BY] = $mice_xy
| X = min AX BX
| Y = min AY BY
| U = max AX BX
| V = max AY BY
| [X Y U-X V-Y]

world.update_pick Units =
| for U $picked^uncons{picked}: U.picked <= 0
| $picked <= Units^cons{picked}

view.select_unit XYZ = 
| less $world.seen{XYZ.0 XYZ.1}: leave 0
| Picked = []
| X,Y,Z = XYZ
| Us = $world.column_units_at{X Y}.skip{?bank><mark}.keep{?fix_z><Z}
| when $mode >< play: Us <= Us.keep{?pickable}
| when not $world.picked or $world.picked.xyz <> XYZ: $pick_count <= 0
| when Us.size
  | !$pick_count+1
  | Picked <= [Us.($pick_count%Us.size)]
| $world.update_pick{Picked}

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
      | U = $world.alloc_unit{ClassName}
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
  | when T.unit: Brush <= [obj dummy]
  | case Brush
    [obj Type]
      | Us = $units_at{X,Y,Z}
      | BelowUs = []
      | when T.unit:
        | !Z-T.height
        | BelowUs <= $units_at{X,Y,Z}
        | when BelowUs.size: $mice_click <= 0
      | less Us.size: Us <= BelowUs
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

view.update_pick =
| when $mice_click >< left: $select_unit{$cursor}
| $mice_click <= 0
| Picked = $world.picked
| less Picked: Picked <= $world.nil
| $on_unit_pick{}{Picked}
  // FIXME: following line is outdated
| $main.update //ensures deleted units get updated

action_list_moves Me Picked Act =
| A = action Picked
| A.init{@Act.list.join}
| Affects = Act.affects
| Path = []
| Moves = []
| R = Act.range
| less got R: leave Moves
| PXYZ = Picked.xyz
| Points = if R.is_int then points_in_circle R else points_in_matrix R.tail
| for X,Y Points
  | XYZ = PXYZ+[X Y 0]
  | X = XYZ.0
  | Y = XYZ.1
  | when X>0 and X<<$w and Y>0 and Y<<$h:
    | XYZ.2 <= $fix_z{XYZ}
    | Target = $block_at{XYZ}^~{No 0}
    | Valid = 1
    | when Target and Affects >< empty: Valid <= 0
    | when not Target and Affects >< unit: Valid <= 0
    | A.xyz.init{XYZ}
    | A.target <= Target
    | if Valid and A.valid
      then push XYZ Moves
      else push XYZ Path
| [Moves Path]

update_lmb Me Player =
| less $world.act:
  | $select_unit{$cursor}
  | leave
| Picked = $world.picked
| less Picked.id and Picked.owner.id >< Player.id:
  | $world.act <= 0
  | leave
| less $world.seen{@$cursor.take{2}}: leave
| Act = $world.act.deep_copy
| less Act.range >< any
  | Ms = action_list_moves{$world Picked Act}.0
  | when no Ms.find{$cursor}: leave
| Act.target <= if Act.affects><land then 0
                else $world.block_at{$cursor}^~{No 0}
| when Act.fix_z><caster: $cursor.2 <= Picked.xyz.2
| Act.at <= $cursor
| Picked.order.init{@Act.list.join}
| $world.act <= 0

update_rmb Me Player =
| when $world.act:
  | $world.act <= 0
  | leave
| less $world.seen{@$cursor.take{2}}: leave
| Picked = $world.picked
| when Picked.id and Picked.owner.id >< Player.id:
  | $world.picked.guess_order_at{$cursor}

view.update_play =
| Player = $world.player
| when $keys.q><1:
  | $keys.q <= 0
  | Player.human <= not Player.human 
  | leave $update_play
| if not $world.picked.idle or $world.waiting then
  else if not Player.human then
    | $on_unit_pick{}{$world.nil}
    | Player.ai.update
  else
  | case $mice_click
    left | update_lmb Me Player
    right | update_rmb Me Player
  | $mice_click <= 0
  | Picked = $world.picked
  | less Picked: Picked <= $world.nil
  | $on_unit_pick{}{Picked}
| $main.update


install_pushables Me XYZ =
| Ps = []
| Ms = []
| for D Dirs:
  | B = $block_at{XYZ+[@D 0]}
  | when got B and B.movable:
    | P = B.xyz.deep_copy
    | B.remove
    | M = $alloc_unit{"unit_pushable" owner/$players.0}
    | M.move{P}
    | push [P B] Ps
    | push M Ms
| [Ps Ms]

uninstall_pushables Me Ps,Ms =
| for M Ms: M.free
| for [P B] Ps: B.move{P}

world.update_picked = 
| SanitizedPicked = $picked^uncons{picked}.skip{?removed}
| $picked <= [$nil @SanitizedPicked]^cons{picked}
| for M $marks^uncons{mark}: M.free
| $marks <= $nil
| Picked = $picked
| less Picked and Picked.moves and Picked.moved<$turn:
  | Picked <= 0
| when Picked and Picked.picked and Picked.action.type >< idle:
  | Saved = install_pushables Me Picked.xyz
  | Marks = if $act and $act.range <> any
    then | Ms,Path = action_list_moves{Me Picked $act}
         | Ms = Ms.keep{X,Y,Z=>$seen{X Y}}
         | Path = Path.keep{X,Y,Z=>$seen{X Y}}
         | As = map XYZ Ms
           | Mark = $alloc_unit{"mark_magic_hit"}
           | Mark.move{XYZ}
           | Mark
         | Bs = map XYZ Path
           | Mark = $alloc_unit{"mark_magic"}
           | Mark.move{XYZ}
           | Mark
         | [@As @Bs]
    else Picked.mark_moves
  | uninstall_pushables Me Saved
  | $marks <= [$nil @Marks]^cons{mark}

world.update_cursor CXYZ Brush Mirror =
| Marks = $marks^uncons{mark}.flip
| if $act
  then | push $alloc_unit{mark_cursor_target}.move{CXYZ} Marks
  else | push $alloc_unit{mark_cursor0}.move{CXYZ} Marks
       | push $alloc_unit{mark_cursor1}.move{CXYZ} Marks
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
      | when Place: push $alloc_unit{mark_cube}.move{XYZ} Marks
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
    | !XY+[0 32]
    | $mice_xy.init{XY}
    | CX,CY = $viewToWorld{$mice_xy}
    | when $mode <> play or $world.human.sight.CY.CX:
      | $cursor.init{[CX CY $cursor.2]}
      | $cursor.2 <= $fix_z{$cursor}
  [mice left State XY]
    | $zfix <= 1
    | $mice_click <= if State then \left else 0
    | if State then $anchor.init{$cursor} else $cursor.2 <= $fix_z{$cursor}
  [mice right State XY]
    | $zfix <= 1
    | $mice_click <= if State then \right else 0
    | if State then $anchor.init{$cursor} else $cursor.2 <= $fix_z{$cursor}
  [key Name S]
    | $keys.Name <= S

view.pause = $paused <= 1
view.unpause = $paused <= 0

view.wants_focus = 1
