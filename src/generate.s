use util


PCells = 10
Slots = 
Parts = t
BluePrints = t
Spans = @table
        [riverh,[h [riverhb] riverh1 riverh2 riverh3 riverh4 riverh5]
         riverv,[v [rivervb] riverv1 riverv2 riverv3 riverv4 riverv5]
        ]

Crosses = [[riverh riverv],[riverc1]]

type site_part{name w h tmap} units/[]

site_part.pw = $w/PCells
site_part.ph = $h/PCells

main.load_symta_file Path =
| Path <= "[$data]/[Path].txt"
| File = Path.get
| less got File: bad "cant load [Path]"
| Path.get.utf8.parse{src Path}

site.load_part Name =
| File = $main.load_symta_file{"parts/[Name]"}
| Saved = File.0.0.group{2}.table
| SW = Saved.w
| SH = Saved.h
| when SW%10 or SH%10: bad "[SW]x[SH] is not multiple of 10x10 for part [Name]"
| P = site_part Name SW SH $load_tile_map{Saved}
| P.units <= Saved.units
| P

site.find_place_for_part PW PH =
| Ps = []
| W = $w/PCells
| H = $h/PCells
| for Y H: for X W
  | for YY PH: for XX PW:
    | when YY+Y>>H or XX+X>>W or Slots.(Y+YY).(X+XX): _goto next
  | push X,Y Ps
  | _label next
| when Ps.end: leave -1,-1
| Ps.rand

site.get_part PartName =
| P = Parts.PartName
| when got P: leave P
| P <= $load_part{PartName}
| Parts.PartName <= P
| P

site.get_blueprint BPName =
| BP = BluePrints.BPName
| when got BP: leave BP
| File = $main.load_symta_file{"bp/[BPName]"}
| BP <= File{[?1.0 ?2]}.table
| BluePrints.BPName <= BP
| BP

site.place_part XY P =
| when P.is_text: P <= $get_part{P}
| less XY:
  | XY <= $find_place_for_part{P.pw P.ph}
  | when XY.0 < 0: leave 0
| OX,OY = XY
| X = OX*10
| Y = OY*10
| TM = P.tmap
| for YY P.h: for XX P.w:
  | $set_pilar{1+X+XX 1+Y+YY TM.XX.YY}
| for UD P.units
  | [Type Id Serial Owner XYZ FXYZ Facing Flags HP Active] = UD
  | DXYZ = XYZ+[X Y 0]
  | $upd_pilar{DXYZ.0 DXYZ.1}
  | U = $players.Owner.alloc_unit{Type}
  | U.move{DXYZ}
  | when Facing.is_list:
    | U.sprite <= $main.sprites.(Facing.0)
    | Facing <= Facing.1
  | U.pick_facing{Facing}
| PW = P.pw
| PH = P.ph
| for YY PH: for XX PW: Slots.(OY+YY).(OX+XX) <= 1
| 1

//FIXME: implement placement constraints, like shore should always be placed near edge of the map
// also add `cross` for shore mixed with river


site.generate W H BlueprintName =
| B = $get_blueprint{BlueprintName}
| $clear
| $w <= W*PCells
| $h <= H*PCells
| Slots <= dup W: dup H: 0
| $filename <= "default"
| $name <= "Default"
| $description <= ""
| $serial <= 0
| UsedSpansX = []
| UsedSpansY = []
| FreeSpansX = @shuffle: dup I W I
| FreeSpansY = @shuffle: dup I H I
| for SpanName B.spans:
  | less SpanName.is_text: SpanName <= SpanName.rand
  | Span = Spans.SpanName
  | when no Span: bad "missing span [SpanName]"
  | [Dir MustHave @PartSet] = Span
  | V = Dir >< v
  | when V:
    | swap FreeSpansX FreeSpansY
    | swap UsedSpansX UsedSpansY
    | swap W H
  | less FreeSpansY.end:
    | Y = pop FreeSpansY
    | push Y,SpanName UsedSpansY
    | ReqXYs = []
    | for PartName MustHave: less FreeSpansX.end:
      | X = pop FreeSpansX
      | push X,Y ReqXYs
    | Ps = []
    | for X W: less got ReqXYs.find{X,Y}:
      | when Ps.end: Ps <= PartSet.shuffle
      | PartName = Ps^pop
      | Isect = UsedSpansX.find{?0><X}
      | when got Isect:
        | IX,ISpanName = Isect
        | Pair = if V then [ISpanName SpanName] else [SpanName ISpanName]
        | CrossNames = Crosses.find{?0><Pair}
        | when got CrossNames: PartName <= CrossNames.1.rand
      | $place_part{(if V then Y,X else X,Y) PartName}
    | for X,Y ReqXYs: $place_part{(if V then Y,X else X,Y) MustHave^pop}
    | for PartName MustHave: say "no place for [PartName] in [SpanName]"
  | when V:
    | swap FreeSpansX FreeSpansY
    | swap UsedSpansX UsedSpansY
    | swap W H
| for PartName B.parts:
  | when PartName.is_list: PartName <= PartName.rand
  | less $place_part{0 PartName}:
    | say "failed to place [PartName]"
| Ps = []
| C = 0
| for Y H: for X W:
  | less Slots.Y.X:
    | C++
    | when Ps.end: Ps <= B.filler.shuffle
    | $place_part{X,Y Ps^pop}
| say "[BlueprintName].filler: [B.filler.size]/[C]"
| $create_borders
| for X,Y points{1 1 $w+1 $h+1}: $upd_pilar{X Y}
| $data.music <= B.playlist.0
| Slots <= 0



site.generate_human_player Gold PlayerActs =
| Ls = []
| LeaderXYZ = []
| ItemPlaces = []
| KeyPlaces = dup 16 []
| DoorPlaces = dup 16 []
| for U $units: less U.removed:
  | when U.type><trigger_spawn_key:
    | push U.xyz KeyPlaces.(U.owner.id)
  | when U.type><trigger_spawn_door:
    | push U.xyz DoorPlaces.(U.owner.id)
  | when U.owner.id >< 1:
    | when U.type><trigger_spawn_item: push U.xyz ItemPlaces
    | when U.type><trigger_spawn_patrol: push U.xyz Ls
    | when U.type><trigger_spawn_leader: push U.xyz LeaderXYZ
//| $players.1.make_ally{$players.2}
//| $players.2.make_ally{$players.1}
| Acts = $main.acts
| for Name,Act Acts:
  | Act.picks.($human.id) <= Act.picked
  | $human.enable{Act Act.researched}
| Ls = Ls.shuffle
| for Act PlayerActs:
  | when Act.picked>0 and Act.tab><summon: less Ls.end:
    | Type = Act.name
    | times I Act.picked:
      | XYZ = pop Ls
      | S = $human.alloc_unit{Type}
      | S.aistate <= \spawned
      | S.move{XYZ}
| Items = $cfg.spawn_items.group{2}
| TotalDensity = Items{?1}.sum.float
| when Items.size: for XYZ ItemPlaces.shuffle:
  | for (I=0; I<1000000; I++):
    | ItemName,ItemDensity = Items.loop{I}
    | when 1.0.rand < ItemDensity.float/TotalDensity:
      | Item = $human.alloc_unit{"item_[ItemName]"}
      | Item.aistate <= \spawned
      | Item.move{XYZ}
      | done
| for OwnerId,Places KeyPlaces.i: when Places.size:
  | Places <= Places.shuffle
  | S = $players.OwnerId.alloc_unit{item_key}
  | S.aistate <= \spawned
  | S.move{Places.0}
| for OwnerId,Places DoorPlaces.i: when Places.size:
  | Places <= Places.shuffle
  | S = $players.OwnerId.alloc_unit{special_door_locked}
  | S.aistate <= \spawned
  | S.move{Places.0}
  | for XYZ Places.tail: //remaining doors are unlocked
    | S = $players.OwnerId.alloc_unit{special_door}
    | S.aistate <= \spawned
    | S.move{XYZ}
| when LeaderXYZ.size:
  | LeaderXYZ <= LeaderXYZ.shuffle
  | S = $human.alloc_unit{leader_mage}
  | S.aistate <= \guard
  | S.move{LeaderXYZ.0}
| $human.data.gold += Gold

site.generate_ai Side Budget Dweller Units Spells Rand =
| Total = 0
| Us = Units.shuffle
| Picked = []
| SpellBudget = 0
| when Dweller:
  | U = $main.acts.Dweller
  | Count = 0
  | Budget <= max Budget U.gold*3
  | while Total+U.gold << Budget and Count < 10000:
    | push U Picked
    | Total += U.gold
    | Count += 1
| less Dweller:
  | SpellBudget <= (Budget+3)/4
  | Budget <= (Budget*3+3)/4
  | for U Us: when U.gold<<100 or (Budget-Total)/max{1 U.gold}>5:
    | Count = max 1 Rand{U.maxPicks}
    | times I Count: when Total+U.gold << Budget:
      | Total += U.gold
      | push U Picked
| Patrol = []
| Guards = []
| RGuards = []
| Player = $players.Side //for now we use hardcoded player 5 for enemy
| LeaderXYZ = []
| for U $units: less U.removed: when U.owner.id >< Player.id:
  | when U.type><trigger_spawn_leader:
    | push [U.xyz.copy U.facing] LeaderXYZ
  | when U.type><trigger_spawn_patrol:
    | push [U.xyz.copy U.facing] Patrol
    | U.free
  | when U.type><trigger_spawn_guard:
    | push [U.xyz.copy U.facing] Guards
    | U.free
  | when U.type><trigger_spawn_ranged:
    | push [U.xyz.copy U.facing] RGuards
    | U.free
| Player.patrol_points <= Patrol{?0}.enheap
| when LeaderXYZ.size:
  | XYZ,Facing = LeaderXYZ.shuffle.0
  | S = Player.alloc_unit{leader_heretic}
  | S.aistate <= \guard
  | S.move{XYZ}
  | S.pick_facing{Facing}
| SBudget = SpellBudget
| STotal = 0
| for S Spells: S.picks.(Player.id) <= 0
| Ss = Spells.shuffle
| for S Ss: when S.gold<<100 or (SBudget-STotal)/max{1 S.gold}>5:
  | Count = max 1 Rand{S.maxPicks}
  | times I Count: when STotal+S.gold << SBudget:
    | STotal += S.gold
    | S.picks.(Player.id) += 1
| Picked <= Picked{?name}.shuffle
| RTs = [unit_blob unit_goblin unit_elf unit_vampire unit_observer]
| Rs = Picked.keep{U => RTs.has{U}}
| Ms = Picked.skip{U => RTs.has{U}}
| RSz = min RGuards.size Rs.size
| RGuards <= RGuards.shuffle
| Ps = [@RGuards.take{RSz}
        @Guards.shuffle
        @RGuards.drop{RSz}
        @Patrol.shuffle]
| PatrolXYZs = Patrol{?0}
| for Type [@Rs @Ms]: less Ps.end:
  | XYZ,Facing = pop Ps
  | S = Player.alloc_unit{Type}
  | S.aistate <= if PatrolXYZs.has{XYZ} then \patrol else \guard
  | S.move{XYZ}
  | S.pick_facing{Facing}