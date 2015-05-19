use util

world.save =
| list w($w) h($h) serial($serial) cycle($cycle) turn($turn)
    filename | $filename
    name | $name
    description | $description
    params | map [K V] $params [K V]
    events | $events{}{?1}
    tids | $tid_map{}{?type}
    players | map P $players
              | [P.id P.name P.human P.color P.power P.moves
                 P.params.list P.research.list.keep{?1} P.mana]
    player | $player.id
    units | map U $units.skip{(?removed or ?mark)}
            | list U.id U.serial U.type U.xyz U.xy
                   U.anim U.anim_step U.facing
                   U.owner.id U.moved U.turn U.flags
    tilemap | map X $w: map Y $h:
              | $tilemap.getPilar{X+1 Y+1}.drop{1}

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
  | P.power <= Power
  | P.moves <= Moves
  | for K,V Params: P.params.K <= V
  | for N,R Research: P.research.N <= R
| $player <= $players.(Saved.player)
| for X Saved.units
  | [Id Serial Type XYZ SXYZ Anim AnimStep Facing Owner Moved Turn @Flags] = X
  | U = $alloc_unit{Type}
  | U.serial <= Serial
  | U.xy.init{SXYZ}
  | U.animate{Anim}
  | U.anim_step <= AnimStep
  | U.pick_facing{Facing}
  | less U.health or U.bank >< pentagram: Owner <= 0
  | U.owner <= $players.Owner
  | U.move{XYZ}
  | U.moved <= Moved
  | U.turn <= Turn
  | U.flags <= if Flags.size then Flags.0 else 0
  | when U.leader: U.owner.leader <= U
  | when U.bank >< pentagram: U.owner.pentagram <= U
  | IdMap.Id <= U
| $view.clear
| Leader = $player.units.find{?leader}
| when got Leader: $view.center_at{Leader.xyz}

main.load Path =
| Saved = Path.get.utf8.parse{src Path}.0.0.group{2}.table
| Saved.filename <= Path.url.1
| $world.load{Saved}
