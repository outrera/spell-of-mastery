use gfx util

type main{Data}
     world
     data/Data
     tile_cursor
     rect_back
     rect_front
     cache/(t)
     cycle
     params
     sprites
     classes // object classes
     classes_banks
     bank_names
     tiles 
     acts
     editor_types
     tid_map/dup{1024 0}
     aux_tiles
| $load_params
| $load_sprites
| $load_classes
| $load_tiles
| $tile_cursor <= $img{"mice_tile"}
| $rect_back <= $img{"mice_rect_back"}
| $rect_front <= $img{"mice_rect_front"}
| for [Type Tile] $tiles: $tid_map.(Tile.id) <= Tile
| $bank_names <= $classes{}{?1}{?bank}.uniq.sort
| $classes_banks <= @table: map N $bank_names
  | N,$classes{}{?1}.keep{?bank >< N}{?class_name}.sort

main.img Name =
| S = $sprites."[Name]"
| less got S: bad "missing image `[Name]`"
| S.frames.0

main.spr Name =
| S = $sprites."[Name]"
| less got S: bad "missing sprite `[Name]`"
| S


export main
