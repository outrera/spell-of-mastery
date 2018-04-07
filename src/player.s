use bits macros

type ai{player} site
| $site <= $player.site
| $params.view <= [0 0 0]
| $params.cursor <= [0 0 1]

ai.main = $player.main
ai.params = $player.params

ai.picked = $player.picked
ai.`=picked` V = $player.picked <= V

ai.clear =
| $params.aiType <= 'default'
| $params.aiStep <= 0
| $params.aiWait <= 0
| $params.difficulty <= 5 // 0=easy, 5=normal, 10=hard
| $params.aiLeaderHarmTurn <= -24*100000
| $params.aiCastFlight <= 0
| $params.aiCastFlightTurn <= -24*100000
| $params.ai_spells <= []

PlayerColors = [red blue teal purple orange black white yellow]

type player{id site}
   name
   ai
   human //1 for human controlled players
   mana
   leader
   pentagram
   params
   research/(t) //research and latency
   picked_ //picked units
   sight // fog of war
   total_units
   unit_counts // counts uwned units for each unit type
   colors
   gold
   wood
   stone
   iron
   houses
| $unit_counts <= dup 300 //FIXME: should not be hardcoded
| $name <= if $id >< 0 then "Independents" else "Player[$id]"
| $params <= t
| MaxSize = $site.maxSize
| $sight <= dup MaxSize: MaxSize.bytes
| $ai <= ai Me
| Cs = $main.img{ui_colors}
| when $id<Cs.h: $colors <= map I 5: Cs.get{I $id}
| $clear

player.color = PlayerColors.$id

player.picked = $picked_.unheap{}.keep{?0><?1.serial}{?1}.skip{?removed}

player.`=picked` Us =
| for U $picked_: U.1.picked <= 0
| for U Us: U.picked <= 1
| Us = Us{[?serial ?]}.enheap
| $picked_.heapfree
| $picked_ <= Us

player.is_enemy P = $id <> P.id

player.notify Text =
| less $human: leave
| $site.notify{Text}

player.main = $site.main

player.lore = $params.lore
player.`=lore` R = $params.lore <= R

player.explore State =
| when State
  | for S $sight: S.clear{3}
  | for U $units: U.explore{1}
  | leave
| for S $sight: S.clear{0}
| for U $units: U.explore{1}


//or 0 if the cell is unexplored
//else number of units seeing this cell + 1
player.explored X,Y,Z = $sight.Y.X

player.clear =
| for Xs $sight: Xs.clear{3}
| $total_units <= 0
| $unit_counts.clear{0}
| $ai.clear
| $picked <= []
| $leader <= $site.nil
| $pentagram <= $site.nil
| $mana <= 0
| $lore <= 0
| $params.lossage <= 0
| $params.mana <= 0
| for Type,Act $main.cfg.acts: $research.Type <= 0

player.init StartMana StartLore =
| $lore <= StartLore
| $mana <= StartMana

player.got_unit U =
| CID = U.class.id
| when CID:
  | $unit_counts.CID++
  | $total_units++

player.lost_unit U =
| CID = U.class.id
| when CID:
  | $unit_counts.CID--
  | $total_units--
| when U.ai >< pentagram: $pentagram <= $site.nil

player.research_item What =
| Act = $main.cfg.acts.What
| $research.What <= Act.lore
| $notify{"Acquired [Act.title]"}

player.research_remain Act =
| ResearchSpent = $research.(Act.name)
| ResearchRemain = Act.lore - ResearchSpent
| ResearchRemain

player.enabled Act = Act.players^get_bit{$id}<>0

player.researched Act = $research_remain{Act}<<0

player.can_research Act =
| when $researched{Act}: leave 0
| Act.needs.all{Ns=>Ns.any{N=>$researched{N}}}

player.units =
| PID = $id
| $site.active.list.keep{(?owner.id >< PID and not ?removed)}

player.seen XYZ = $sight.(XYZ.1).(XYZ.0)>1

update_spell_of_mastery Me P =
| when P.human: for Q $players:
  | S = Q.params.spell_of_mastery
  | when got S and not S%(24*5):
    | P.notify{"[Q.name] will finish Spell of Mastery in [S/24] seconds"}
| SOM = P.params.spell_of_mastery
| when got SOM:
  | SOM--
  | less SOM > 0:
    | $params.winner <= P.id
    | $params.victory_type <= 'Victory by casting the Spell of Mastery'
    | leave
  | P.params.spell_of_mastery <= SOM

player.update =
| Cycle = $site.cycle
| when Cycle><0 and $human and not $leader.removed:
  | $site.view.center_at{$leader.xyz cursor/1}
| update_spell_of_mastery $site Me

alloc_ai_blockers Me =
| for U $units: less U.removed: when U.ai >< avoid:
  | B = U.owner.alloc_unit{unit_block}
  | B.move{U.xyz}

free_ai_blockers Me =
| for U $units: less U.removed: when U.type >< unit_block:
  | U.free

player.make_move =
| when $human: leave
//|alloc_ai_blockers $site
| $ai.update
//|free_ai_blockers $site

player.add_item Name Amount =
| when Amount > 0: bad "player.remove_item implement positive amount"
| Amount <= -Amount
| Piles = []
| for U $units: when U.ai><flag: 
  | Available = U.cell.get_item{Name}
  | when Available: push [U.cell Available] Piles
| when Piles{?1}.sum<Amount: leave 0
| for Cell,Avail Piles:
  | Count = min Amount Avail
  | Cell.add_item{Name -Count}
  | Amount -= Count
  | when Amount < 0: leave 1
| 1

player.sound Name = when $id >< $site.human.id: $main.sound{Name}

player.lost_leader Leader =
| Leaders = []
| RemainingUnits = []
| for U $site.active.list: when U.id <> Leader.id:
  | when U.leader: push U Leaders
  | when U.owner.id >< $id: push U RemainingUnits
| case Leaders [L@Ls]: when Ls.all{?owner.id><L.owner.id}:
  | $site.params.winner <= L.owner.id
  | $site.params.victory_type <= 'Victory by defeating other leaders.'
| when Leader.owner.human: less Leaders.any{?owner.human}:
  | $site.params.winner <= 0
  | $site.params.victory_type <= 'Defeat by losing your leader.'
| $site.notify{"[$name] was defeated."}
| less RemainingUnits.any{?leader}: for U RemainingUnits: U.free

export player
