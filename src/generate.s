use util


PCells = 10
Slots = 

Parts = [pond grass rocks castle forest
         /*river_ns,[0 riverns1 riverns2 riverns3 riverns4 riverns5 riverns6]*/]

type site_part{name w h tmap} units/[]

site_part.pw = $w/PCells
site_part.ph = $h/PCells

site.load_part Name =
| Path = "[$main.data]/work/sites/[Name].txt"
| File = Path.get
| less got File: bad "cant load [Path]"
| Saved = Path.get.utf8.parse{src Path}.0.0.group{2}.table
| P = site_part Name Saved.w Saved.h $load_tile_map{Saved}
| P.units <= Saved.units
| P

site.place_part OX OY P =
| X = OX*10
| Y = OY*10
| TM = P.tmap
| for YY P.h: for XX P.w:
  | $set_pilar{1+X+XX 1+Y+YY TM.XX.YY}
| for UD P.units
  | [Type Id Serial Owner XYZ FXYZ Facing Flags HP Active] = UD
  | U = $players.Owner.alloc_unit{Type}
  | U.move{XYZ+[X Y 0]}
  | when Facing.is_list:
    | U.sprite <= $main.sprites.(Facing.0)
    | Facing <= Facing.1
  | U.pick_facing{Facing}
| PW = P.pw
| PH = P.ph
| for YY PH: for XX PW: Slots.(OY+YY).(OX+XX) <= 1

site.find_place_for_part P =
| PW = P.pw
| PH = P.ph
| Ps = []
| W = $w/PCells
| H = $h/PCells
| for Y H: for X W
  | for YY PH: for XX PW:
    | when YY+Y>>W or XX+X>>H or Slots.(Y+YY).(X+XX): _goto next
  | push X,Y Ps
  | _label next
| when Ps.end: leave -1,-1
| Ps.rand

site.load_parts = 
| Parts <= @table: map P Parts: P,$load_part{P}


SiteWish = \
  | small: pond grass rocks
  | medium: castle forest //forest1 forest2 ruins
  | huge: //(river_ns river_we) shore
       //parentheses mean that only one of these should be placed,
       //frequency could be added for each, as a number,
       //generator will just duplicate that item, before shuffling

//first we place huge, then large then small
//there can also be constraints, like shore should always be placed near edge of the map


site.generate W H =
| $clear
| $w <= W*PCells
| $h <= H*PCells
| Slots <= dup W: dup H: 0
| $filename <= "default"
| $name <= "Default"
| $description <= ""
| $serial <= 0
| $load_parts
| SW = SiteWish.tail{}{[?1.0 ?2]}.table
| for PartName SW.medium:
  | P = Parts.PartName
  | X,Y = $find_place_for_part{P}
  | less X<0: $place_part{X Y P}
| Ps = []
| for Y H: for X W:
  | less Slots.Y.X:
    | when Ps.end: Ps <= SW.small.shuffle
    | P = Parts.(pop Ps)
    | $place_part{X Y P}
| $create_borders
| for X,Y points{1 1 $w+1 $h+1}: $updPilarGfxes{X Y}