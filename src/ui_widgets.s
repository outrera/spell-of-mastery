use gui widgets ui_icon

DialogResult = 0

type message_box.$base{ui} base title text buttons width margin/[0 0]
| BG = $ui.img{ui_panel5}
| $width <= BG.w
| $title <= txt medium '' 
| $text <= txt medium ''
| button_click Result = 
  | DialogResult <= Result
  | $ui.unpause
  | $show <= 0
| Buttons =
| Buttons <= 3{I => button 'Text' skin/medium_small: =>
                    | button_click Buttons.I.value}
| $buttons <= map B Buttons: hidden B
| MarginW = 65
| MarginH = 50
| $margin.init{[MarginW MarginH]}
| $base <= hidden: dlg: mtx
  | 270-MarginW 100-MarginH | BG
  | 290 110 | $title
  | 276 140 | $text
  | 290 395 | layH s/5 $buttons

message_box.display Buttons Title Text =
| DialogResult <= 0
| $title.value <= Title
| $text.value <= $text.font.format{$width-$margin.0*2 Text}
| for B $buttons: B.show <= 0
| for [I [Value Text]] Buttons.i
  | B = $buttons.I
  | B.show <= 1
  | B.text <= Text
  | B.value <= Value
| $show <= 1
| $ui.pause

main.show_message Title Text buttons/[ok,'Ok'] =
| $ui.message_box.display{Buttons Title Text}

main.dialog_result = DialogResult

type unit_panel.widget{ui} w/0 h/0 unit bg
| $bg <= $ui.img{ui_unit_panel}
unit_panel.set_unit Unit =
| $unit <= Unit
| if $unit
  then | $w <= $bg.w
       | $h <= $bg.h
  else | $w <= 0
       | $h <= 0

unit_panel.draw G X Y =
| less $unit: leave
| Icon = $unit.main.sprites."icons_[$unit.icon or $unit.type]"
| IconBg = $unit.main.sprites.ui_icon_bg
| G.blit{X+3 Y+20 IconBg.frames.0}
| when got Icon: G.blit{X+3 Y+20 Icon.frames.0}
| G.blit{X Y $bg}
| Font = font medium
//| Font.draw{G X+85 Y+48 "[$unit.owner.name]"}
| Font.draw{G X+4 Y "[$unit.title or $unit.class_name.title]"}
| Font.draw{G X+23 Y+74"[max 0 $unit.health]"}
| Font.draw{G X+70 Y+28"[$unit.attack]"}
| Font.draw{G X+60 Y+64"[$unit.armor]"}

type world_props.$base{world callback}
     filename name description width height base
| $filename <= txt_input{''}
| $name <= txt_input{''}
| $description <= txt_input{w/240 ''}
| $width <= txt_input{''}
| $height <= txt_input{''}
| PropFields = ['File Name:',$filename
                'World Name:',$name 
                'Description:',$description
                'Width:',$width
                'Height:',$height
               ]
| MarginW = 65
| MarginH = 50
| $base <= dlg: mtx
  | -MarginW  -MarginH | $world.main.img{ui_panel5}
  | 130  10 | txt medium 'Properties'
  |  15  40 | layV s/8 PropFields{(txt small ?0)}
  | 100  36 | layV PropFields{?1}
  |  15 305 | button 'Done' skin/medium_small: => ($callback){Me}

world_props.update =
| W = $world
| $filename.value <= W.filename
| $name.value <= W.name
| $description.value <= W.description
| $width.value <= "[W.w]"
| $height.value <= "[W.h]"


type info_line.widget{ui} info_text/txt{small ''}

info_line.render =
| $info_text.value <= ""
| case $ui.act_icons.keep{(?.show and ?.over)} [Icon@_]
  | ActName = Icon.data
  | Unit = Icon.unit
  | Act = $ui.params.acts.ActName
  | Info = Act.title
  | Number = Icon.text.2
  | Cool = Unit.cooldown_of{ActName}
  | ResearchRemain = Unit.owner.research_remain{Act}
  | Cost = Act.cost
  | if Cool then
      | Info <= "[Info] ([Cool.0/24] SECONDS TO RECHARGE)"
    else if ResearchRemain then
      | Info <= "research [Info] ([Act.lore.0] LORE, [Act.lore.1] MANA)"
    else when got Cost and Cost:
      | Info <= "cast [Info] ([Cost] MANA)"
  | $info_text.value <= Info.upcase
| $info_text.render

type load_world_dlg.$base{world folder cancelCB loadCB}
  filename base picked
| LoadButton = button 'Load' skin/medium_small: => ($loadCB){$picked}
| LoadButton.state <= 'disabled'
| MarginW = 65
| MarginH = 50
| $base <= dlg: mtx
  | -MarginW   -MarginH | $world.main.img{ui_panel5}
  | 130  10 | txt medium 'Load World'
  |  15  40 | folder_widget $folder: File =>
              | $picked <= File
              | LoadButton.state <= if File.exists and File.urls.size >< 0
                then 'normal'
                else 'disabled'
  |  15 305 | LoadButton
  | 220 305 | button 'Cancel' skin/medium_small: => ($cancelCB){}

type credits_roll.widget{ui text} cycle txt
| $txt <= txt medium $text

credits_roll.draw G PX PY =
| R = $txt.render
| R.draw{G PX+10 PY+$ui.height-$cycle/5}
| !$cycle+1

credits_roll.reset = $cycle <= 0

export message_box unit_panel world_props info_line load_world_dlg credits_roll