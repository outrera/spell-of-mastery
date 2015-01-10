use gfx util

type main{Data} world data/Data sounds/"[Data]sounds"
                view_w/448 view_h/448 cursor rect_back rect_front
                cache/(t) cycle
                sprites classes tiles 
                acts  editor_types
                tid_map/dup{1024 0} aux_tiles
| $load_sprites
| $load_classes
| $load_tiles
| $cursor <= $img{"cursor"}
| $rect_back <= $img{"rect_back"}
| $rect_front <= $img{"rect_front"}
//| $acts <= $load_types{act "[$data]/act/"}
//| $obj_types <= $load_types{act "[$data]/obj/"}
| for [Type Tile] $tiles: $tid_map.(Tile.id) <= Tile


main.img Name =
| S = $sprites."images_[Name]"
| less got S: bad "missing sprites/images/[Name].png"
| S.frames.0

export main
