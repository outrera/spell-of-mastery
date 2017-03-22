use bits

type ai{player} world
| $world == $player.world
| $params.view == [0 0 0]
| $params.cursor == [0 0 1]

ai.main = $player.main
ai.params = $player.params

ai.picked = $player.picked
ai.`=picked` V = $player.picked == V

ai.clear =
| $params.aiType == 'default'
| $params.aiStep == 0
| $params.aiWait == 0
| $params.aiSpellWait == 0  //hack to stop AI from spamming spells
| $params.difficulty == 5 // 0=easy, 5=normal, 10=hard
| $params.aiLeaderHarmCycle == -24*100000
| $params.aiCastFlight == 0
| $params.aiCastFlightCycle == -24*100000
| $params.ai_spells == []

type player{id world}
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
| $unit_counts == dup 300 //FIXME: should not be hardcoded
| $name == if $id >< 0 then "Independents" else "Player[$id]"
| $params == t
| MaxSize = $world.maxSize
| $sight == dup MaxSize: MaxSize.bytes
| $ai == ai Me
| Cs = $main.img{ui_colors}
| when $id<Cs.h: $colors == map I 5: Cs.get{I $id}
| $clear

player.picked = $picked_.unheap{}.keep{?0><?1.serial}{?1}.skip{?removed}

player.`=picked` Us =
| for U $picked_: U.1.picked == 0
| for U Us: U.picked == 1
| Us = Us{[?serial ?]}.enheap
| $picked_.heapfree
| $picked_ == Us

player.is_enemy P = $id <> P.id

player.notify Text =
| less $human: leave
| $world.notify{Text}

player.main = $world.main

player.researching = $params.researching
player.`=researching` R = $params.researching == R

player.lore = $params.lore
player.`=lore` R = $params.lore == R

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
| $total_units == 0
| $unit_counts.clear{0}
| $ai.clear
| $picked == []
| $leader == 0
| $pentagram == 0
| $researching == 0
| $mana == 0
| $lore == 0
| $params.lossage == 0
| $params.mana == 0
| $params.libs_left == 0
| $params.temples_left == 0
| for Type,Act $main.params.acts: $research.Type == 0

player.init StartMana StartLore =
| $lore == StartLore
| $mana == StartMana
| $reset_counters

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
| when U.ai >< pentagram: $pentagram == 0

player.research_item What =
| Act = $main.params.acts.What
| $research.What == Act.lore
| $notify{"Acquired [Act.title]"}

player.research_remain Act =
| ResearchSpent = $research.(Act.name)
| ResearchRemain = Act.lore - ResearchSpent
| ResearchRemain

player.units =
| PID = $id
| $world.active.list.keep{(?owner.id >< PID and not ?removed)}

player.seen XYZ = $sight.(XYZ.1).(XYZ.0)>1

update_units Me =

alloc_ai_blockers Me =
| for U $units: less U.removed: when U.ai >< avoid:
  | B = U.owner.alloc_unit{unit_block}
  | B.move{U.xyz}

free_ai_blockers Me =
| for U $units: less U.removed: when U.type >< unit_block:
  | U.free

update_spell_of_mastery Me P =
| when P.human: for Q $players:
  | S = Q.params.spell_of_mastery
  | when got S and not S%(24*5):
    | P.notify{"[Q.name] will finish Spell of Mastery in [S/24] seconds"}
| SOM = P.params.spell_of_mastery
| when got SOM:
  | SOM--
  | less SOM > 0:
    | $params.winner == P.id
    | $params.victory_type == 'Victory by casting the Spell of Mastery'
    | leave
  | P.params.spell_of_mastery == SOM

//FIXME:calculate income per second here
update_income Me =
| IC = $main.params.world.income_cycle
| Cycle = $world.cycle
| when Cycle%IC><0: $mana++
| less $human: when Cycle%24><0: $mana += $params.difficulty-5
| Leader = $leader
| when $mana < $main.params.world.defeat_threshold and Leader:
  | $main.show_message{'Wizard has Lost Too Much Mana'
       "[$name] is too exhausted and cannot continue his life."}
  | Leader.harm{Leader 1000}
  | Leader.harm{Leader 1000} //in case leade has shell
  | $world.effect{Leader.xyz electrical}

player.update =
| Cycle = $world.cycle
| LibId = $main.classes.deco_bookshelf.id
| TempleId = $main.classes.deco_templepit.id
| LibCount = $unit_counts.LibId
| TempleCount = $unit_counts.TempleId
| $params.libs_left == LibCount
| $params.temples_left == TempleCount
| when Cycle><0 and $human and $leader:
  | $world.view.center_at{$leader.xyz cursor/1}
| update_units Me
| update_income Me
| update_spell_of_mastery $world Me
| less $human: when Cycle%10><$id:
  //|alloc_ai_blockers $world
  | $ai.update
  //|free_ai_blockers $world

player.dig_mark X Y Z =
| W = $world.column_units_get{X Y}.find{(?type><unit_dig and ?owner.id><$id)}
| if got W then W else 0


player.work_at XYZ =
| W = $world.units_get{XYZ}.find{(?type><unit_build and ?owner.id><$id)}
| if got W then W else 0

player.add_item Name Amount =
| when Amount > 0: bad "player.remove_item implement positive amount"
| Amount == -Amount
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

player.capture Cell = //captures room pointer by a cell
| Tile = Cell.tile
| less Tile.deco: leave 1
| DSize,OX,OY,Params,DecoType = Tile.deco
| CaptType = Tile.type
| Ts = $world.linked_cells2d{Cell | Cell => Cell.tile.type><CaptType}{?+1}
| Guard = Ts.find{T=>got T.units.find{U=>U.hp and $is_enemy{U.owner}}}
| when got Guard: leave 0 //room is guarded, cant capture it
| for T Ts:
  | D = T.units.find{?type><DecoType}
  | when got D and D.owner.id<>$id:
    | D.change_owner{Me}
    | D.colors == $colors
| 1

export player
