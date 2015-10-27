use gfx


sprite_dump Me DstPath Name staticFrame/128 bX/10 bY/10 sheet/1 =
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
| "[DstPath]/[Name].txt".set{Ls.flip.as_text}
| when Sheet: G.save{"[DstPath]/[Name].png"}
| less Sheet: for [R AnimName Dir XX,YY] Rs:
  | R.save{"[DstPath]/[Dir]-[AnimName]+[XX]+[YY].png"}


export sprite_dump