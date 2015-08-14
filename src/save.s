use util rle

world.save =
| ActivePlayers = dup 32 0
| Units = map U $units.skip{(?removed or ?mark)}
  | ActivePlayers.(U.owner.id) <= 1
  | list U.id U.serial U.type U.xyz U.xy
         U.anim U.anim_step U.facing
         U.owner.id U.moved U.turn U.flags U.hits
| list w($w) h($h) serial($serial) cycle($cycle) turn($turn)
    filename | $filename
    name | $name
    description | $description
    params | map [K V] $params [K V]
    events | $events{}{?1}
    tids | $tid_map{}{?type}
    players | map P $players
              | [P.id P.name P.human P.color 0 0
                 P.params.list P.research.list.keep{?1} P.mana]
    player | $player.id
    units | Units
    tilemap | map X $w: map Y $h:
              | $tilemap.getPilar{X+1 Y+1}.drop{1}
    explored | map Id,Active ActivePlayers.i.keep{?.1}
               | [Id $players.Id.sight{}{X=>rle_encode X}]
    actions_enabled | map Name,Act $main.params.acts: Name,Act.enabled

main.save Path = Path.set{[version(0.1) @$world.save].as_text}

remap_tids LookupTable Xs =
| for Ys Xs: for Zs Ys: for I Zs.size
  | Id = Zs.I
  | when Id >> 0: Zs.I <= LookupTable.Id
| Xs

world.load Saved =
| $clear
| $w <= Saved.w
| $h <= Saved.h
| $filename <= Saved.filename
| $name <= Saved.name
| $description <= Saved.description
| $events <= if got Saved.events then Saved.events.i else []
| $serial <= Saved.serial
| when got!it Saved.params: for [K V] it: $params.K <= V
| TypeTids = $main.tid_map{}{?type,?id}.table
| LookupTable = Saved.tids{}{TypeTids.?}
| Tilemap = remap_tids LookupTable Saved.tilemap
| BaseId = TypeTids.base_
| for X $w: for Y $h: $tilemap.setPilar{X+1 Y+1 [BaseId@Tilemap.X.Y]}
| $create_borders
| for P points{1 1 $w+1 $h+1}: $updPilarGfxes{P}
| for P points{1 1 $w+1 $h+1}: $update_move_map{P}
| $cycle <= Saved.cycle
| $turn <= Saved.turn
| IdMap = t
| for X Saved.players
  | [Id Name Human Color Power Moves Params Research Mana] = X
  | P = $players.Id
  | P.name <= Name
  | P.human <= Human
  | P.color <= Color
  | P.mana <= Mana
  | for K,V Params: P.params.K <= V
  | for N,R Research: P.research.N <= R
| $player <= $players.(Saved.player)
| for X Saved.units
  | [Id Serial Type XYZ SXYZ Anim AnimStep Facing Owner Moved Turn Flags @Hits]
        = X
  | U = $alloc_unit{Type owner/$players.Owner}
  | less U.health or U.ai >< pentagram:
    | U.change_owner{$players.0}
  | U.serial <= Serial
  | U.xy.init{SXYZ}
  | U.animate{Anim}
  | U.anim_step <= AnimStep
  | U.pick_facing{Facing}
  | U.move{XYZ}
  | U.moved <= Moved
  | U.turn <= Turn
  | U.flags <= Flags
  | U.hits <= if Hits.size then Hits.0 else 0
  | when U.leader: U.owner.leader <= U
  | when U.bank >< pentagram: U.owner.pentagram <= U
  | IdMap.Id <= U
| for [Id@_] Saved.players: $players.Id.recalc
| Explored = Saved.explored
| when got Explored:
  | for PID,Sight Explored
    | PS = $players.PID.sight
    | for I PS.size PS.I.init{Sight.I^rle_decode}
| AEs = Saved.actions_enabled
| Acts = $main.params.acts
| when got AEs: for Name,Enabled AEs: Acts.Name.enabled <= Enabled

main.load Path =
| File = Path.get
| less got File: bad "cant load [Path]"
| Saved = Path.get.utf8.parse{src Path}.0.0.group{2}.table
| Saved.filename <= Path.url.1
| $world.load{Saved}
