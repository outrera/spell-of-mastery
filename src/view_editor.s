use macros util gui

site.update_cursor_brush Bank Type CXYZ =
| View = $view
| Mirror = View.key{edit_place_mirrored}
| Reverse = View.key{edit_place_reversed}
| ClassName = "[Bank]_[Type]"
| Class = $main.classes.ClassName
| XYZ = CXYZ //+ if Mirror then [-Y X Z] else [X -Y Z]
| when XYZ.0<0 or XYZ.1<0: leave 0
| Us = $units_get{XYZ}
| when Class.unit and Us.any{?unit}: leave 0
| when Us.any{?class^address >< Class^address}: leave 0
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
  
site.place_struct XYZ Tile =
| XX,YY,ZZ = XYZ
| Tiles = Tile.structTiles
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

site_place_tile Me X Y Z Tile =
| when X<1 or Y<1 or X>$w or Y>$h: leave
| $set{X Y Z Tile}
| for U $units_get{X,Y,Z}: U.move{X,Y,Z+Tile.height}

AnchorHack = -1

view.place_tile Type =
| when $cursor.2<>$zlock: $cursor.2 <= $floor{$cursor}
| Tile = $main.tiles.Type
| when Tile.struct:
  | $site.place_struct{$cursor Tile}
  | $mice_click <= 0
  | X,Y,Z = $cursor
  | till $site.at{X Y Z}.empty: Z++
  | $cursor.2 <= Z
  | leave
| X,Y,Z = $cursor
| IsBridge = $key{edit_bridge}
| IsEmpty = $key{edit_over_empty} or Tile.empty
| IsEmbed = $key{edit_place_embed}
| when IsBridge
  | EmptyTile = $main.tiles.void
  | when $lmb_count<>AnchorHack:
    | AZ = max 1 $anchor.2-Tile.height
    | $anchor.2 <= AZ
    | AnchorHack <= $lmb_count
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
      | when $cursor.2<<$anchor.2:
        | Below = $site.at{X Y $cursor.2-1}
        | less Below.empty
          | $site.set{X Y $cursor.2-1 Tile}
          | leave
    else
      | when $site.at{X Y $cursor.2-1}.embed><1 and not Tile.embed: 
        | Z = $cursor.2-1
        | when AnchorHack<>$lmb_count:
          | $anchor.2 <= Z
          | AnchorHack <= $lmb_count
        | while Z>>0 and $site.at{X Y Z}.embed><1 and not Tile.embed:
          | $site.set{X Y Z-- Tile}
        | leave
  | AnchorHack <= $lmb_count
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
