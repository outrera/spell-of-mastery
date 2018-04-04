use gui util widgets stack

type world_site{Id Planet}
  world/Planet //world this sites belongs to
  id/Id // numeric id, which can be reused
  serial //serial guaranteed to be unique for the duration of the game
  type //city, ruin, lair, base, enemy
  turn //turn this place came to live
  name
  xy/[-1 -1]
  data

world_site.rect =
| C = $world.siteC
| [$xy.0-C $xy.1-C C*2 C*2]

type world.widget{Main UI W H}
  main/Main
  ui/UI
  w/W
  h/H
  mice_xy/[0 0]
  click_xy/[0 0]
  seed
  serial
  bg
  fg_site
  fg_picked
  fow
  turn
  sites
  all_sites
  free_sites
  picked //picked site
  siteC/8
  param
| $param <= $main.params.world
| MaxSites = $param.max_sites
| $all_sites <= MaxSites{(world_site ? Me)}
| $sites <= stack MaxSites
| $free_sites <= stack $all_sites
| $clear

LCG_M = 2147483647
LCG_M_F = LCG_M.float
LCG_A = 16807
LCG_B = 0

world.rand Size =
| $seed <= ($seed*LCG_A + LCG_B) % LCG_M
| @int: @round: $seed.float*Size.float/LCG_M_F

world.img Name = $main.img{Name}

world.clear =
| for S $sites: $free_sites.push{S}
| $sites.clear
| $picked <= 0
| $turn <= 0
| $serial <= 1
| $seed <= LCG_M.rand
| $generate

world.free_site S =
| S.xy.init{-1,-1}

world.generate_site Type =
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

world.generate =
| for I $param.ncities: $generate_site{city}

world.pass_time =
| $turn += 1

world.render = Me

world.draw FB X Y =
| less $bg: $bg <= $img{world_bg}
| less $fg_site: $fg_site <= $img{world_site}
| less $fg_picked: $fg_picked <= $img{world_picked}
| FB.blit{0 0 $bg}
| Clock = clock
| PickBlink = (Clock-Clock.int.float)<0.25
| C = $siteC
| PickedId = if $picked then $picked.id else -1
| for S $sites: when S.xy.0>0:
  | G = if S.id <> PickedId or
           (PickBlink and not point_in_rect{S.rect $mice_xy})
        then $fg_site
        else $fg_picked
  | FB.blit{S.xy.0-C S.xy.1-C G}

world.site_at XY =
| C = $siteC
| for S $sites: when point_in_rect{[S.xy.0-C S.xy.1-C C*2 C*2] XY}:
  | leave S
| 0

world.infoline =
| S = $site_at{$mice_xy}
| less S: leave "[$mice_xy]"
| "site([S.serial]): [S.type]"

world.input In =
| case In
  [mice_move _ XY]
    | $mice_xy.init{XY}
  [mice left State XY]
    | $mice_xy.init{XY}
    | when State: leave
    | S = $site_at{$mice_xy}
    | $picked <= 0
    | when S: $picked <= S
  [mice right State XY]
    | $mice_xy.init{XY}

export world
