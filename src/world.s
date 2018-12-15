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

world_site.move XY =
| $xy.init{XY}

type world.widget{Main UI W H}
  main/Main
  ui/UI
  w/W
  h/H
  mice_xy/[0 0]
  click_xy/[0 0]
  cfg
  data/(t)
  mode
  seed
  turn_seed //prevents player from reloading to get different outcome
  serial
  bg
  mask
  fg
  fow
  turn
  sites
  all_sites
  free_sites
  picked //picked site
  siteC/16
  siteLimX
  siteLimY/510
  incomeFactor
  gold
  debt
  site_gold //gold when player entered the site
  tmap/(t) //terrain map
  sterra/(t) //allowed terrain for sites
| $cfg <= $main.cfg.world
| $bg <= $img{world_bg}
| $mask <= $img{world_bg_mask}
| $siteLimX <= $bg.w-$siteC
| $fg <= @table: map N [site picked attacked base city lair party ruin attack]
  | [N $img{"world_fg_[N]"}]
| for V,@Ks $cfg.tmap: for K Ks: $tmap.K <= V
| for K,@Vs $cfg.sterra: $sterra.K <= Vs
| MaxSites = $cfg.max_sites
| $all_sites <= MaxSites{(world_site ? Me)}
| $sites <= stack MaxSites
| $free_sites <= stack $all_sites
| $clear


world.render =
| Cur = \ui_cursor_point
| when $mode><newBase:
  | Can = $can_place{base $mice_xy}
  | Cur <= if Can then \ui_cursor_target else \ui_cursor_target2
| when $mode><airship:
  | S = $site_at{$mice_xy}
  | Cur <= if S then \ui_cursor_target else \ui_cursor_target2
| get_gui{}.cursor <= $img{Cur}
| Me

world.draw FB X Y =
| FB.blit{0 0 $bg}
| Clock = clock
| PickBlink = (Clock-Clock.int.float)<0.25
| C = $siteC
| P = $picked
| PickedId = if P then P.id else -1
| for S $sites: when S.xy.0>0 and S.state <> raid:
  | if S.attacker and S.type><city then
       FB.blit{S.xy.0-C S.xy.1-C $fg.attack}
    else FB.blit{S.xy.0-C S.xy.1-C S.gfx}
  | when S.id >< PickedId
    | less PickBlink and not point_in_rect{S.rect $mice_xy}:
      | FB.blit{S.xy.0-C S.xy.1-C $fg.picked}
  | when S.attacker: when PickBlink:
    | FB.blit{S.xy.0-C S.xy.1-C $fg.attacked}
| when P:
  | when P.type><base:
    | FB.circle{#FFFFFF 0 [P.xy.0 P.xy.1] $cfg."base_reach"}
  | when P.type><party:
    | FB.circle{#FFFFFF 0 [P.xy.0 P.xy.1] $cfg."party_reach"}
| when $mode><newBase:
  | FB.circle{#FFFFFF 0 $mice_xy $cfg."base_reach"}
| Font = font titleb
| Debt = if $debt>0 then " (debt=[$debt])" else ""
| Font.draw{FB 300 2 "Gold: [$gold][Debt]"}
| Font.draw{FB 500 2 "Turn: [$turn]"}

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
| $gold <= $cfg.start_gold
| $picked <= 0
| $turn <= 0
| $mode <= 0
| $serial <= 1
| $incomeFactor <= 100
| $seed <= LCG_M.rand
| $turn_seed <= LCG_M.rand
| $data.victories <= 0
| $generate

world.free_site S =
| when $picked and $picked.id><S.id: $picked <= 0
| Type = S.type
| $data."cnt_[Type]" <= $data."cnt_[Type]"^~{No 0}-1
| S.xy.init{-100,-100}
| $free_sites.push{S}

world.terra_at XY =
| T = $tmap.|$mask.get{XY.0.clip{0 $mask.w} XY.1.clip{0 $mask.h}}
| when no T: T <= \void
| T

world.site_at XY =
| C = $siteC
| for S $sites: when point_in_rect{S.rect XY}:
  | leave S
| 0

world.can_place Type XY =
| X,Y = XY
| less X<$siteLimX: leave 0
| less Y<$siteLimY: leave 0
| when X<$siteC or Y<$siteC: leave 0
| less got $sterra.Type.find{$terra_at{XY}}: leave 0
| when Type><city: for S $sites: when S.type><city:
  | when (S.xy-XY).all{?abs<32}: leave 0
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
| less $data."cnt_[Type]"^~{No 0}<$cfg."lim_[Type]"^~{No 1000}:
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
| for I $cfg.start_cities: $generate_site{city}
| $generate_site{base}
| $generate_site{party}

//any city remaining in raid state at the end of the turn
//gets turned into ruins
world.update_raids =
| for S $sites:
  | when S.type >< city and S.attacker:
    | $free_site{S.attacker}
    | X,Y = S.xy
    | $free_site{S}
    | R = $generate_site{ruin xy/[X Y]}

world.update_parties Cities Parties =
| RR = $cfg."party_reach"
| R = RR.float
| for P Parties: less P.state:
  | Cs = Cities.keep{C => (P.xy-C.xy).abs < R and not C.attacker}
  | if Cs.size then
      | C = Cs.($rand{Cs.size-1})
      | C.attacker <= P
      | P.state <= \raid
    else
      | X = 0
      | Y = 0
      | I = 0
      | while 1
        | X <= ($rand{RR/2}+RR/2)*(if $rand{1} then -1 else 1)+P.xy.0
        | Y <= ($rand{RR/2}+RR/2)*(if $rand{1} then -1 else 1)+P.xy.1
        | when (P.xy-[X Y]).abs < R and $can_place{party X,Y}:
          | _goto found
        | when I++ > 9000: leave
      | _label found
      | P.move{X,Y}
| when $picked and $picked.state><raid: $picked <= 0

world.end_turn =
| when $turn><0 and $data."cnt_base"^~{No 0}<1:
  | $notify{"Place a base first! Click that flag icon."}
  | leave
| less $sites.list.any{?type><city}:
  | $notify{"The last city has fallen. It is game over."}
  | leave
| $update_raids
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
| less Bases.size:
  | $notify{"You have no base left. It is game over."}
  | leave
| DebtInterest = $debt*$cfg.interest_rate/100
| when $gold < DebtInterest:
  | $notify{"You're bankrupt and cant support your debt. It is game over."}
  | leave
| $gold -= DebtInterest
| $turn += 1
| $turn_seed <= ($turn_seed*LCG_A + LCG_B) % LCG_M
| $incomeFactor <= Cities.size*100/(Cities.size+Ruins.size)
| $gold += $cfg.passive_income*Bases.size
| $update_parties{Cities Parties}
| for B Bases: B.state <= 0
| LSLC = $cfg.lair_spawn_lair_chance
| LSMC = $cfg.lair_spawn_monster_chance
| LH = $cfg.lair_handicap
| for L Lairs:
  | A = $turn - L.turn
  | when $rand{5}<A and $rand{100}<LSMC: $generate_site{party}
  | when $rand{LH}<A and $rand{100}<LSLC: $generate_site{lair}
| when $rand{100}<LSMC: $generate_site{party}
| when $rand{max{1 LH/2}}<$turn and $rand{100}<LSLC: $generate_site{lair}

world.base_placement =
| less $data."cnt_base"^~{No 0}<$cfg."lim_base"^~{No 1000}:
  | $notify{"We are too stretched to build any more bases."}
  | leave
| BaseCost = $cfg."base_cost"
| less $gold >> BaseCost:
  | $notify{"Node enough gold. [BaseCost] required to build a base."}
  | leave
| $set_mode{newBase}

world.borrow =
| DebtCap = $cfg."debt_cap"
| BorrowAmount = $cfg."borrow_amount"
| A = min BorrowAmount DebtCap-$debt
| less A>0:
  | $notify{"Can't borrow more than [DebtCap]"}
  | leave
| $debt += A
| $gold += A
| $notify{"Loaned [A] gold"}

world.repay =
| less $debt>0
  | $notify{"You have no debt"}
  | leave
| RepayAmount = $cfg."borrow_amount"
| Amount = min $gold RepayAmount
| less Amount>>0
  | $notify{"No money to repay the debt"}
  | leave
| $gold -= Amount
| $debt -= Amount
| $notify{"Repaid [Amount] gold"}


world.airship_targeting =
| when $picked and $picked.state><acted:
  | $notify{"This base has already acted this turn."}
  | leave
| $set_mode{airship}


world.set_mode M =
| when $mode >< M: leave
| $mode <= M

world.site_by_serial Serial =
| for S $sites: when S.serial><Serial: leave S
| 0

world.leave_site How =
| Scrap = 0
| for Act $ui.enterSiteIcons1{}{?data}:
  | Scrap += Act.gold*Act.picked
| P = $ui.site.human
| Scrap -= P.data.lossage
| ScrapPercent = $cfg."site_scrap_percent"
| Scrap <= max 0 Scrap*ScrapPercent/100
| $gold += P.data.gold
| $gold += Scrap
| less How><victory:
  | $notify{"You've scrapped [Scrap] gold due to early mission end."}
  | leave
| S = $site_by_serial{$ui.site.data.serial}
| less S: leave //skirmish game
| BP = $cfg."site_bounty_percent"
| Bounty = ($site_gold*BP+BP-1)/100
| Bounty <= max 0 Bounty-$ui.site.turn*$cfg."site_turn_cost"
| $gold += Bounty
| $notify{"You earned [Bounty] bounty gold and scrapped [Scrap] gold!"}
| when S.type><party:
  | $free_site{S}
  | $notify{"You have defeated the raiding party!"}
| when S.type><city and S.attacker:
  | $free_site{S.attacker}
  | $notify{"You have defended the city!"}
| when $picked:
  | $picked.state <= \acted

world.mode_pick M =
| when M><newBase:
  | less $can_place{base $mice_xy}:
    | $notify{"Can't place new base here."}
    | leave newBase
  | $generate_site{base xy/$mice_xy}
  | $gold -= $cfg."base_cost"
  | leave 0
| when M><airship:
  | less ($mice_xy-$picked.xy).abs < $cfg."base_reach".float:
    | $notify{"Out of reach."}
    | leave airship
  | S = $site_at{$mice_xy}
  | less S: leave airship
  | when S.type><party:
    | $ui.enter_site{S}
    | leave 0
  | when S.type><city and S.attacker:
    | $ui.enter_site{S}
    | leave 0
  | $notify{"Nothing to investigate there."}
  | leave airship
| leave 0

world.cancel_mode = $set_mode{0}

world.input In =
| case In
  [mice_move _ XY]
    | $mice_xy.init{XY}
  [mice left State XY]
    | $mice_xy.init{XY}
    | when State: leave
    | when $mode:
      | $set_mode{$mode_pick{$mode}}
      | leave
    | S = $site_at{$mice_xy}
    | $picked <= 0
    | when S: $picked <= S
    | $ui.site_picked{S}
  [mice right State XY]
    | $set_mode{0}
    | $mice_xy.init{XY}

world.infoline =
| R = "[$mice_xy]:[$terra_at{$mice_xy}]"
| S = $site_at{$mice_xy}
| when S: R <= "[R]:[S.type]([S.serial])" 
| R

export world
