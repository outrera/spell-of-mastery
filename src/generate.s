use util


PCells = 10
Slots = 
Parts = t
BluePrints = t
Spans = @table
        [riverh,[h [riverhb] riverh1]
         riverv,[v [rivervb] riverv1]
        ]

Crosses = [[riverh riverv],[riverc1]]

type site_part{name w h tmap} units/[]

site_part.pw = $w/PCells
site_part.ph = $h/PCells

main.load_symta_file Path =
| Path <= "[$data]/[Path].txt"
| File = Path.get
| less got File: bad "cant load [Path]"
| Path.get.utf8.parse{src Path}

site.load_part Name =
| File = $main.load_symta_file{"parts/[Name]"}
| Saved = File.0.0.group{2}.table
| SW = Saved.w
| SH = Saved.h
| when SW%10 or SH%10: bad "[SW]x[SH] is not multiple of 10x10 for part [Name]"
| P = site_part Name SW SH $load_tile_map{Saved}
| P.units <= Saved.units
| P

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
| when got P: leave P
| P <= $load_part{PartName}
| Parts.PartName <= P
| P

site.get_blueprint BPName =
| BP = BluePrints.BPName
| when got BP: leave BP
| File = $main.load_symta_file{"bp/[BPName]"}
| BP <= File{[?1.0 ?2]}.table
| BluePrints.BPName <= BP
| BP

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

//FIXME: implement placement constraints, like shore should always be placed near edge of the map
// also add `cross` for shore mixed with river


site.generate W H =
| BlueprintName = \castle
| B = $get_blueprint{BlueprintName}
| $clear
| $w <= W*PCells
| $h <= H*PCells
| Slots <= dup W: dup H: 0
| $filename <= "default"
| $name <= "Default"
| $description <= ""
| $serial <= 0
| UsedSpansX = []
| UsedSpansY = []
| FreeSpansX = @shuffle: dup I W I
| FreeSpansY = @shuffle: dup I H I
| for SpanName B.spans:
  | less SpanName.is_text: SpanName <= SpanName.rand
  | Span = Spans.SpanName
  | when no Span: bad "missing span [SpanName]"
  | [Dir MustHave @PartSet] = Span
  | V = Dir >< v
  | when V:
    | swap FreeSpansX FreeSpansY
    | swap UsedSpansX UsedSpansY
    | swap W H
  | less FreeSpansY.end:
    | Y = pop FreeSpansY
    | push Y,SpanName UsedSpansY
    | ReqXYs = []
    | for PartName MustHave: less FreeSpansX.end:
      | X = pop FreeSpansX
      | push X,Y ReqXYs
    | Ps = []
    | for X W: less got ReqXYs.find{X,Y}:
      | when Ps.end: Ps <= PartSet.shuffle
      | PartName = Ps^pop
      | Isect = UsedSpansX.find{?0><X}
      | when got Isect:
        | IX,ISpanName = Isect
        | Pair = if V then [ISpanName SpanName] else [SpanName ISpanName]
        | CrossNames = Crosses.find{?0><Pair}
        | when got CrossNames: PartName <= CrossNames.1.rand
      | $place_part{(if V then Y,X else X,Y) PartName}
    | for X,Y ReqXYs: $place_part{(if V then Y,X else X,Y) MustHave^pop}
    | for PartName MustHave: say "no place for [PartName] in [SpanName]"
  | when V:
    | swap FreeSpansX FreeSpansY
    | swap UsedSpansX UsedSpansY
    | swap W H
| for PartName B.parts: $place_part{0 PartName}
| Ps = []
| for Y H: for X W:
  | less Slots.Y.X:
    | when Ps.end: Ps <= B.filler.shuffle
    | $place_part{X,Y Ps^pop}
| $create_borders
| for X,Y points{1 1 $w+1 $h+1}: $upd_pilar{X Y}
| Slots <= 0