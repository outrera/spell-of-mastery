use gui main_data fxn

Fonts = t

skin F = get_main{}.img{"ui_[F]"}

type font{@new_font Gs W H} glyphs/Gs widths/W height/H
font.as_text = "#font{}"
font N = have Fonts.N:
| S = get_main{}.spr{"font_[N]"}
| [W H EX] = S.0^|F => [F.w F.h F.xy.0]
| FrameList = map I S.nframes: S.I
| Glyphs = FrameList{F<[X Y W H].margins=>| F.xy <= 0,0
                                          | F.cut{X 0 W F.h}}
| Ws = Glyphs{[X Y W H].margins=>X+W-EX}.list
| Ws.0 <= W/2
| new_font Glyphs.list Ws H
font.width Line =
| Ws = $widths
| CodePoint = ' '.code
| R = Line.size
| for C Line: fxn: R += Ws.(C.code-CodePoint)
| R
font.draw G X Y Text =
| Ls = Text.lines
| Ws = $widths
| Gs = $glyphs
| H = $height
| CodePoint = ' '.code
| CY = Y
| fxn: for L Ls
  | CX = X
  | for C L
    | I = C.code-CodePoint
    | W = Ws.I
    | G.blit{CX CY Gs.I}
    | CX += W+1
  | CY += H
  
font.draw_alpha G X Y Alpha Text =
| Ls = Text.lines
| Ws = $widths
| Gs = $glyphs
| H = $height
| CodePoint = ' '.code
| CY = Y
| fxn: for L Ls
  | CX = X
  | for C L
    | I = C.code-CodePoint
    | W = Ws.I
    | Glyph = Gs.I
    | Glyph.alpha{Alpha}
    | G.blit{CX CY Glyph}
    | CX += W+1
  | CY += H
font.format MaxLineWidth Text =
| SpaceWidth = $width{' '}
| Words = Text.replace{'\n' ' '}.split{' '}{Word=>[Word $width{Word}]}
| Line = []
| Lines = []
| LineWidth = 0
| till Words.end
  | Word,Width = pop Words
  | less Line.end: Width += SpaceWidth
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
  | LineWidth += Width
| less Line.end: push Line Lines
| Lines{?flip.text{' '}}.flip.text{'\n'}

type txt.widget{font_name value_} w h v font
| $font <= font $font_name
txt.value = "[if $value_.is_fn then $value_{}{} else $value_]"
txt.`=value` V = $value_ <= V
txt.render =
| Text = $value
| F = $font
| $w <= Text.lines{}{L => F.width{L}}.max
| $h <= F.height
| Me
txt.draw G X Y = $font.draw{G X Y $value}
txt.as_text = "#txt{[$value]}"

type bar.widget{V} value_/V.clip{0 100} bg/No
bar.render =
| have $bg: skin."bar-bg"
| Me
bar.value = $value_
bar.set_value New = $value_ <= New.clip{0 100}
bar.draw G X Y =
| G.blit{X Y $bg}
| G.rectangle{#347004 1 X+3 Y+3 152*$value_/100 14}

type button.widget{Text Fn state/normal skin/medium_large}
  text/Text value on_click/Fn state_/State sprite over w h
| $sprite <= get_main{}.spr{"ui_button_[Skin]"} 
| $w <= $sprite.'normal'.w
| $h <= $sprite.'normal'.h
button.state = $state_
button.`=state` V =
| when V><normal and $state><pressed: leave
| $state_ <= V


button.render = Me
button.draw G PX PY =
| State = $state_
| when State >< normal and $over: State <= \over
| Sprite = $sprite
| BG = Sprite.|case State over normal Else State
| G.blit{PX PY BG}
| SF = Sprite.font
| when SF <> `none`
  | ShiftX = 0
  | ShiftY = 0
  | case State pressed
    | ShiftX <= SF.5
    | ShiftY <= SF.6
  | FontName = SF.| case State pressed+over(3) disabled(4) _(2)
  | F = font FontName
  | FW = F.width{$text}
  | FH = F.height
  | X = BG.w/2-FW/2 + SF.0
  | Y = BG.h/2-FH/2 + SF.1
  | F.draw{G PX+X+ShiftX PY+Y+ShiftY $text}
button.input In = case In
  [mice over S P] | $over <= S
  [mice left 1 P] | case $state normal: $state_ <= \pressed
  [mice left 0 P] | case $state pressed
                    | when $over: $on_click{}{}
                    | $state_ <= \normal
button.as_text = "#button{[$text]}"

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
litem.`=text` Text =
| $init <= 0
| $text_ <= Text
litem.draw G PX PY =
| BG = "litem-[$state]"^skin
| G.blit{PX PY BG.rect{0 0 $w-10 BG.h}}
| G.blit{PX+$w-10 PY BG.rect{BG.w-10 0 10 BG.h}}
| X = 2
| Y = BG.h/2-$fh/2
| $font.draw{G PX+X PY+Y $text_}
litem.input In = case In
  [mice left 1 P] | $state <= case $state normal(\picked) picked(\normal) X(X)

type droplist.widget{Xs f/(V=>) w/160}
     f/F w/W h/1 ih xs/[] drop rs picked over above_all p
| less Xs.size: Xs <= [' ']
| $xs <= Xs{(litem ? w/$w)}
| $f $text
droplist.text = $xs.$picked.text
droplist.`=text` T =
| $xs.$picked.text <= T
| $f $text
droplist.render =
| $rs <= map X $xs X.render
| case $rs [R@_]: $ih <= R.h
| when $drop: $h <= $ih*$rs.size
| less $drop: $h <= $ih
| Me
droplist.draw G PX PY =
| when $drop
  | Y = 0
  | for R $rs
    | G.blit{PX PY+Y R}
    | Y += R.h
| less $drop
  | G.blit{PX PY $rs.$picked}
  | A = get_main{}.spr{"ui_arrow"}.'down_normal'
  | G.blit{PX+$w-A.w PY A}
| $rs <= 0
| No
droplist.input In = case In
  [mice over S P] | $over <= S
                  | $xs.$p.state <= case S 1(\picked) 0(\normal)
  [mice_move _ P] | when $drop
                    | $xs.$p.state <= \normal
                    | $p <= (P.1/$ih).clip{0 $xs.size-1}
                    | $xs.$p.state <= \picked
  [mice left 1 P] | $over <= 1
                  | $drop <= 1
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

type litems.$box{W H Xs F}
    f/F ih/No lines xs/Xs box picked o/No ls
| Pad = "litem-disabled"^skin
| LH = Pad.h
| $lines <= max 1 H/LH
| $ls <= dup $lines: litem '' w/W
| LHH = $lines*LH
| $box <= layV: if LHH><H then $ls else [@$ls Pad.cut{0 0 W LH}]
| $offset <= 0
litems.offset = $o
litems.`=offset` NO =
| when NO >< $o: leave
| $o <= max 0: @clip 0 $xs.size-1 NO
| times K $lines
  | I = $o + K
  | Item = $ls.K
  | if I < $xs.size
    then | Item.text <= $xs.I
         | Item.state <= if I >< $picked then \picked else \normal
    else | Item.text <= ''
         | Item.state <= \disabled
litems.value = $xs.$picked
litems.data = $xs
litems.`=data` Ys =
| $xs <= Ys
| $picked <= 0
| $o <= No
| $offset <= 0
litems.pick NP =
| less $xs.size: leave
| NP <= @clip 0 $xs.size-1 NP
| when NP <> $picked:
  | K = $picked - $o
  | when K >> 0 and K < $lines: $box.items.K.state <= \normal
  | $picked <= NP
  | K = NP-$o
  | when K >> 0 and K < $lines: $box.items.K.state <= \picked
| $f $xs.NP
litems.input In = case In
  [mice left 1 P] | have $ih: $box.items.0.render.h
                  | $pick{P.1/$ih+$o}
litems.itemAt Point XY WH = [Me XY WH] //override lay`s method

type slider_.widget{Dir Size F}
     dir/Dir
     size/Size
     f/F
     pos/0.0
     state/normal
     skin/No
     w/1 h/1
     delta/0.01
| $value <= 0.0
slider_.value = $pos
slider_.`=value` V =
| NP = V.clip{0.0 1.0}
| when $pos <> NP:
  | $pos <= NP
  | $f $pos
slider_.render =
| S = skin "slider-[$dir]-normal"
| $w <= S.w
| $h <= S.h
| if $dir >< v then $h <= $size else $w <= $size
| Me
slider_.inc = $value += $delta
slider_.dec = $value -= $delta
slider_.draw G PX PY =
| BG = skin "slider-[$dir]-normal"
| K = skin "slider-knob"
| I = 0
| when $dir >< v
  | while I < $size
    | G.blit{PX PY+I BG.rect{0 0 BG.w (min BG.h $size-I)}}
    | I += BG.h
  | G.blit{PX+1 PY+($pos*($size-K.h).float).int K}
| when $dir >< h
  | while I < $size
    | G.blit{PX+I PY BG.rect{0 0 (min BG.w $size-I) BG.h}}
    | I += BG.w
  | G.blit{PX+($pos*($size-K.w).float).int PY+1 K}
slider_.input In = case In
  [mice_move _ P] | when $state >< pressed:
                    | NP = @clip 0 $size: if $dir >< v then P.1 else P.0
                    | $value <= NP.float/$size.float
  [mice left 1 P] | when $state >< normal
                    | $state <= \pressed
                    | $input{mice_move,P,P}
  [mice left 0 P] | when $state >< pressed: $state <= \normal

type arrow.widget{D Fn state/normal skin/arrow}
  direction/D on_click/Fn state/State sprite
| $sprite <= get_main{}.spr{"ui_[Skin]"}
arrow.render = $sprite."[$direction]_[$state]"
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

slider D Sz F =
| S = No
| Dec = => S.dec
| Inc = => S.inc
| if D >< v
  then | A = arrow up Dec
       | B = arrow down Inc
       | S <= slider_ D max{0 Sz-A.render.h*2} F
       | layV A,S,B
  else | A = arrow left Dec
       | B = arrow right Inc
       | S <= slider_ D max{Sz-A.render.w*2} F
       | layH A,S,B

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
txt_input.`=value` Text =
| $init <= 0
| $text_ <= Text
txt_input.draw G PX PY =
| BG = "litem-[$state]"^skin
| G.blit{PX PY BG.rect{0 0 $w-10 BG.h}}
| G.blit{PX+$w-10 PY BG.rect{BG.w-10 0 10 BG.h}}
| X = 2
| Y = BG.h/2-$fh/2
| $font.draw{G PX+X PY+Y $text_}
txt_input.wants_focus = 1
txt_input.input In = case In
  [focus State P] | $state <= if State then \picked else \normal
  [key backspace 1] | when $value.size: $value <= $value.lead
  [key K<1.size 1] | $value <= "[$value][K]"

type pic.widget{Src}
   src/Src value on_click/0 state_/normal over w/1 h/1
pic.state = $state_
pic.`=state` V =
| when V><normal and $state><pressed: leave
| $state_ <= V
pic.render = Me
pic.draw G PX PY =
| Img = if $src.is_text then get_main{}.img{"[$src]"}
        else if $src.is_fn then ($src){Me}
        else leave
| $w <= Img.w
| $h <= Img.h
| G.blit{PX PY Img}
pic.input In = case In
  [mice over S P] | $over <= S
  [mice left 1 P] | case $state normal: $state_ <= \pressed
  [mice left 0 P] | case $state pressed
                    | when $over and $on_click: $on_click{}{}
                    | $state_ <= \normal



folder_nomalized Path = 
| Xs = Path.items
| Folders = Xs.keep{is."[_]/"}
| Files = Xs.skip{is."[_]/"}
| Parent = if Path >< '/' or Path.last >< ':' then [] else ['../']
| [@Parent @Folders.sort @Files.sort]

type folder_litems.$litems{W H Root F} root/Root f/F litems
| when not $root.size or $root.last <> '/': $root <= "[$root]/"
| $litems <= litems W H $root^folder_nomalized | N => $f "[$root][N]"
folder_litems.cd NewRoot =
| $root <= NewRoot
| $litems.data <= $root^folder_nomalized
folder_litems.input In = case In
  [mice double_left 1 P] | R = if $litems.value >< '../'
                               then "[$root.lead.url.0]"
                               else "[$root][$litems.value]"
                         | when R.folder: $cd{R}
  Else | $litems.input{In}
folder_litems.itemAt Point XY WH = [Me XY WH]

type folder_widget.$lay{W H Root F} lay base
| FL = folder_litems W H Root F
| $base <= FL
| S = slider v H | N => FL.offset <= @int N*FL.data.size.float
| $lay <= layH FL,S
folder_widget.folder = $base.root
folder_widget.`=folder` NewFolder = $base.cd{NewFolder}

type infoline.widget{} info_text/txt{small ''}
infoline.render =
| $info_text.value <= (get_gui).mice_widget.infoline
| $info_text.render

export skin font txt button litem droplist slider folder_widget 
       litems txt_input pic infoline
