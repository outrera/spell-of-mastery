use gui util widgets stack

type world_site{Id World}
  world/World //world this sites belongs to
  id/Id // numeric id, which can be reused
  serial //serial guaranteed to be unique for the duration of the game
  type //city, ruin, lair, base, party
  gfx //representation on world map
  turn //turn this site came to life
  name
  attacker/0
  xy/[-100 -100]
  state
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
  param
  data/(t)
  mode
  seed
  serial
  bg
  fg
  fow
  turn
  sites
  all_sites
  free_sites
  picked //picked site
  siteC/8
  siteLimX
  siteLimY/510
  incomeFactor
| $param <= $main.params.world
| $bg <= $img{world_bg}
| $siteLimX <= $bg.w
| $fg <= @table: map N [site picked base city lair party ruin attack]
  | [N $img{"world_fg_[N]"}]
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

world.notify Msg = $ui.notify{Msg}

world.clear =
| for S $sites: $free_sites.push{S}
| for K,V $data.list: $data.K <= No
| $sites.clear
| $picked <= 0
| $turn <= 0
| $mode <= 0
| $serial <= 1
| $incomeFactor <= 100
| $seed <= LCG_M.rand
| $generate

world.free_site S =
| when $picked and $picked.id><S.id: $picked <= 0
| Type = S.type
| $data."cnt_[Type]" <= $data."cnt_[Type]"^~{No 0}-1
| S.xy.init{-100,-100}
| $free_sites.push{S}

world.can_place Type XY =
| X,Y = XY
| less Y<$siteLimY: leave 0
| less X<$siteLimX: leave 0
| when X>$w-$siteC: leave 0
| C2 = $siteC*2
| R = [X-$siteC Y-$siteC C2 C2]
| for S $sites: when rects_intersect{R S.rect}: leave 0
| 1

world.generate_xy Type =
| X = 0
| Y = 0
| _label again
| X <= $rand{$w-$siteC}+$siteC
| Y <= $rand{$h-$siteC}+$siteC
| less $can_place{Type X,Y}: _goto again
| X,Y

world.generate_site Type xy/0 =
| Lim = 
| less $data."cnt_[Type]"^~{No 0}<$param."lim_[Type]"^~{No 1000}:
  | leave 0
| less $free_sites.used: leave 0 //FIXME: should we halt the game?
| X,Y = if Xy then Xy else $generate_xy{Type}
| S = $free_sites.pop
| S.type <= Type
| S.serial <= $serial++
| S.turn <= $turn
| S.xy.init{X,Y}
| S.gfx <= $fg.Type
| S.attacker <= 0
| S.state <= 0
| when no S.gfx: S.gfx <= $fg.site
| $sites.push{S}
| $data."cnt_[Type]" <= $data."cnt_[Type]"^~{No 0}+1
| S

world.generate =
| for I $param.start_cities: $generate_site{city}

world.end_turn =
| for S $sites:
  | when S.type >< city and S.attacker:
    | $free_site{S.attacker}
    | X,Y = S.xy
    | $free_site{S}
    | R = $generate_site{ruin xy/[X Y]}
| Ss = $sites.list
| $sites.clear
| Lairs = []
| Cities = []
| Bases = []
| Ruins = []
| Parties = []
| for S Ss: when S.xy.0>0
  | when S.type><base: push S Bases
  | when S.type><lair: push S Lairs
  | when S.type><city: push S Cities
  | when S.type><ruin: push S Ruins
  | when S.type><party: push S Parties
  | $sites.push{S}
| $turn += 1
| $incomeFactor <= Cities.size*100/(Cities.size+Ruins.size)
| for P Parties: less P.state:
  | C = Cities.find{?attacker^not}
  | when got C:
    | C.attacker <= P
    | P.state <= \raid
| LSLC = $param.lair_spawn_lair_chance
| LSMC = $param.lair_spawn_monster_chance
| LH = $param.lair_handicap
| for L Lairs:
  | A = $turn - L.turn
  | when $rand{5}<A and $rand{100}<LSMC: $generate_site{party}
  | when $rand{LH}<A and $rand{100}<LSLC: $generate_site{lair}
| when $rand{100}<LSMC: $generate_site{party}
| when $rand{max{1 LH/2}}<$turn and $rand{100}<LSLC: $generate_site{lair}
| $notify{"Turn [$turn]"}

world.render =
| less $mode: get_gui{}.cursor <= $img{ui_cursor_point}
| when $mode><newBase:
  | Can = $can_place{base $mice_xy}
  | Cur = if Can then \ui_cursor_target else \ui_cursor_target2
  | get_gui{}.cursor <= $img{Cur}
| Me

world.draw FB X Y =
| FB.blit{0 0 $bg}
| Clock = clock
| PickBlink = (Clock-Clock.int.float)<0.25
| C = $siteC
| PickedId = if $picked then $picked.id else -1
| for S $sites: when S.xy.0>0 and S.state <> raid:
  | G = if S.id <> PickedId or
           (PickBlink and not point_in_rect{S.rect $mice_xy})
        then if S.attacker then $fg.attack else S.gfx
        else $fg.picked
  | FB.blit{S.xy.0-C S.xy.1-C G}

world.site_at XY =
| C = $siteC
| for S $sites: when point_in_rect{S.rect XY}:
  | leave S
| 0

world.base_placement =
| less $data."cnt_base"^~{No 0}<$param."lim_base"^~{No 1000}:
  | $notify{"We are too stretched to build any more bases."}
  | leave
| $mode <= \newBase

world.infoline =
| S = $site_at{$mice_xy}
| less S: leave "[$mice_xy]"
| "site([S.serial]): [S.type]"


world.mode_pick M =
| when M><newBase:
  | less $can_place{base $mice_xy}:
    | $notify{"Can't place new base here."}
    | leave newBase
  | $generate_site{base xy/$mice_xy}
  | leave 0
| leave 0


world.input In =
| case In
  [mice_move _ XY]
    | $mice_xy.init{XY}
  [mice left State XY]
    | $mice_xy.init{XY}
    | when State: leave
    | when $mode:
      | $mode <= $mode_pick{$mode}
      | leave
    | S = $site_at{$mice_xy}
    | $picked <= 0
    | when S: $picked <= S
    | $ui.site_picked{S}
  [mice right State XY]
    | $mode <= 0
    | $mice_xy.init{XY}

export world
