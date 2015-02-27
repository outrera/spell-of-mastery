use util

world.save =
| list w($w) h($h) serial($serial) cycle($cycle) turn($turn)
    tids | $tid_map{}{?type}
    players | map P $players [P.id P.name P.human P.color P.power P.moves]
    player | $player.id
    units | map U $units.skip{?removed}
            | list U.id U.serial U.type U.xyz U.xy
                   U.anim U.anim_step U.facing
                   U.owner.id U.moved
    tilemap | $tilemap.root

main.save Path = Path.set{[version(0.1) @$world.save].as_text}

remap_tids LookupTable Xs =
| for I Xs.size
  | X = Xs.I
  | if X.is_int
    then when X >> 0: Xs.I <= LookupTable.X
    else remap_tids LookupTable X
| Xs

world.load Saved =
| $clear
| $w <= Saved.w
| $h <= Saved.h
| $serial <= Saved.serial
| TypeTids = $main.tid_map{}{?type,?id}.table
| LookupTable = Saved.tids{}{TypeTids.?}
| $tilemap.root <= remap_tids LookupTable Saved.tilemap
| for P points{0 0 $w $h}: $updPilarGfxes{P}
| $cycle <= Saved.cycle
| $turn <= Saved.turn
| IdMap = t
| for X Saved.players
  | [Id Name Human Color Power Moves] = X
  | P = $players.Id
  | P.name <= Name
  | P.human <= Human
  | P.color <= Color
  | P.power <= Power
  | P.moves <= Moves
| $player <= $players.(Saved.player)
| for X Saved.units
  | [Id Serial Type XYZ SXYZ Anim AnimStep Facing Owner Moved] = X
  | U = $alloc_unit{Type}
  | U.serial <= Serial
  | U.move{XYZ}
  | U.xy.init{SXYZ}
  | U.animate{Anim}
  | U.anim_step <= AnimStep
  | U.pick_facing{Facing}
  | U.owner <= $players.Owner
  | U.moved <= Moved
  | IdMap.Id <= U

main.load Path =
| Saved = Path.get.utf8.parse{src Path}.0.0.group{2}.table
| $world.load{Saved}
