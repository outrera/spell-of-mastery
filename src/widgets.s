use gui

Main = No
Fonts = t
Tints = No

set_main NewMain =
| Main <= NewMain
| Tints <= Main.params.tints

skin F = Main.img{"ui_[F]"}

type font{@new_font Gs W H} glyphs/Gs widths/W height/H
font.as_text = "#font{}"
font N = have Fonts.N:
| S = Main.spr{"font_[N]"}
| [W H EX] = S.frames.0^|F => [F.w F.h F.xy.0]
| Glyphs = S.frames{}{F<[X Y W H].margins=>| F.xy <= 0,0
                                           | F.cut{X 0 W F.h}}
| Ws = Glyphs{[X Y W H].margins=>X+W-EX}
| Ws.0 <= W/2
| new_font Glyphs Ws H
font.width Line = | Ws = $widths; Line{C.code => Ws.(C-' '.code)+1}.sum
font.draw G P Text =
| X,Y = P
| Ls = Text.lines
| Ws = $widths
| Gs = $glyphs
| H = $height
| CodePoint = ' '.code
| CY = Y
| for L Ls
  | CX = X
  | for C L
    | I = C.code-CodePoint
    | W = Ws.I
    | G.blit{[CX CY] Gs.I}
    | W+1+!CX
  | !CY + H
font.format MaxLineWidth Text =
| SpaceWidth = $width{' '}
| Words = Text.replace{'\n' ' '}.split{' '}{Word=>[Word $width{Word}]}
| Line = []
| Lines = []
| LineWidth = 0
| till Words.end
  | Word,Width = pop Words
  | less Line.end: !Width+SpaceWidth
  | when Word >< ' '
    | Word <= ''
    | Width <= 0
  | when Word >< '<br>'
    | push Line Lines
    | Line <= []
    | LineWidth <= 0
    | Width <= 0
    | Word <= ''
  | when LineWidth+Width > MaxLineWidth: less Line.end:
    | push Line Lines
    | Line <= []
    | LineWidth <= 0
  | less Word >< '': push Word Line
  | !LineWidth+Width
| less Line.end: push Line Lines
| Lines{?flip.text{' '}}.flip.text{'\n'}

type txt.widget{font_name value} w h v value_/'' font
| $font <= font $font_name
txt.render =
| Text = "[if $value.is_fn then $value{}{} else $value]"
| when $value_ <> Text
  | $value_ <= Text
  | F = $font
  | $w <= $value_.lines{}{L => F.width{L}}.max
  | $h <= F.height
| Me
txt.draw G P = $font.draw{G P $value_}
txt.as_text = "#txt{[$value]}"

type bar.widget{V} value_/V.clip{0 100} bg/No
bar.render =
| have $bg: skin."bar-bg"
| Me
bar.value = $value_
bar.set_value New = $value_ <= New.clip{0 100}
bar.draw G P =
| G.blit{P $bg}
| G.rect{#347004 1 P+[3 3] [152*$value_/100 14]}


type button.widget{Text Fn state/normal skin/medium_large}
  value/Text on_click/Fn state/State sprite over w h
| $sprite <= Main.spr{"ui_button_[Skin]"} 
| $w <= $sprite.frames.normal.0.w
| $h <= $sprite.frames.normal.0.h
button.render = Me
button.draw  G P =
| State = $state
| when State >< normal and $over: State <= \over
| Sprite = $sprite
| BG = Sprite.frames.(case State over normal Else State).0
| G.blit{P BG}
| SF = Sprite.font
| when SF <> `none`
  | Shift = case State pressed [SF.5 SF.6] _ [0 0]
  | FontName = SF.| case State pressed+over(3) disabled(4) _(2)
  | F = font FontName
  | FW = F.width{$value}
  | FH = F.height
  | X = BG.w/2-FW/2 + SF.0
  | Y = BG.h/2-FH/2 + SF.1
  | F.draw{G P+[X Y]+Shift $value}


button.input In = case In
  [mice over S P] | $over <= S
  [mice left 1 P] | case $state normal: Me.state <= \pressed
  [mice left 0 P] | case $state pressed
                    | when $over: $on_click{}{}
                    | $state <= \normal
button.as_text = "#button{[$value]}"

type litem.widget{Text w/140 state/normal}
  text_/Text w/W h state/State font fw fh init
litem.render =
| when $init <> $state
  | $h <= "litem-[$state]"^skin.h
  | $font <= font: if $state >< normal then 'small' else "small_[$state]"
  | $fw <= $font.width{$text_}
  | $fh <= $font.height
  | $init <= $state
| Me
litem.text = $text_
litem.`!text` Text =
| $init <= 0
| $text_ <= Text
litem.draw G P =
| BG = "litem-[$state]"^skin
| G.blit{P BG rect/[0 0 $w-10 BG.h]}
| G.blit{P+[$w-10 0] BG rect/[BG.w-10 0 10 BG.h]}
| X = 2
| Y = BG.h/2-$fh/2
| $font.draw{G P+[X Y] $text_}
litem.input In = case In
  [mice left 1 P] | $state <= case $state normal(\picked) picked(\normal) X(X)

type droplist.widget{Xs f/(V=>) w/160}
     f/F w/W h/1 ih xs/[] drop rs picked over above_all p
| less Xs.size: Xs <= [' ']
| $xs <= Xs{(litem ? w/$w)}
| $f $text
droplist.text = $xs.$picked.text
droplist.`!text` T =
| $xs.$picked.text <= T
| $f $text
droplist.render =
| $rs <= map X $xs X.render
| case $rs [R@_]: $ih <= R.h
| when $drop: $h <= $ih*$rs.size
| less $drop: $h <= $ih
| Me
droplist.draw G P =
| when $drop
  | Y = 0
  | for R $rs
    | G.blit{P+[0 Y] R}
    | !Y + R.h
| less $drop
  | G.blit{P $rs.$picked}
  | A = Main.spr{"ui_arrow"}.frames.down_normal.0
  | G.blit{P+[$w-A.w 0] A}
| $rs <= 0
| No
droplist.input In = case In
  [mice over S P] | $over <= S
                  | $xs.$p.state <= case S 1(\picked) 0(\normal)
  [mice_move _ P] | when $drop
                    | $xs.$p.state <= \normal
                    | $p <= (P.1/$ih).clip{0 $xs.size-1}
                    | $xs.$p.state <= \picked
  [mice left 1 P] | $drop <= 1
                  | $p <= $picked
                  | $above_all <= 1
                  | $xs.$p.state <= \picked
  [mice left 0 P] | $drop <= 0
                  | $xs.$p.state <= \normal
                  | $picked <= $p
                  | $f $text
droplist.pick Name =
| for I,X $xs.i: when X.text >< Name
  | $picked <= I
  | leave

type litems.$box{Xs w/160 lines/5 f/(V=>)} f/F ih/No lines/Lines xs/Xs box picked o/No
| $box <= layV: dup $lines: litem '' w/W
| $offset <= 0
litems.offset = $o
litems.`!offset` NO =
| when NO >< $o: leave
| $o <= max 0: @clip 0 $xs.size-1 NO
| times K $lines
  | I = $o + K
  | Item = $box.items.K
  | if I < $xs.size
    then | Item.text <= $xs.I
         | Item.state <= if I >< $picked then \picked else \normal
    else | Item.text <= ''
         | Item.state <= \disabled
litems.value = $xs.$picked
litems.data = $xs
litems.`!data` Ys =
| $xs <= Ys
| $picked <= 0
| $o <= No
| $offset <= 0
litems.pick NP =
| less $xs.size: leave
| NP <= @clip 0 $xs.size-1 NP
| when NP <> $picked
  | K = $picked - $o
  | when K >> 0 and K < $lines:
    | $box.items.K.state <= \normal
  | $picked <= NP
  | $box.items.(NP-$o).state <= \picked
| $f $xs.NP
litems.input In = case In
  [mice left 1 P] | have $ih: $box.items.0.render.h
                  | $pick{P.1/$ih+$o}
litems.itemAt Point XY WH = [Me XY WH] //override lay's method

type slider_.widget{D f/(N=>) size/124 value/0.0 state/normal delta/No}
     dir/D f/F size/Size pos/0.0 state/State skin/No w/1 h/1 delta/Delta
| have $delta (10.0/$size.float)
| $value <= Value
slider_.value = $pos/$size.float
slider_.`!value` V =
| OV = $value
| $pos <= (V*$size.float).clip{0.0 $size.float}
| when $value <> OV: $f $value
slider_.render =
| S = skin "slider-[$dir]-normal"
| $w <= S.w
| $h <= S.h
| if $dir >< v then $h <= $size else $w <= $size
| Me
slider_.inc = !$value + $delta
slider_.dec = !$value - $delta
slider_.draw G P =
| BG = skin "slider-[$dir]-normal"
| K = skin "slider-knob"
| I = 0
| when $dir >< v
  | while I < $size
    | G.blit{P+[0 I] BG rect/[0 0 BG.w (min BG.h $size-I)]}
    | !I + BG.h
  | G.blit{P+[1 $pos.int*($size-K.h)/$size+1] K}
| when $dir >< h
  | while I < $size
    | G.blit{P+[I 0] BG rect/[0 0 (min BG.w $size-I) BG.h]}
    | !I + BG.w
  | G.blit{P+[$pos.int*($size-K.w)/$size+1 1] K}
slider_.input In = case In
  [mice_move _ P] | when $state >< pressed
                    | NP = @clip 0 $size: if $dir >< v then P.1 else P.0
                    | when NP <> $pos.int
                      | $pos <= NP.float
                      | $f $value
  [mice left 1 P] | when $state >< normal
                    | $state <= \pressed
                    | $input{mice_move,P,P}
  [mice left 0 P] | when $state >< pressed: $state <= \normal

type arrow.widget{D Fn state/normal skin/arrow}
  direction/D on_click/Fn state/State sprite
| $sprite <= Main.spr{"ui_[Skin]"}
arrow.render = $sprite.frames."[$direction]_[$state]".0
arrow.input In = case In
  [mice left 1 P] | when $state >< normal
                    | $state <= \pressed
                    | Repeat = => when $state >< pressed
                                  | $on_click{}{}
                                  | 1
                    | (get_gui).add_timer{0.25 Repeat}
  [mice left 0 P] | when $state >< pressed
                    | $on_click{}{}
                    | $state <= \normal
arrow.as_text = "#arrow{[$direction] state([$state])}"

slider D @Rest =
| S = slider_ D @Rest
| if D >< v
  then layV [(arrow up (=>S.dec)) S (arrow down (=>S.inc))]
  else layH [(arrow left (=>!S.dec)) S (arrow right (=>S.inc))]

type txt_input.widget{Text w/140 state/normal}
  text_/Text w/W h state/State font fw fh init
txt_input.render =
| when $init <> $state
  | $h <= "litem-[$state]"^skin.h
  | $font <= font: if $state >< normal then 'small' else "small_[$state]"
  | $fw <= $font.width{$text_}
  | $fh <= $font.height
  | $init <= $state
| Me
txt_input.value = $text_
txt_input.`!value` Text =
| $init <= 0
| $text_ <= Text
txt_input.draw G P =
| BG = "litem-[$state]"^skin
| G.blit{P BG rect/[0 0 $w-10 BG.h]}
| G.blit{P+[$w-10 0] BG rect/[BG.w-10 0 10 BG.h]}
| X = 2
| Y = BG.h/2-$fh/2
| $font.draw{G P+[X Y] $text_}
txt_input.wants_focus = 1
txt_input.input In = case In
  [focus State P] | $state <= if State then \picked else \normal
  [key backspace 1] | when $value.size: $value <= $value.lead
  [key K<1.size 1] | $value <= "[$value][K]"

type img.widget{Path} path/Path
img.render = Main.img{"image_[$path]"}


folder_nomalized Path = 
| Xs = Path.items
| Folders = Xs.keep{is."[_]/"}
| Files = Xs.skip{is."[_]/"}
| Parent = if Path >< '/' or Path.last >< ':' then [] else ['../']
| [@Parent @Folders @Files]

type folder_litems.$litems{Root w/300 lines/10 f/(V=>)} root/Root f/F litems
| when $root.last <> '/': $root <= "[$root]/"
| $litems <= litems lines/Lines w/W f/(N => F "[$root][N]")
                    $root^folder_nomalized
folder_litems.input In = case In
  [mice double_left 1 P] | R = if $litems.value >< '../'
                               then "[$root.lead.url.0]"
                               else "[$root][$litems.value]"
                         | when R.folder
                           | $root <= R
                           | $litems.data <= $root^folder_nomalized
  Else | $litems.input{In}
folder_litems.itemAt Point XY WH = [Me XY WH]

folder_widget Root F =
| FL = folder_litems Root f/F
| S = slider size/124 v f/(N => FL.offset <= @int N*FL.data.size.float)
| layH [FL S]


export set_main skin font txt button litem droplist slider folder_widget 
       litems txt_input img
