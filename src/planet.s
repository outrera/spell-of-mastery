use gui util widgets stack

type planet_site{Id Planet}
  planet/Planet //planet this sites belongs to
  id/Id // numeric id, which can be reused
  serial //serial guaranteed to be unique for the duration of the game
  type //city, lair, base, monsters
  turn //turn this place came to live
  name
  xy/[-1 -1]
  data

planet_site.rect =
| C = $planet.siteC
| [$xy.0-C $xy.1-C C*2 C*2]

type planet.widget{Main UI W H}
  main/Main
  ui/UI
  w/W
  h/H
  mice_xy/[0 0]
  seed
  serial
  bg
  fg_site
  fow
  turn
  sites
  all_sites
  free_sites
  siteC/8
  param
| $param <= $main.params.planet
| MaxSites = $param.max_sites
| $all_sites <= MaxSites{(planet_site ? Me)}
| $sites <= stack MaxSites
| $free_sites <= stack $all_sites
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
| for S $sites: $free_sites.push{S}
| $sites.clear
| $turn <= 0
| $serial <= 0
| $seed <= LCG_M.rand
| $generate

planet.free_site S =
| S.xy.init{-1,-1}

planet.generate_site Type =
| X = 0
| Y = 0
| R = [0 0 0 0]
| C2 = $siteC*2
| _label again
| X = $rand{$w}
| Y = $rand{$h}
| R.init{[X Y C2 C2]}
| when Y>510 or X>$w-C2: _goto again
| for P $sites: when rects_intersect{R P.rect}: _goto again
| X += $siteC
| Y += $siteC
| S = $free_sites.pop
| S.type <= Type
| S.serial <= $serial++
| S.turn <= $turn
| S.xy.init{X,Y}
| $sites.push{S}
| S

planet.generate =
| for I $param.ncities: $generate_site{city}
| for I $param.nlairs: $generate_site{lair}

planet.pass_time =
| $turn += 1

planet.render = Me

planet.draw FB X Y =
| less $bg: $bg <= $img{planet_bg}
| less $fg_site: $fg_site <= $img{planet_site}
| FB.blit{0 0 $bg}
| C = $siteC
| for S $sites: when S.xy.0>0: FB.blit{S.xy.0-C S.xy.1-C $fg_site}

planet.site_at XY =
| C = $siteC
| for S $sites: when point_in_rect{[S.xy.0-C S.xy.1-C C*2 C*2] XY}:
  | leave S
| 0

planet.infoline =
| S = $site_at{$mice_xy}
| less S: leave "[$mice_xy]"
| "site([S.serial]): [S.type]"

planet.input In =
| case In
  [mice_move _ XY]
    | $mice_xy.init{XY}
  [mice left State XY]
    | $mice_xy.init{XY}
  [mice right State XY]
    | $mice_xy.init{XY}

export planet
