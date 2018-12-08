use site gfx sprite unit_flags enheap ui widgets gui main_data

type main{Data}
     site
     data/Data
     cache/(t)
     cfg
     acts
     sprites
     classes // object classes
     classes_banks
     bank_names
     tiles 
     editor_types
     last_tid
     tid_map
     aux_tiles
     sounds
     ui
     credits
     unit_effects_sprite
| say 'init heap'
| enheap_init 64000
| $credits <= t
| say 'loading configuration'
| $load_configuration
| for K,V $cfg.main: $cfg.K <= V //easies access
| say 'loading sprites'
| $load_sprites
| say 'loading sounds'
| $load_sounds
| say 'loading tiles'
| $load_tiles
| say 'loading classes'
| $load_classes
| say 'post init'
| for K,V $acts: less V.icon_gfx:
  | IName = V.icon
  | IName = if IName.is_text then "icons_[IName]" else IName.1
  | V.icon_gfx <= $img{IName}
| $tid_map <= dup $last_tid+1 0
| for [Type Tile] $tiles: $tid_map.(Tile.id) <= Tile
| $bank_names <= $classes{}{?1}{?bank}.uniq.sort
| $classes_banks <= @table: map N $bank_names
  | N,$classes{}{?1}.keep{(?bank >< N and not ?aux)}{?class_name}.sort
| $prepare_credits
//| $sprites.unit_cyclops.save{frames "work/sd/cyclops"}; halt
//| $sprites.unit_horse.save{sheet "work/sd/horse"}; halt
| $init_unit_flags
| site Me


main.run =
| set_main Me
| $ui <= ui Me
| $ui.init
| gui $ui cursor/$img{ui_cursor_point}

export main
