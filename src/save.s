use util

world.save =
| list w($w) h($h) serial($serial) cycle($cycle) turn($turn)
    filename | $filename
    name | $name
    description | $description
    tids | $tid_map{}{?type}
    players | map P $players
              | [P.id P.name P.human P.color P.power P.moves
                 P.params.list P.research.list.keep{?1}]
    player | $player.id
    units | map U $units.skip{(?removed or ?mark)}
            | list U.id U.serial U.type U.xyz U.xy
                   U.anim U.anim_step U.facing
                   U.owner.id U.moved
    tilemap | map X $w: map Y $h: $tilemap.getPilar{X+1 Y+1}

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
| for X $w: for Y $h: $tilemap.setPilar{X+1 Y+1 Tilemap.X.Y}
| $create_borders
| for P points{1 1 $w+1 $h+1}: $updPilarGfxes{P}
| for P points{1 1 $w+1 $h+1}: $update_move_map{P}
| $cycle <= Saved.cycle
| $turn <= Saved.turn
| IdMap = t
| for X Saved.players
  | [Id Name Human Color Power Moves Params Research] = X
  | P = $players.Id
  | P.name <= Name
  | P.human <= Human
  | P.color <= Color
  | P.power <= Power
  | P.moves <= Moves
  | for K,V Params: P.params.K <= V
  | for N,R Research: P.research.N <= R
| $player <= $players.(Saved.player)
| for X Saved.units
  | [Id Serial Type XYZ SXYZ Anim AnimStep Facing Owner Moved] = X
  | U = $alloc_unit{Type}
  | U.serial <= Serial
  | U.xy.init{SXYZ}
  | U.animate{Anim}
  | U.anim_step <= AnimStep
  | U.pick_facing{Facing}
  | U.move{XYZ}
  | U.owner <= $players.Owner
  | U.moved <= Moved
  | when U.leader: U.owner.leader <= U
  | when U.type >< special_pentagram: U.owner.pentagram <= U
  | IdMap.Id <= U

main.load Path =
| Saved = Path.get.utf8.parse{src Path}.0.0.group{2}.table
| $world.load{Saved}
