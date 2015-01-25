use param sprite class tile world game ui

type main{Data}
     world
     data/Data
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
     last_tid
     tid_map
     aux_tiles
| $load_params
| for K,V $params.main: $params.K <= V
| $load_sprites
| $load_classes
| $load_tiles
| $tid_map <= dup $last_tid+1 0
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


Main = main: main_root
World = world Main 16
Game = game Main World

run_ui Main

say 'Succeed!'
