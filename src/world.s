use gui util widgets stack

MoveTime = 0.75
SoundDist = 0.3

type world_site{Id World}
  world/World //world this sites belongs to
  id/Id // numeric id, which can be reused
  serial //serial guaranteed to be unique for the duration of the game
  type //city, ruin, lair, base, party
  gfx //representation on world map
  gfx2 //alternatve gfx for animation
  gfx2xy/[0 0]
  turn //turn this site came to life
  name //name of city lair
  attacker/0
  xy/[-100 -100]
  xy_from/[-100 -100]
  xy_goal/[-100 -100]
  act/[0 0]
  tstart
  tfinish
  move_time
  hide
  state
  data

world_site.rect =
| C = $world.siteC
| [$xy.0-C $xy.1-C C*2 C*2]

world_site.move XY =
| $xy.init{XY}

world_site.sched Act Target XY =
| $xy_goal.init{XY}
| $xy_from.init{$xy}
| $act.init{Act,Target}
| $tstart <= 0
| $tfinish <= 0
| $move_time <= MoveTime

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
  etsounds/(t) //sounds already played this turn
  phase/normal
| $cfg <= $main.cfg.world
| $bg <= $img{world_bg}
| $mask <= $img{world_bg_mask}
| $siteLimX <= $bg.w-$siteC
| $fg <= @table: map N [site picked attacked
                        base airship city village
                        lair dungeon party ruin
                        city_siege village_siege]
  | [N $img{"world_fg_[N]"}]
| for V,@Ks $cfg.tmap: for K Ks: $tmap.K <= V
| for K,@Vs $cfg.sterra: $sterra.K <= Vs
| MaxSites = $cfg.max_sites
| $all_sites <= MaxSites{(world_site ? Me)}
| $sites <= stack MaxSites
| $free_sites <= stack $all_sites
| $clear


world.render =
| $update
| Cur = \ui_cursor_point
| when $phase<>normal: Cur <= \ui_cursor_hourglass
| when $mode><newBase:
  | Can = $can_place{base $mice_xy}
  | Cur <= if Can then \ui_cursor_target else \ui_cursor_target2
| when $mode><airship:
  | S = $site_at{$mice_xy}
  | Cur <= if S then \ui_cursor_target else \ui_cursor_target2
| get_gui{}.cursor <= $img{Cur}
| Me

Frame = 0

world.draw FB X Y =
| FB.blit{0 0 $bg}
| Clock = clock
| PickBlink = (Clock-Clock.int.float)<0.25
| C = $siteC
| P = $picked
| when (get_gui{}.ticks*24.0).int%5><0: Frame++
| PickedId = if P then P.id else -1
| for S $sites: when S.xy.0>0 and S.state <> raid:
  | when S.hide: pass
  | if S.attacker and not S.gfx2 then
       if S.type><city then FB.blit{S.xy.0-C S.xy.1-C $fg.city_siege}
       else FB.blit{S.xy.0-C S.xy.1-C $fg.village_siege}
    else
    | when not S.gfx2:
      | G = S.gfx
      | when S.type >< rift:
        | Wait = 33
        | F = ((Frame+S.xy.0+S.xy.1)%Wait).float/Wait.float
        | G <= $main.sprites.world_fg_rift.lerp{F 3 idle}
      | FB.blit{S.xy.0-C S.xy.1-C G}
    | when S.gfx2:
      | FB.blit{S.xy.0-C+S.gfx2xy.0 S.xy.1-C+S.gfx2xy.1 S.gfx2}
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
| FontS = font title
| print X Y Text =
  | FontS.draw{FB X-2 Y-2 Text}
  | FontS.draw{FB X+2 Y+2 Text}
  | Font.draw{FB X Y Text}
| Debt = if $debt>0 then " (debt=[$debt])" else ""
| print{200 2 "Gold: [$gold][Debt]"}
| print{500 2 "Turn: [$turn]"}

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
| $phase <= \normal
| for K,V $etsounds: $etsounds.K <= 0.0
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
| when Type><city or Type><village:
  | for S $sites: when S.type><city or S.type><village:
    | when (S.xy-XY).all{?abs<48}: leave 0
| C2 = $siteC*2
| R = [X-$siteC Y-$siteC C2 C2]
| for S $sites: when rects_intersect{R S.rect}: leave 0
| when Type><rift: for S $sites: when S.type><rift:
  | when (S.xy-XY).all{?abs<64}: leave 0
| when Type><party:
  | RR = $cfg."rift_reach"
  | R = RR.float
  | when $sites.list.keep{?type><rift}.all{C => (XY-C.xy).abs >> R}:
    | leave 0
| 1

world.generate_xy Type =
| X = 0
| Y = 0
| _label again
| X <= $rand{$w-$siteC}+$siteC
| Y <= $rand{$h-$siteC}+$siteC
| less $can_place{Type X,Y}: _goto again
| X,Y

world.sound Sound =
| GUI = get_gui{}
| when no GUI: leave //GUI is not ready yet
| T = GUI.ticks
| when Sound and $etsounds.Sound^~{0.0} < T:
  | $main.sound{Sound}
  | $etsounds.Sound <= T + SoundDist

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
| S.xy_goal.init{-100,-100}
| S.act.init{0,0}
| S.gfx <= $fg.Type
| S.attacker <= 0
| S.state <= 0
| S.hide <= 0
| when no S.gfx: S.gfx <= $fg.site
| S.gfx2 <= 0
| S.gfx2xy.init{0,0}
| $sites.push{S}
| $data."cnt_[Type]" <= $data."cnt_[Type]"^~{No 0}+1
| when $phase><spawn_sched:
  | S.sched{spawn 0 S.xy}
  | S.hide <= 1
  | S.move_time <= MoveTime*0.5
| S

world.generate =
| for I $cfg.start_cities: $generate_site{city}
| for I $cfg.start_villages: $generate_site{village}
| for I $cfg.start_rifts: $generate_site{rift}
| Spells = $cfg.spells
| Summons = $cfg.summons
| Acts = $main.acts
| for N Spells: less Acts.N.researched:
  | S = $generate_site{dungeon}
  | S.state <= N
| for N Summons: less Acts.N.researched:
  | S = $generate_site{lair}
  | S.state <= N
| $generate_site{base}
| $generate_site{party}

//any city remaining in raid state at the end of the turn
//gets turned into ruins
world.sched_raze =
| for S $sites:
  | when S.attacker:
    | S.sched{raze 0 S.xy}

world.sched_actions Villages Cities Parties =
| RR = $cfg."party_reach"
| R = RR.float
| Targets = [@Cities @Villages].shuffle
| for P Parties: less P.state:
  | Cs = Targets.keep{C => (P.xy-C.xy).abs < R
                           and C.act.0<>raided
                           and not C.attacker}
  | if Cs.size then
      | C = Cs.($rand{Cs.size-1})
      | C.act.0 <= \raided
      | P.sched{raid C C.xy}
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
      | P.sched{move 0 X,Y}

world.sched_spawns Rifts =
| $phase <= \spawn_sched
| SRC = $cfg.spawn_rift_chance
| SMC = $cfg.spawn_monster_chance
| LH = $cfg.rift_handicap
| for L Rifts:
  | A = $turn - L.turn
  | when $rand{100}<SMC: $generate_site{party}
  | when $rand{LH}<A and $rand{100}<SRC: $generate_site{rift}

world.end_turn =
| when $phase<>normal: leave
| when $turn><0 and $data."cnt_base"^~{No 0}<1:
  | $notify{"Place a base first! Click that flag icon."}
  | leave
| less $sites.list.any{?type><city}:
  | $notify{"The last city has fallen. It is game over."}
  | leave
| $sched_raze
| Ss = $sites.list
| $sites.clear
| Lairs = []
| Cities = []
| Villages = []
| Bases = []
| Ruins = []
| Parties = []
| Rifts = []
| for S Ss: when S.xy.0>0
  | when S.type><base: push S Bases
  | when S.type><lair: push S Lairs
  | when S.type><city: push S Cities
  | when S.type><village: push S Villages
  | when S.type><ruin: push S Ruins
  | when S.type><party: push S Parties
  | when S.type><rift: push S Rifts
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
| $sched_actions{Villages Cities Parties}
| for B Bases: B.state <= 0
| for V Villages.shuffle: less V.attacker or V.act.0><raided:
  | when $data."cnt_city"^~{0} < $cfg."lim_city"^~{1000}:
    | when $rand{100} < $cfg."village_growth_chance":
      | XY = V.xy.deep_copy
      | $free_site{V}
      | $generate_site{city xy/XY}
| $sched_spawns{Rifts}
| $phase <= \raze

world.update =
| when $phase><normal: leave
| for S $sites.list: when S.xy_goal.0 >> 0 and S.act.0><$phase:
  | Act,Goal = S.act
  | S.hide <= 0
  | T = get_gui{}.ticks
  | less S.tstart
    | S.tstart <= get_gui{}.ticks
    | S.tfinish <= S.tstart+S.move_time
    | when Act><raze:
      | $sound{dragon_flame}
      | $generate_site{ruin xy/S.xy}
  | when T < S.tfinish:
    | DX,DY = S.xy_goal-S.xy_from
    | TD = (T-S.tstart)/(S.tfinish-S.tstart)
    | S.xy.init{S.xy_from + [(DX.float*TD).int (DY.float*TD).int]}
    | when Act><spawn:
      | when TD < 0.5: S.hide <= 1
      | S.gfx2 <= $main.sprites.effect_warp.lerp{TD 3 idle}
    | when Act><raze:
      | S.gfx2 <= $main.sprites.effect_incinerate.lerp{TD 3 idle}
      | S.gfx2xy.init{-26,-112}
    | leave
  | S.xy.init{S.xy_goal}
  | S.xy_goal.init{-100,-100}
  | S.act.init{0,0}
  | S.gfx2 <= 0
  | S.gfx2xy.init{0,0}
  | when Act><raze:
    | $free_site{S.attacker}
    | $free_site{S}
  | when Act><raid:
    | S.state <= \raid
    | Goal.attacker <= S
    | $sound{w_raid}
    | when $picked and $picked.id >< S.id: $picked <= 0
  | when Act><spawn:
    | when S.type><party or S.type><rift: $sound{w_enemy}
  | when Act><flight:
    | $ui.enter_site{Goal}
    | $free_site{S} //no need for airship
  | leave
| $phase <= case $phase
    raze | \move
    move | \raid
    raid | \spawn
    spawn
        | $sound{new_turn} 
        | \normal
    Else | \normal

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


world.site_bounty Turn =
| BP = $cfg."site_bounty_percent"
| Bounty = ($site_gold*BP+BP-1)/100
| max 0 Bounty-Turn*$cfg."site_turn_cost"

world.site_spoils How Apply =
| Scrap = 0
| for Act $ui.enterSiteIcons1{}{?data}:
  | Scrap += Act.gold*Act.picked
| P = $ui.site.human
| Scrap -= P.data.lossage
| ScrapPercent = $cfg."site_scrap_percent"
| Scrap <= max 0 Scrap*ScrapPercent/100
| when Apply: $gold <= $gold + P.data.gold + Scrap
| less How><victory:
  | leave: if Scrap
       then "You've scrapped [Scrap] gold due to early mission end."
       else ""
| S = $site_by_serial{$ui.site.data.serial}
| less S: //skirmish game
  | leave "You've scrapped [Scrap] gold."
| Bounty = $site_bounty{$ui.site.turn}
| when Apply: $gold += Bounty
| T = "You earned [Bounty] bounty gold and scrapped [Scrap] gold."
| T2 = 0
| Acts = $main.acts
| Class = $main.classes
| when S.type><dungeon:
  | Act = Acts.(S.state)
  | when Apply:
    | Act.researched <= 1
    | $free_site{S}
  | T2 <= "You have discovered the spell of [Act.title]."
| when S.type><lair:
  | Name = S.state
  | Act = Acts.Name
  | when Apply:
    | Act.researched <= 1
    | $free_site{S}
  | T2 <= "New mercenary type unlocked: [Class.Name.title]."
| when S.type><party:
  | when Apply: $free_site{S}
  | T2 <= "You have defeated the raiding party!"
| when S.type><ruin:
  | when Apply:
    | $generate_site{village xy/S.xy}
    | $free_site{S}
  | T2 <= "You have cleansed the ruins of the settlement!"
| when S.attacker:
  | when Apply: $free_site{S.attacker}
  | T2 <= "You have defended the [S.type]!"
| when T2: T <= "[T]\n[T2]"
| T

world.leave_site How =
| $site_spoils{How 1}
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
  | ValidDst =
  | Investigable = [party ruin lair dungeon] 
  | less Investigable.has{S.type} or S.attacker:
    | $notify{"Nothing to investigate there."}
    | leave airship
  | A = $generate_site{airship xy/$picked.xy}
  | A.sched{flight S S.xy}
  | $phase <= \flight
| leave 0

world.cancel_mode = $set_mode{0}

world.input In =
| when $phase<>normal: leave
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
| when 0:
  | R = "[$mice_xy]:[$terra_at{$mice_xy}]"
  | S = $site_at{$mice_xy}
  | when S: R <= "[R]:[S.type]([S.serial])" 
  | leave R
| R = "[$terra_at{$mice_xy}]"
| S = $site_at{$mice_xy}
| Acts = $main.acts
| Class = $main.classes
| SiteName =
   if not S then 0
   else case S.type
     party | "Raiding Party. These creatures are up to no good."
     city | "City"
     village | "Village. It will grow into city with time"
     ruin | "Ruins of a Settlement"
     lair | "[Class.(S.state).title] creatures inhabit this land. Conquer to have them in your army."
     dungeon | "Local mages guard the knowledge of [Acts.(S.state).title] spell."
     base | "Wizard Tower - your base of operation."
     rift | "It is rummored that raiding parties appear in this region."
     Else | 0
| when SiteName: R <= "[R], [SiteName]" 
| R



export world
