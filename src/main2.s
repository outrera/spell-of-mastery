use world gfx

dump_sprite Me DstPath Name =
| StaticFrame = 128 // force frame size
| BX = 10
| BY = 10
| S = Me.sprites.Name
| Rs = []
| WW = 1
| HH = 1
| when StaticFrame
  | WW <= StaticFrame
  | HH <= StaticFrame
| for F S.frames:
    | AnimName = F.0
    | G0 = F.1.3
    | G1 = F.1.6
    | for Dir,G [3,G0 6,G1]: when G:
      | X,Y,W,H = G.margins
      | less StaticFrame
        | max !WW W
        | max !HH H
      | R = G.cut{X Y W H}
      | GX,GY = G.xy
      | push [R AnimName Dir [GX-G.w/2 GY-G.h]+[X Y]+[W/2 H]] Rs
| N = Rs.size
| Order = [idle move attack death hit]
| Order = Order.keep{O =>
    got Rs.find{[_ AN @_]=>AN.size>>O.size and AN.take{O.size}><O}}
| MaxCol = 1
| for O Order: for D 3,6:
  | Xs = Rs.keep{?2><D}
  | Xs = Xs.keep{[_ AN @_]=>AN.size>>O.size and AN.take{O.size}><O}
  | max !MaxCol Xs.size
| W = Order.size*2*WW
| H = MaxCol*HH
| G = gfx W H
| G.clear{#FF000000} // transparent
| Col = 0
| Ls = []
| for O Order: for D 3,6:
  | Xs = Rs.keep{?2><D}
  | Xs = Xs.keep{[_ AN @_]=>AN.size>>O.size and AN.take{O.size}><O}
  | Xs = Xs.sort{?1<??1}
  | for Row,[R AnimName Dir XX,YY] Xs.i:
    | X = BX + Col*WW
    | Y = BY + Row*HH
    | G.blit{X Y R}
    | push ["[Dir]-[AnimName]+[XX]+[YY]" [X Y R.w R.h]] Ls
  | !Col+1
//| say Ls.flip
| G.save{"[DstPath]/[Name].png"}
| "[DstPath]/[Name].txt".set{Ls.flip.as_text}
//| for [R AnimName Dir XY] Rs:
  //| R.save{"[DstPath]/[Dir]-[AnimName].png"}

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
| $credits <= t
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
| dump_sprite Me "/Users/nikita/Downloads/1" unit_elf
| world Me

export main
