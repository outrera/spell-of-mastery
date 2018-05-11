use util rle

action.save =
| less $type: leave 0
| list
   $type
   $cycles
   $priority
   $xyz
   (if $target then $target.id else 0)

action.load IdMap Saved =
| less Saved: leave
| Type,Cycles,Priority,XYZ,Target = Saved.take{5}
| $init{Type |if Target then IdMap.Target else XYZ}
| $priority <= Priority
| $cycles <= Cycles
| $xyz.init{XYZ}


unit.serialize = //unit serializer for savegames
| Active = 0
| when $active:
  | Genes = if $genes.end then 0
            else $genes.map{E=>[E.when E.name E.amount E.data]}
  | Host = if $host then $host.id else 0
  | Goal = if $goal then [$goal.id $goal_act.name] else 0
  | Path = if $path.end then 0 else [$path 0]
  | Active <= list $from $anim $anim_step $anim_wait
                   $fatigue $cooldown Genes Host Goal Path
                   $action.save $ordered.save $next_action.save
                   $mov $def
| Facing = $facing
| when $sprite.id <> $default_sprite.id: Facing <= [$sprite.id Facing]
| list $type $id $serial $owner.id $xyz $fxyz Facing
       $flags $hp Active

site.save =
| ActivePlayers = dup 32 0
| Units = map U $units.skip{(?removed or ?mark)}
  | ActivePlayers.(U.owner.id) <= 1
  | U.serialize
| $data.view_zlock <= $view.zlock
| $data.turn <= $turn
| $data.player <= $player
| $data.paused <= $paused
| Explored = No
| less $editor:
  | map Id,Active ActivePlayers.i.keep{?.1}
    | [Id $players.Id.sight{}{X=>rle_encode X}]
| list version(0.2) w($w) h($h) serial($serial) cycle($cycle) seed($seed)
    filename | $filename
    name | $name
    description | $description
    data | map [K V] $data [K V]
    events | $events{}{?1}
    tids | $main.tid_map{}{?type}
    players | map P $players
              | [P.id P.name P.human 0 P.picked.id 0
                 P.data.list 0 P.mana]
    player | $human.id
    units | Units
    tilemap | map X $w: map Y $h:
              | XX = X+1
              | YY = Y+1
              | Ts = $pilar{XX YY}
              | map T Ts: if T.parts.is_int then T.parts else T.id
    explored | Explored
    enabled | map Name,Act $main.acts: Name,Act.players


site.deserialize_unit IdMap X =
| [Type Id Serial Owner XYZ FXYZ Facing Flags HP Active] = X
| U = $players.Owner.alloc_unit{Type}
| less Active: U.change_owner{$players.0} //kludge
| U.serial <= Serial
| case XYZ A,B:
  | XYZ <= A
  | U.from.init{B}
| U.hp <= HP
| U.move{XYZ}
| U.fxyz.init{FXYZ}
| when Facing.is_list:
  | U.sprite <= $main.sprites.(Facing.0)
  | Facing <= Facing.1
| U.pick_facing{Facing}
| when Active:
  | [From Anim AnimStep AnimWait Fatigue Cool Genes Host Goal Path
     Action Ordered NextAction Mov Def @More] = Active
  | U.mov <= Mov
  | U.fatigue <= Fatigue^~{unused 0}
  | U.def <= Def
  | U.from.init{From}
  | U.animate{Anim}
  | U.anim_step <= AnimStep
  | U.anim_wait <= AnimWait
  | U.cooldown <= Cool
  | for E U.genes: $free_gene{E}
  | U.genes.heapfree
  | U.genes <= if Genes.is_list and not Genes.end
               then Genes{E=>$new_gene{@E}}
               else []
  | when Path:
    | P = Path.0.enheap
    | U.path.heapfree
    | U.path <= P
  | U.host <= [Host Goal Action Ordered NextAction]
| U.flags <= Flags
| when U.leader: U.owner.leader <= U
| when U.ai >< pentagram: U.owner.pentagram <= U
| IdMap.Id <= U

remap_tids TidMap LookupTable Xs =
| LookupTable = LookupTable{TidMap.?}
| map Ys Xs: map Zs Ys:
  | Rs = dup Zs.size
  | times Z Zs.size:
    | Id = Zs.Z
    | when Id >> 0:
      | T = LookupTable.Id
      | Rs.Z <= T
      | H = T.height-1
      | Ps = T.parts
      | Z = Z-H
      | when H>0: times I H: Rs.(Z+I) <= Ps.I
  | Rs

site.load_tile_map Saved =
| TidMap = $main.tid_map
| TypeTids = TidMap{?type,?id}.table
| LookupTable = Saved.tids{}{TypeTids.?}.replace{No 0}
| remap_tids TidMap LookupTable Saved.tilemap

site.load Saved =
| $clear
| $w <= Saved.w
| $h <= Saved.h
| $filename <= Saved.filename
| $name <= Saved.name
| $description <= Saved.description
| $events <= if got Saved.events then Saved.events.i else []
| $serial <= 0
| Seed = 
| when got@@it Saved.seed: $seed <= it
| when got@@it Saved.data: for [K V] it: $data.K <= V
| $turn <= $data.turn
| $player <= $data.player
| $paused <= $data.paused
| Tilemap = $load_tile_map{Saved}
| for X $w: for Y $h: $set_pilar{X+1 Y+1 Tilemap.X.Y}
| $create_borders
| for X,Y points{1 1 $w+1 $h+1}: $upd_pilar{X Y}
//| StartTime = clock
//| say "site.load: update_move_map_ took [clock{}-StartTime]"
| $cycle <= Saved.cycle
| IdMap = t //used to remap old ids to new ones
| for X Saved.players
  | [Id Name Human Color Picked Moves Data Research Mana] = X
  | P = $players.Id
  | P.name <= Name
  | P.human <= Human
  | P.mana <= Mana
  | for K,V Data: P.data.K <= V
  | P.data.picked <= Picked
| Explored = Saved.explored
| when got Explored:
  | for PID,Sight Explored
    | PS = $players.PID.sight
    | WH = min{Sight.size $maxSize}
    | for I WH
      | Dst = PS.I
      | Src = map X Sight.I^rle_decode: if X then 1 else 0
      | if Dst.size><Src.size then Src.init{Src}
        else for J WH: Dst.J <= Src.J
| $human <= $players.(Saved.player)
| for X Saved.units: $deserialize_unit{IdMap X}
| Acts = $main.acts
| for U $active: when U.host:
  | [HostId Goal Action Ordered NextAction] = U.host
  | U.host <= 0
  | when HostId: U.host <= IdMap.HostId
  | when Goal:
    | Target,ActName = Goal
    | U.goal_act <= Acts.ActName
    | if Target.is_int
      then U.goal <= IdMap.Target
      else U.goal <= $new_goal{Target}
    | U.goal_serial <= U.goal.serial
  | U.action.load{IdMap Action}
  | U.ordered.load{IdMap Ordered}
  | U.next_action.load{IdMap NextAction}
| $serial <= Saved.serial
| for P $players:
  | when got@@it P.data.picked:
    | U = IdMap.(it)
    | when got U: P.picked <= U
| for Name,Flags Saved.enabled^~{No []}:
  | when got Acts.Name: Acts.Name.players <= Flags

main.save Path = Path.set{$site.save.as_text}

main.load Path =
| File = Path.get
| less got File: bad "cant load [Path]"
| Saved = Path.get.utf8.parse{src Path}.0.0.group{2}.table
| Saved.filename <= Path.url.1
| $site.load{Saved}
