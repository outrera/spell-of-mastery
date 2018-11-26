use bits macros

type ai{player} site
| $site <= $player.site
| $data.view <= [0 0 0]
| $data.cursor <= [0 0 1]

ai.main = $player.main
ai.data = $player.data

ai.picked = $player.picked
ai.`=picked` V = $player.picked <= V

ai.clear =

PlayerColors = [red blue teal purple orange black white yellow]

type player{id site}
   name
   ai
   human //1 for human controlled players
   leader
   data/(t)
   picked_unit
   picked_serial
   sight // fog of war
   total_units
   unit_counts // counts uwned units for each unit type
   colors
| $unit_counts <= dup 300 //FIXME: should not be hardcoded
| $name <= if $id >< 0 then "Independents" else "Player[$id]"
| MaxSize = $site.maxSize
| $sight <= dup MaxSize: MaxSize.bytes
| $ai <= ai Me
| Cs = $main.img{ui_colors}
| when $id<Cs.h: $colors <= map I 5: Cs.get{I $id}
| $clear

player.color = PlayerColors.$id

player.picked =
| U = $picked_unit
| when U.removed or U.serial<>$picked_serial: leave $site.nil
| U

player.`=picked` U =
| $picked_unit <= U
| $picked_serial <= U.serial

player.is_enemy P = $id <> P.id

player.notify Text =
| less $human: leave
| $site.notify{Text}

player.main = $site.main

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
| $picked_unit <= $site.nil
| $picked_serial <= 0
| $leader <= $site.nil
| $data.lossage <= 0
| $data.gold <= 0
| $data.keys <= 0

player.init =

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

player.haskey N = $data.keys &&& (1<<<N)

player.enabled Act = Act.players.bit{$id}
player.enable Act State = Act.players <= Act.players.bitSet{$id State}

player.units =
| PID = $id
| $site.active.list.keep{(?owner.id >< PID and not ?removed)}

player.seen XYZ = $sight.(XYZ.1).(XYZ.0)>1

player.update =
| Cycle = $site.cycle
| when Cycle><0 and $human and not $leader.removed:
  | $site.view.center_at{$leader.xyz cursor/1}

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

player.sound Name = when $id >< $site.human.id: $main.sound{Name}

player.lost_leader Leader =
| Leaders = []
| RemainingUnits = []
| for U $site.active.list: when U.id <> Leader.id:
  | when U.leader: push U Leaders
  | when U.owner.id >< $id: push U RemainingUnits
| case Leaders [L@Ls]: when Ls.all{?owner.id><L.owner.id}:
  | $site.data.winner <= L.owner.id
  | $site.data.victory_type <= 'Victory by defeating enemy leaders.'
| when Leader.owner.human: less Leaders.any{?owner.human}:
  | $site.data.winner <= 0
  | $site.data.victory_type <= 'Defeat by losing your leader.'
//| $site.notify{"[$name] was defeated."}
| less RemainingUnits.any{?leader}: for U RemainingUnits: U.free

export player
