use world

type main{Data}
     world
     data/Data
     cache/(t)
     params
     sprites
     classes // object classes
     classes_banks
     bank_names
     tiles 
     acts
     editor_types
     last_tid
     tid_map
     aux_tiles
     sounds
     ui
| $load_params
| for K,V $params.main: $params.K <= V
| $load_sprites
| $load_sounds
| $load_tiles
| $load_classes
| $tid_map <= dup $last_tid+1 0
| for [Type Tile] $tiles: $tid_map.(Tile.id) <= Tile
| $bank_names <= $classes{}{?1}{?bank}.uniq.sort
| $classes_banks <= @table: map N $bank_names
  | N,$classes{}{?1}.keep{(?bank >< N and not ?aux)}{?class_name}.sort
| world Me

export main
