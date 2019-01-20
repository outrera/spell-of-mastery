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
  | $ui.site.paused <= 0
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
| $ui.site.paused <= 1

main.show_message Title Text buttons/[ok,'Ok'] click/0 =
| $ui.message_box.display{Buttons Title Text Click}

main.dialog_result = DialogResult

type site_props.$base{site callback}
   base name description width height gold
| $name <= txt_input{''}
| $description <= txt_input{w/240 ''}
| $width <= txt_input{''}
| $height <= txt_input{''}
| $gold <= txt_input{'0'}
| PropFields = ['Site Name:',$name 
                'Description:',$description
                'Width:',$width
                'Height:',$height
                'Start Gold:',$gold
               ]
| MW = 44 //60
| MH = 86 //6
| $base <= dlg: mtx
  | 0  0 | $site.main.img{ui_box}
  | 205  12 | txt header 'Properties'
  |  15+MW  40+MH | layV s/8 PropFields{(txt small ?0)}
  | 100+MW  36+MH | layV PropFields{?1}
  |  15+MW 305+MH | button 'Done' skin/medium_small: => ($callback){Me}

site_props.update =
| W = $site
| $name.value <= W.name
| $description.value <= W.description
| $width.value <= "[W.w]"
| $height.value <= "[W.h]"
| $gold.value <= "[W.data.gold^~{0}]"

type notification_widget.widget{ui} site w/0 h/0
notification_widget.draw G X Y =
| Font = font medium
| C = 24
| Clock = clock
| FadeT = 5.0
| FadeA = #ff.float
| for [Expires Chars] $ui.notes.flip: when Clock < Expires:
  | Msg = "* [Chars.text]"
  | TTL = Expires-Clock
  | if TTL < FadeT
    then
      | A = max 0: @int FadeA-FadeA*(TTL/FadeT)
      | Font.draw_alpha{G 16 Y-C A Msg}
    else Font.draw{G 16 Y-C Msg}
  | C+=16

type save_dlg.$base{site start cancelCB loadCB}
  base picked title filename button widget
| $button <= button 'Save' skin/medium_small: => ($loadCB){$picked}
| $button.state <= 'normal'
| $title <= txt header 'Save'
| $filename <= txt_input{''}
| $widget <= folder_widget 320 240 $start: File =>
  | $picked <= File
  | FN = File.url.1
  | when FN<>'': $filename.value <= FN
| MW = 44
| MH = 86
| $base <= dlg: mtx
  |   0   0 | $site.main.img{ui_box}
  | 240  12 | $title
  |  15+MW  10+MH | $filename
  |  15+MW  40+MH | $widget
  |  15+MW 305+MH | $button
  | 220+MW 305+MH | button 'Cancel' skin/medium_small: => ($cancelCB){}
save_dlg.folder = $widget.folder
save_dlg.`=folder` V = $widget.folder <= V
save_dlg.render =
| $button.state <= if $filename.value<>'' then \normal else \disabled
| $base.render

type load_dlg.$base{site start cancelCB loadCB}
  filename base picked title widget
| LoadButton = button 'Load' skin/medium_small: => ($loadCB){$picked}
| LoadButton.state <= 'disabled'
| $title <= txt header 'Load'
| $widget <= folder_widget 320 240 $start: File =>
  | $picked <= File
  | LoadButton.state <= if File.exists and File.urls.size >< 0
    then 'normal'
    else 'disabled'
| MW = 44
| MH = 86
| $base <= dlg: mtx
  |   0   0| $site.main.img{ui_box}
  | 240  12 | $title
  |  15+MW  10+MH | $widget
  |  15+MW 305+MH | LoadButton
  | 220+MW 305+MH | button 'Cancel' skin/medium_small: => ($cancelCB){}
load_dlg.folder = $widget.folder
load_dlg.`=folder` V = $widget.folder <= V

type invnt_dlg.$base{main infoCB backCB}
  unit wearSlots bagSlots groundSlots
  filename base picked widget
| $startup_init

type credits_roll.widget{ui text} cycle txt
| $txt <= txt titleb $text
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

export message_box site_props credits_roll notification_widget
       player_picker save_dlg load_dlg invnt_dlg
