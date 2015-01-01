use gfx

type main{Data} world data/Data sounds/"[Data]sounds"
                view_w/448 view_h/448 cursor rect_back rect_front
                cache/(t) cycle
                acts obj_types unit_types editor_types
                tiles tid_map/dup{1024 0} aux_tiles
| $cursor <= gfx "[Data]/misc/cursor.png"
| $rect_back <= gfx "[Data]/misc/rect_back.png"
| $rect_front <= gfx "[Data]/misc/rect_front.png"
| $acts <= $load_types{act "[Data]/act/"}
| $obj_types <= $load_types{act "[Data]/obj/"}
| $unit_types <= $load_types{act "[Data]/units/"}
| $load_tiles
| for [Type Tile] $tiles: $tid_map.(Tile.id) <= Tile

main.load_types What Dir = 

export main
