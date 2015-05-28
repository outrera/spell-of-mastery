use gui widgets

MessageBox = No
MessageBoxTitle = No
MessageBoxText = No
MessageBoxOk = No
MessageBoxWidth = 1
Main = No

message_box M =
| Main <= M
| BG = Main.img{ui_panel5}
| MessageBoxWidth <= BG.w
| MessageBoxTitle <= txt medium '' 
| MessageBoxText <= txt medium ''
| MessageBoxOk <= hidden: button 'Ok' skin/medium_small: =>
  | Main.unpause
  | MessageBox.show <= 0
| MessageBox <= hidden: dlg: mtx
  | 270 100 | BG
  | 290 110 | MessageBoxTitle
  | 280 140 | MessageBoxText
  | 390 420 | MessageBoxOk
main.show_message Title Text =
| MessageBoxTitle.value <= Title
| MessageBoxText.value <= MessageBoxText.font.format{MessageBoxWidth Text}
| MessageBoxOk.show <= 1
| MessageBox.show <= 1
| Main.pause

type unit_panel.widget{main}
     w/0 h/0 unit laurels moved
     power_icon health_icon attack_icon defense_icon
| $laurels <= $main.img{ui_laurels}
| $moved <= $main.img{ui_unit_moved}
| $power_icon <= $main.img{stats_power}
| $health_icon <= $main.img{stats_health}
| $attack_icon <= $main.img{stats_attack}
| $defense_icon <= $main.img{stats_defense}
unit_panel.set_unit Unit =
| $unit <= Unit
| if $unit
  then | $w <= $laurels.w
       | $h <= $laurels.h
  else | $w <= 0
       | $h <= 0

unit_panel.draw G P =
| less $unit: leave
| IconXY = P+[18 16]
| Icon = $unit.main.sprites."icons_[$unit.icon or $unit.type]"
| when got Icon: G.blit{IconXY Icon.frames.0}
| G.blit{P+[8 8] $laurels}
| X = P.0+4
| Y = P.1+$laurels.h+16
| Font = font medium
| Font.draw{G P+[85 10] "[$unit.title or $unit.class_name.title]"}
| Font.draw{G P+[85 48] "[$unit.owner.name]"}
| Health = max 0 $unit.health-$unit.hits
| times I Health: G.blit{[X+I*8 Y] $health_icon}
| times I $unit.level: G.blit{[X+I*8 Y+16] $power_icon}
| times I $unit.attack: G.blit{[X+I*8 Y+32] $attack_icon}
| times I $unit.defense: G.blit{[X+I*8 Y+48] $defense_icon}
| Moved = $unit.moved-$unit.world.turn+1
| when Moved > 0: times I Moved: G.blit{[X+I*8 Y+64] $moved}

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
| $base <= dlg: mtx
  |   0   0 | $world.main.img{ui_panel5}
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


type info_line.widget{main} info_text/txt{small ''}

info_line.render =
| $info_text.value <= ""
| case Main.act_icons.keep{(?.show and ?.over)} [Icon@_]
  | Act = $main.params.acts.(Icon.data)
  | Info =  if got Act.title then Act.title else Act.type.replace{_ ' '}
  | when got Icon.number: Info <= "research [Info] ([Icon.number] TURNS)"
  | less got Icon.number:
    | Cost = if got Act.cost then Act.cost else 0
    | Info <= "[Info] ([Act.cost] MANA)"
  | $info_text.value <= Info.upcase
| $info_text.render

type load_world_dlg.$base{world folder cancelCB loadCB}
  filename base picked
| LoadButton = button 'Load' skin/medium_small: => ($loadCB){$picked}
| LoadButton.state <= 'disabled'
| $base <= dlg: mtx
  |   0   0 | $world.main.img{ui_panel5}
  | 130  10 | txt medium 'Load World'
  |  15  40 | folder_widget $folder: File =>
              | $picked <= File
              | LoadButton.state <= if File.exists and File.urls.size >< 0
                then 'normal'
                else 'disabled'
  |  15 305 | LoadButton
  | 220 305 | button 'Cancel' skin/medium_small: => ($cancelCB){}

export message_box unit_panel world_props info_line load_world_dlg