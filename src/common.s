use gfx util

type main{Data}
     world
     data/Data
     sounds/"[Data]sounds"
     cursor
     rect_back
     rect_front
     cache/(t)
     cycle
     sprites
     classes // object classes
     classes_banks
     bank_names
     tiles 
     acts
     editor_types
     tid_map/dup{1024 0}
     aux_tiles
| $load_sprites
| $load_classes
| $load_tiles
| $cursor <= $img{"cursor"}
| $rect_back <= $img{"rect_back"}
| $rect_front <= $img{"rect_front"}
//| $acts <= $load_types{act "[$data]/act/"}
| for [Type Tile] $tiles: $tid_map.(Tile.id) <= Tile
| $bank_names <= $classes{}{?1}{?bank}.uniq.sort
| $classes_banks <= @table: map N $bank_names
  | N,$classes{}{?1}.keep{?bank >< N}{?class_name}.sort

main.img Name =
| S = $sprites."images_[Name]"
| less got S: bad "missing sprites/images/[Name].png"
| S.frames.0

export main
