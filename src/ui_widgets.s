use gui widgets ui_icon

DialogResult = 0

type message_box.$base{ui} base title text buttons width margin/[0 0] click
| BG = $ui.img{ui_scroll}
| $width <= BG.w
| $title <= txt medium '' 
| $text <= txt medium ''
| button_click Result = 
  | DialogResult <= Result
  | $ui.unpause
  | $ui.world.paused <= 0
  | $show <= 0
  | when $click: $click{}{DialogResult}
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

message_box.display Buttons Title Text Click =
| DialogResult <= 0
| $title.value <= Title
| $click <= Click
| $text.value <= $text.font.format{$width-$margin.0*2 Text}
| for B $buttons: B.show <= 0
| for [I [Value Text]] Buttons.i
  | B = $buttons.I
  | B.show <= 1
  | B.text <= Text
  | B.value <= Value
| $show <= 1
| $ui.pause
| $ui.world.paused <= 1

main.show_message Title Text buttons/[ok,'Ok'] click/0 =
| $ui.message_box.display{Buttons Title Text Click}

main.dialog_result = DialogResult

type world_props.$base{world callback} name description width height base
| $name <= txt_input{''}
| $description <= txt_input{w/240 ''}
| $width <= txt_input{''}
| $height <= txt_input{''}
| PropFields = ['World Name:',$name 
                'Description:',$description
                'Width:',$width
                'Height:',$height
               ]
| MarginW = 65
| MarginH = 50
| $base <= dlg: mtx
  | -MarginW  -MarginH | $world.main.img{ui_scroll}
  | 130  10 | txt medium 'Properties'
  |  15  40 | layV s/8 PropFields{(txt small ?0)}
  | 100  36 | layV PropFields{?1}
  |  15 305 | button 'Done' skin/medium_small: => ($callback){Me}

world_props.update =
| W = $world
| $name.value <= W.name
| $description.value <= W.description
| $width.value <= "[W.w]"
| $height.value <= "[W.h]"


Indicators = 0
type resource_counters.widget{view} world w/0 h/0
| $world <= $view.world

resource_counters.main = $world.main

resource_counters.draw G X Y =
| less Indicators: Indicators <= $main.img{ui_indicators}
| Cursor = 
| IX = ($view.w-Indicators.w)/2
| IY = 0
| P = $world.human
| G.blit{IX IY Indicators}
| Param = P.params
| Font = font medium
| Font.draw{G IX+36 IY+2 "[P.mana]"}
| Font.draw{G IX+148 IY+2 "[P.lore]"}
| Font.draw{G IX+232 IY+2 "[$world.turn]:[$world.player]"}
| Debug = $world.params.debug
| when got Debug: Font.draw{G IX+148 IY+32 "[Debug]"}

type notification_widget.widget{view} world w/0 h/0
| $world <= $view.world
notification_widget.main = $world.main
notification_widget.draw G X Y =
| Font = font medium
| C = 24
| Clock = clock
| for [Expires Chars] $world.notes: when Clock < Expires:
  | Font.draw{G 16 Y-C "* [Chars.text]"}
  | C+=16

type save_dlg.$base{world start cancelCB loadCB}
  base picked title filename button widget
| $button <= button 'Save' skin/medium_small: => ($loadCB){$picked}
| $button.state <= 'normal'
| MarginW = 65
| MarginH = 50
| $title <= txt medium 'Save'
| $filename <= txt_input{''}
| $widget <= folder_widget $start: File =>
  | $picked <= File
  | FN = File.url.1
  | when FN<>'': $filename.value <= FN
| $base <= dlg: mtx
  | -MarginW   -MarginH | $world.main.img{ui_scroll}
  | 130  10 | $title
  |  15  40 | $filename
  |  15  60 | $widget
  |  15 305 | $button
  | 220 305 | button 'Cancel' skin/medium_small: => ($cancelCB){}
save_dlg.folder = $widget.folder
save_dlg.`=folder` V = $widget.folder <= V
save_dlg.render =
| $button.state <= if $filename.value<>'' then \normal else \disabled
| $base.render

type load_dlg.$base{world start cancelCB loadCB}
  filename base picked title widget
| LoadButton = button 'Load' skin/medium_small: => ($loadCB){$picked}
| LoadButton.state <= 'disabled'
| MarginW = 65
| MarginH = 50
| $title <= txt medium 'Load'
| $widget <= folder_widget $start: File =>
  | $picked <= File
  | LoadButton.state <= if File.exists and File.urls.size >< 0
    then 'normal'
    else 'disabled'
| $base <= dlg: mtx
  | -MarginW   -MarginH | $world.main.img{ui_scroll}
  | 130  10 | $title
  |  15  40 | $widget
  |  15 305 | LoadButton
  | 220 305 | button 'Cancel' skin/medium_small: => ($cancelCB){}
load_dlg.folder = $widget.folder
load_dlg.`=folder` V = $widget.folder <= V

type credits_roll.widget{ui text} cycle txt
| $txt <= txt medium $text

credits_roll.draw G PX PY =
| R = $txt.render
| R.draw{G PX+10 PY+$ui.height-$cycle/5}
| $cycle++

credits_roll.reset = $cycle <= 0

type player_picker.widget{name index color on_click}
  w/16 h/16 pressed over picked

player_picker.draw G PX PY =
| G.rectangle{$color 1 PX PY $w $h}
| when $picked: G.rectangle{#00FF00 0 PX PY $w $h}

player_picker.input In =
| case In
  [mice over S P] | $over <= S
  [mice left 1 P] | less $pressed: $pressed <= 1
  [mice left 0 P] | when $pressed:
                    | when $over: $on_click{}{Me}
                    | $pressed <= 0

export message_box world_props credits_roll notification_widget
       player_picker save_dlg load_dlg resource_counters
