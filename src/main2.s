use world gfx sprite_dump unit_flags enheap

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
     acts //obsolete?
     editor_types
     last_tid
     tid_map
     aux_tiles
     sounds
     ui
     credits
     effect
| enheap_init 64000
| $credits <= t
| $load_params
| for K,V $params.main: $params.K <= V
| $load_sprites
| $load_sounds
| $load_tiles
| $load_classes
| for K,V $params.acts: less V.icon_gfx:
  | IName = V.icon
  | IName = if IName.is_text then "icons_[IName]" else IName.1
  | V.icon_gfx <= $img{IName}
| $tid_map <= dup $last_tid+1 0
| for [Type Tile] $tiles: $tid_map.(Tile.id) <= Tile
| $bank_names <= $classes{}{?1}{?bank}.uniq.sort
| $classes_banks <= @table: map N $bank_names
  | N,$classes{}{?1}.keep{(?bank >< N and not ?aux)}{?class_name}.sort
| GCredits = $credits.graphics.list.sort{?0<??0}
| SCredits = $credits.sound.list.sort{?0<??0}
| GCreditsT = @text: map K,Vs GCredits: "  [K]\n"
| SCreditsT = @text: map K,Vs SCredits: "  [K]\n"
| $credits <= @text:
              ["SPELL OF MASTERY CREDITS\n\n"
               "Designed and Programmed by Nikita Sadkov\n\n\n"
               "GRAPHICS:\n" GCreditsT
               "\n\n\nSOUND:\n" SCreditsT
               "\n\n\nTHANKS TO:\n"
               "  Matthew Ostil\n"
              ]
//| sprite_dump Me "/Users/nikita/Downloads/0" staticFrame/100 sheet/1 unit_vampire
| init_unit_flags Me
| world Me

export main
