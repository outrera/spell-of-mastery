use gui util widgets

type place{Type XY} type xy/XY data

type planet.widget{Main UI W H}
  main/Main
  ui/UI
  w/W
  h/H
  seed
  bg
  fg_place
  fow
  places/[]
  events/[]
| $clear

LCG_M = 2147483647
LCG_M_F = LCG_M.float
LCG_A = 16807
LCG_B = 0

planet.rand Size =
| $seed <= ($seed*LCG_A + LCG_B) % LCG_M
| @int: @round: $seed.float*Size.float/LCG_M_F

planet.img Name = $main.img{Name}

planet.infoline = "planet.infoline: FIXME"

planet.clear =
| $places <= []
| $seed <= LCG_M.rand
| $generate

planet.generate_place =
| place 0 [$rand{$w} $rand{$h}]

planet.generate =
| NPlaces = 10
| for I NPlaces:
  | push $generate_place $places

planet.pass_time =

planet.render = Me

planet.draw FB X Y =
| less $bg: $bg <= $img{planet_bg}
| less $fg_place: $fg_place <= $img{planet_place}
| FB.blit{0 0 $bg}
| for P $places: FB.blit{P.xy.0 P.xy.1 $fg_place}

export planet
