use gui widgets icon

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
  | 280 140 | $text
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

type unit_panel.widget{ui}
     w/0 h/0 unit laurels moved
     power_icon health_icon attack_icon defense_icon
| $laurels <= $ui.img{ui_laurels}
| $moved <= $ui.img{ui_unit_moved}
| $power_icon <= $ui.img{stats_power}
| $health_icon <= $ui.img{stats_health}
| $attack_icon <= $ui.img{stats_attack}
| $defense_icon <= $ui.img{stats_defense}
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
  | Act = $ui.params.acts.(Icon.data)
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


type research_icon.$base{ui OnClick} base text icon world acts
| Icon = icon data/research 0 click/OnClick
| Icon.fg <= 0 //$ui.img{icons_unit_orc}
| Icon.frame <= 0
| Icon.research <= 1
| $world <= $ui.main.world
| $acts <= $ui.main.params.acts
| $icon <= Icon
| $text <= txt medium "Researching: "
| $base <= hidden: layH s/4 (layV spacer{1 8},$text),Icon

research_icon.render =
| Player = $world.player
| $base.show <= 0
| Researching = Player.researching
| when Researching and Player.human:
  | $base.show <= 1
  | Icon = $icon
  | Act = $acts.Researching
  | Icon.fg <= $ui.img{"icons_[Act.icon]"}
  | Icon.number <= Player.research_remain{Act}
| $base.render

export message_box unit_panel world_props info_line load_world_dlg research_icon