use util

world.save =
| list w($w) h($h) serial($serial) cycle($cycle) turn($turn)
    filename | $filename
    name | $name
    description | $description
    tids | $tid_map{}{?type}
    players | map P $players [P.id P.name P.human P.color P.power P.moves]
    player | $player.id
    units | map U $units.skip{(?removed or ?mark)}
            | list U.id U.serial U.type U.xyz U.xy
                   U.anim U.anim_step U.facing
                   U.owner.id U.moved
    tilemap | map X $w: map Y $h: $tilemap.getPilar{X Y}

main.save Path = Path.set{[version(0.1) @$world.save].as_text}

remap_tids LookupTable Xs =
| for Ys Xs: for Zs Ys: for I Zs.size
  | Z = Zs.I
  | Id = Z.1
  | when Id >> 0: Z.1 <= LookupTable.Id
| Xs

world.load Saved =
| $clear
| $w <= Saved.w
| $h <= Saved.h
| $filename <= Saved.filename
| $name <= Saved.name
| $description <= Saved.description
| $serial <= Saved.serial
| TypeTids = $main.tid_map{}{?type,?id}.table
| LookupTable = Saved.tids{}{TypeTids.?}
| Tilemap = remap_tids LookupTable Saved.tilemap
| for X $w: for Y $h: $tilemap.setPilar{X Y Tilemap.X.Y}
| $create_borders
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
