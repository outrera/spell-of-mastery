use util


PCells = 10
Slots = 

Parts = [pond grass rocks castle forest
         riverh1 riverhb
         
        ]

Spans = @table
        [riverh,[h [riverhb] riverh1]
        //[riverh,[v [rivervb] riverv1]
         ]

Crosses = []

type site_part{name w h tmap} units/[]

site_part.pw = $w/PCells
site_part.ph = $h/PCells

site.load_part Name =
| Path = "[$main.data]/work/sites/[Name].txt"
| File = Path.get
| less got File: bad "cant load [Path]"
| Saved = Path.get.utf8.parse{src Path}.0.0.group{2}.table
| SW = Saved.w
| SH = Saved.h
| when SW%10 or SH%10: bad "[SW]x[SH] is not multiple of 10x10 for [Path]"
| P = site_part Name SW SH $load_tile_map{Saved}
| P.units <= Saved.units
| Name,P

site.find_place_for_part PW PH =
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

site.get_part PartName =
| P = Parts.PartName
| when no P: bad "missing part [PartName]"
| P

site.place_part XY P =
| when P.is_text: P <= $get_part{P}
| less XY:
  | XY <= $find_place_for_part{P.pw P.ph}
  | when XY.0 < 0: leave 0
| OX,OY = XY
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
| 1


site.load_parts = 
| Parts <= @table: map P Parts: $load_part{P}


SiteWish = \
  | filler: pond grass rocks
  | parts: castle forest //forest1 forest2 ruins
  | spans: riverh //riverv //shore
       //parentheses mean that only one of these could be placed,

//there can also be placement constraints, like shore should always be placed near edge of the map
//think about how rivew would translate into the shore.
//when two spans intersect, consider using special `cross` part, defined for each span
//also, dont check against Slots for span stage


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
| UsedSpansX = []
| UsedSpansY = []
| FreeSpansX = @shuffle: dup I W I
| FreeSpansY = @shuffle: dup I H I
| for SpanName SW.spans:
  | Span = Spans.SpanName
  | when no Span: bad "missing span [SpanName]"
  | [Dir MustHave @PartSet] = Span
  //| when Dir >< v: swap FreeSpansX FreeSpansY
  | less FreeSpansY.end:
    | Y = pop FreeSpansY
    | push Y UsedSpansY
    | ReqXYs = []
    | for PartName MustHave: less FreeSpansX.end:
      | X = pop FreeSpansX
      | push X,Y ReqXYs
    | Ps = []
    | for X W: less got ReqXYs.find{X,Y}:
      | when Ps.end: Ps <= PartSet.shuffle
      | $place_part{X,Y Ps^pop}
    | for X,Y ReqXYs: $place_part{X,Y MustHave^pop}
    | for PartName MustHave: say "no place for [PartName] in [SpanName]"
| for PartName SW.parts: $place_part{0 PartName}
| Ps = []
| for Y H: for X W:
  | less Slots.Y.X:
    | when Ps.end: Ps <= SW.filler.shuffle
    | $place_part{X,Y Ps^pop}
| $create_borders
| for X,Y points{1 1 $w+1 $h+1}: $updPilarGfxes{X Y}