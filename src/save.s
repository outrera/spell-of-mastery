main.save Path =
| Content = list
  version | 0.1
  w | $world.w
  h | $world.h
  unit_serial | $world.unit_serial
  cycle | $world.game.cycle
  turn | $world.game.turn
  tids | $tid_map{}{?type}
  units | map U $world.units.skip{?removed}
          | list U.id U.serial U.type U.xyz U.sub_xyz
                 U.anim U.anim_step U.facing U.owner
  tilemap | $world.tilemap.root
| Path.set{Content.as_text}

remap_tids LookupTable Xs =
| for I Xs.size
  | X = Xs.I
  | if X.is_int
    then when X >> 0: Xs.I <= LookupTable.X
    else remap_tids LookupTable X
| Xs

main.load Path =
| File = Path.get.utf8.parse{src Path}.0.0.group{2}.table
| TypeTids = $tid_map{}{?type,?id}.table
| LookupTable = File.tids{}{TypeTids.?}
| Tilemap = remap_tids LookupTable File.tilemap
| $world.load{File.w File.h File.unit_serial File.cycle File.turn
              Tilemap File.units}
