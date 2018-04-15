use util

Parts = [pond grass rocks]

type site_part{name w h tmap} units/[]

site.load_part Name =
| Path = "[$main.data]/work/sites/[Name].txt"
| File = Path.get
| less got File: bad "cant load [Path]"
| Saved = Path.get.utf8.parse{src Path}.0.0.group{2}.table
| P = site_part Name Saved.w Saved.h $load_tile_map{Saved}
| P.units <= Saved.units
| P

site.place_part X Y P =
| X *= 10
| Y *= 10
| TM = P.tmap
| for YY P.h: for XX P.w:
  | $set_pilar{1+X+XX 1+Y+YY TM.XX.YY}

site.generate W H =
| $clear
| $w <= W*10
| $h <= H*10
| $filename <= "default"
| $name <= "Default"
| $description <= ""
| $serial <= 0
| Parts <= map P Parts: P,$load_part{P}
| for Y H: for X W: 
  | P = Parts.0.1
  //| P = Parts.rand.1
  | $place_part{X Y P}
| $create_borders
| for X,Y points{1 1 $w+1 $h+1}: $updPilarGfxes{X Y}