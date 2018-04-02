use gui util widgets

type place{Planet Id Type XY}
  planet/Planet id/Id type/Type xy/XY data

place.rect =
| C = $planet.placeC
| [$xy.0-C $xy.1-C C*2 C*2]

type planet.widget{Main UI W H}
  main/Main
  ui/UI
  w/W
  h/H
  mice_xy/[0 0]
  seed
  bg
  fg_place
  fow
  turn
  places/[]
  events/[]
  placeC/8
| $clear

LCG_M = 2147483647
LCG_M_F = LCG_M.float
LCG_A = 16807
LCG_B = 0

planet.rand Size =
| $seed <= ($seed*LCG_A + LCG_B) % LCG_M
| @int: @round: $seed.float*Size.float/LCG_M_F

planet.img Name = $main.img{Name}


planet.clear =
| $places <= []
| $turn <= 0
| $seed <= LCG_M.rand
| $generate

planet.generate_place Id Ps =
| X = 0
| Y = 0
| R = [0 0 0 0]
| C2 = $placeC*2
| _label again
| X = $rand{$w}
| Y = $rand{$h}
| R.init{[X Y C2 C2]}
| when Y>510 or X>$w-C2: _goto again
| for P Ps: when rects_intersect{R P.rect}: _goto again
| X += $placeC
| Y += $placeC
| place Me Id 0 [X Y]

planet.generate =
| NPlaces = 200
| for I NPlaces:
  | push $generate_place{I $places} $places

planet.pass_time =
| $turn += 1

planet.render = Me

planet.draw FB X Y =
| less $bg: $bg <= $img{planet_bg}
| less $fg_place: $fg_place <= $img{planet_place}
| FB.blit{0 0 $bg}
| C = $placeC
| for P $places: FB.blit{P.xy.0-C P.xy.1-C $fg_place}


planet.infoline =
| M = $mice_xy
| C = $placeC
| for P $places: when point_in_rect{[P.xy.0-C P.xy.1-C C*2 C*2] M}:
  | leave "place([P.id]): [P.type]"
| "[M]"

planet.input In =
| case In
  [mice_move _ XY]
    | $mice_xy.init{XY}
  [mice left State XY]
    | $mice_xy.init{XY}
  [mice right State XY]
    | $mice_xy.init{XY}

export planet
