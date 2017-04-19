use util rle

action.save =
| less $type: leave 0
| list
   $type
   $cycles
   $priority
   $xyz
   (if $target then $target.id else 0)
   $toXYZ
   $fromXYZ
   $start_cycles

action.load IdMap Saved =
| less Saved: leave
| [Type Cycles Priority XYZ Target To From StartC] = Saved
| $init{Type |if Target then IdMap.Target else XYZ}
| $priority <= Priority
| $cycles <= Cycles
| $start_cycles <= StartC
| $xyz.init{XYZ}
| $toXYZ.init{To}
| $fromXYZ.init{From}


world.save =
| ActivePlayers = dup 32 0
| Units = map U $units.skip{(?removed or ?mark)}
  | ActivePlayers.(U.owner.id) <= 1
  | Active = 0
  | when U.active or U.type><unit_build:
    | Effects = if U.effects.end then 0
                else U.effects.map{E=>[E.when E.name E.amount E.params]}
    | Host = if U.host then U.host.id else 0
    | G = U.goal
    | Goal = if not G then 0
             else if G.type><goal then [G.xyz U.goal_act.name]
             else [G.id U.goal_act.name]
    | Path = if U.path.end then 0 else [U.path 0]
    | Active <= list U.from U.anim U.anim_step U.anim_wait
                     U.kills U.cooldown Effects Host Goal Path
                     U.action.save U.ordered.save U.next_action.save
  | Facing = U.facing
  | when U.sprite.id <> U.default_sprite.id: Facing <= [U.sprite.id Facing]
  | list U.type U.id U.serial U.owner.id U.xyz U.fxyz Facing
         U.flags U.hp Active
| $params.view_zlock <= $view.zlock
| list version(0.2) w($w) h($h) serial($serial) cycle($cycle) seed($seed)
    filename | $filename
    name | $name
    description | $description
    params | map [K V] $params [K V]
    events | $events{}{?1}
    tids | $tid_map{}{?type}
    players | map P $players
              | [P.id P.name P.human 0 P.picked{}{?id} 0
                 P.params.list P.research.list.keep{?1} P.mana]
    player | $human.id
    units | Units
    tilemap | map X $w: map Y $h:
              | XX = X+1
              | YY = Y+1
              | Ts = $pilar{XX YY}
              | map T Ts: if T.parts.is_int then T.parts else T.id
    explored | map Id,Active ActivePlayers.i.keep{?.1}
               | [Id $players.Id.sight{}{X=>rle_encode X}]
    actions_enabled | map Name,Act $main.params.acts: Name,Act.enabled

main.save Path = Path.set{$world.save.as_text}

remap_tids Me LookupTable Xs =
| TidMap = $tid_map
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

world.load Saved =
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
| when got@@it Saved.params: for [K V] it: $params.K <= V
| TypeTids = $main.tid_map{}{?type,?id}.table
| LookupTable = Saved.tids{}{TypeTids.?}.replace{No 0}
| Tilemap = remap_tids Me LookupTable Saved.tilemap
| for X $w: for Y $h: $set_pilar{X+1 Y+1 Tilemap.X.Y}
| $create_borders
| for X,Y points{1 1 $w+1 $h+1}: $updPilarGfxes{X Y}
//| StartTime = clock
//| say "world.load: update_move_map_ took [clock{}-StartTime]"
| $cycle <= Saved.cycle
| IdMap = t
| for X Saved.players
  | [Id Name Human Color Picked Moves Params Research Mana] = X
  | P = $players.Id
  | P.name <= Name
  | P.human <= Human
  | P.mana <= Mana
  | for K,V Params: P.params.K <= V
  | for N,R Research: P.research.N <= R
  | P.params.picked <= if Picked then Picked else []
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
| Acts = $main.params.acts
| Sprites = $main.sprites
| for X Saved.units
  | [Type Id Serial Owner XYZ FXYZ Facing Flags HP Active]=X
  | U = $players.Owner.alloc_unit{Type}
  | less Active or U.type><unit_build: U.change_owner{$players.0}
  | U.serial <= Serial
  | case XYZ A,B:
    | XYZ <= A
    | U.from.init{B}
  | U.hp <= HP
  | U.move{XYZ}
  | U.fxyz.init{FXYZ}
  | when Facing.is_list:
    | U.sprite <= Sprites.(Facing.0)
    | Facing <= Facing.1
  | U.pick_facing{Facing}
  | when Active:
    | [From Anim AnimStep AnimWait Kills Cool Efx Host Goal Path
       Action Ordered NextAction @More] = Active
    | U.from.init{From}
    | U.animate{Anim}
    | U.anim_step <= AnimStep
    | U.anim_wait <= AnimWait
    | U.kills <= Kills
    | U.cooldown <= Cool
    | for E U.effects: $free_effect{E}
    | U.effects.heapfree
    | U.effects <= if Efx.is_list and not Efx.end
                   then Efx{E=>$new_effect{@E}}
                   else []
    | when Path:
      | P = Path.0.enheap
      | U.path.heapfree
      | U.path <= P
    | U.host <= [Host Goal Action Ordered NextAction]
    | when Type><unit_build: //kludge!
      | Target,ActName = Goal
      | U.goal <= U.unit_goal
      | U.goal.xyz.init{XYZ}
      | U.goal_act <= Acts.ActName
      | U.sprite <= Sprites.special_construction
      | U.goal_act <= Acts.ActName
      | U.host <= 0
      | U.animate{idle}
  | U.flags <= Flags
  | when U.leader: U.owner.leader <= U
  | when U.bank >< pentagram: U.owner.pentagram <= U
  | IdMap.Id <= U
| for U $active: when U.host:
  | [HostId Goal Action Ordered NextAction] = U.host
  | U.host <= 0
  | when HostId: U.host <= IdMap.HostId
  | when Goal:
    | Target,ActName = Goal
    | U.goal_act <= Acts.ActName
    | if Target.is_int
      then U.goal <= IdMap.Target
      else | U.goal <= U.unit_goal
           | U.goal.xyz.init{Target}
    | U.goal_serial <= U.goal.serial
  | U.action.load{IdMap Action}
  | U.ordered.load{IdMap Ordered}
  | U.next_action.load{IdMap NextAction}
| $serial <= Saved.serial
| for P $players: P.recount
| for P $players: P.picked <= (P.params.picked){IdMap.?}
| AEs = Saved.actions_enabled
| when got AEs: for Name,Enabled AEs:
  | when got Acts.Name: Acts.Name.enabled <= Enabled

main.load Path =
| File = Path.get
| less got File: bad "cant load [Path]"
| Saved = Path.get.utf8.parse{src Path}.0.0.group{2}.table
| Saved.filename <= Path.url.1
| $world.load{Saved}
