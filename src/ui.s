use gui widgets view icon

ScreenW = No
ScreenH = No

MessageBox = No
MessageBoxTitle = No
MessageBoxText = No
MessageBoxOk = No

init_message_box Main =
| MessageBoxTitle <= txt size/medium '' 
| MessageBoxText <= txt size/medium ''
| MessageBoxOk <= hidden: button 'Ok' w_size/small: =>
  | MessageBox.show <= 0
| MessageBox <= hidden: dlg: mtx
  |   0   0 | spacer ScreenW ScreenH
  | 270 100 | Main.img{ui_panel2}
  | 400 110 | MessageBoxTitle
  | 285 140 | MessageBoxText
  | 360 320 | MessageBoxOk
show_message Title Text =
| MessageBoxTitle.value <= Title
| MessageBoxText.value <= Text
| MessageBoxOk.show <= 1
| MessageBox.show <= 1


/*
GameMenu <=
| Save = button 'Save' w_size/small state/disabled (=>)
| Load = button 'Load' w_size/small state/disabled (=>)
| hidden: dlg: mtx
  |   0   0 | spacer ScreenW ScreenH
  | 270 100 | Main.img{ui_panel1}
  | 346 110 | txt size/medium 'Game Menu'
  | 285 140 | layV s/8: list
              layH{s/12 [Save Load]}
              button{'Options' state/disabled (=>)}
              button{'Objectives' state/disabled (=>)}
              (button 'Abandon Game': =>
                | View.pause
                | GameMenu.show <= 0
                | Tabs.pick{main_menu})
              spacer{1 20}
              (button 'Return to Game': =>
                 | View.unpause
                 | GameMenu.show <= 0)
*/


type unit_panel.widget{main}
     w/0 h/0 unit icon_bg laurels moved
     power_icon health_icon attack_icon defense_icon
| $icon_bg <= $main.img{unit_icon_bg}
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


MaxActIcons = 24
ActIcons = []
ActIcon = 0

type info_line.widget{main} info_text/txt{""}

info_line.render =
| $info_text.value <= ""
| case ActIcons.keep{(?.show and ?.over)} [Icon@_]
  | Act = $main.params.acts.(Icon.data)
  | Info = Act.type.replace{_ ' '}
  | when got Icon.number: Info <= "research [Info] ([Icon.number] points left)"
  | $info_text.value <= Info.upcase
| $info_text.render

unit_panel.draw G P =
| less $unit: leave
| ClassName = $unit.class_name
| IconXY = P+[12 4]
| Icon = $unit.main.sprites."unit_icon_[ClassName]"
//| G.blit{IconXY $icon_bg}
| when got Icon: G.blit{IconXY Icon.frames.0}
| G.blit{P+[8 8] $laurels}
| when $unit.moved >< $unit.world.turn: G.blit{P+[34 54] $moved}
| Font = font medium
| Font.draw{G P+[85 10] "[ClassName.title]"}
| Font.draw{G P+[85 48] "[$unit.owner.name]"}
| X = P.0+4
| Y = P.1+$laurels.h+16
| Health = max 0 $unit.health-$unit.hits
| times I Health: G.blit{[X+I*8 Y] $health_icon}
| times I $unit.level: G.blit{[X+I*8 Y+16] $power_icon}
| times I $unit.attack: G.blit{[X+I*8 Y+32] $attack_icon}
| times I $unit.defense: G.blit{[X+I*8 Y+48] $defense_icon}


// FIXME: refactor following into UI type
main.run =
| ScreenW <= $params.ui.width
| ScreenH <= $params.ui.height
| set_main Me
| init_message_box Me
| PanelW = 200
| View = view Me ScreenW ScreenH
| Tabs = No
| GameMenu = No
| WorldProperties = No
| Ingame = No
| ScenarioMenu = No
| MainMenu = No
| PauseSpacer = hidden: spacer ScreenW ScreenH
| pause = | PauseSpacer.show <= 1; View.pause
| unpause = | PauseSpacer.show <= 0; View.unpause
| InfoText = info_line Me
| WorldNameInput = txt_input{''}
| PropFields = ['World Name:',WorldNameInput
               ]
| WorldProperties <= hidden: dlg: mtx
  |   0   0 | $img{ui_panel5}
  | 130  10 | txt size/medium 'Properties'
  |  15  40 | layV PropFields{?0^txt}
  | 100  36 | layV PropFields{?1}
  |  15 305 | button 'Done' skin/medium_small: =>
              | unpause
              | WorldProperties.show <= 0
| PlayerWidget = droplist $world.players{}{?name} w/110 f: Name =>
  | when got!it $world.players.find{?name >< Name}: $world.player <= it
| $world.on_player_change <= Player =>
  | PlayerWidget.picked <= Player.id
| BankName =
| TileNames = $tiles{}{?0}.skip{$aux_tiles.?^got}.sort
| BankNames = [terrain unit @$bank_names.skip{unit}]
| ItemList = litems w/(PanelW-80) lines/40 [] f: N =>
  | Brush = if BankName >< terrain
            then [tile N]
            else [obj BankName,N]
  | View.set_brush{Brush}
| BankList = litems w/80 lines/40 BankNames f: N =>
  | BankName <= N
  | if BankName >< terrain
    then | ItemList.data <= TileNames
         | ItemList.pick{TileNames.locate{plain}}
    else | ItemList.data <= $classes_banks.BankName
         | ItemList.pick{0}
| BrushUI = dlg: mtx
  | 0 0 | View
  | 0 0 | layH: BankList,ItemList
  | PanelW 0 | PlayerWidget
| PickedUnit = 0
//| sound_play: sound_load "[$data]/music/thaxted.ogg" music/1
| ActClick = Icon =>
  | $sound{ui_click}
  | when ActIcon: ActIcon.picked <= 0
  | Icon.picked <= 1
  | ActIcon <= Icon
  | Act = $params.acts.(Icon.data)
  | when got Icon.number:
    | PickedUnit.owner.researching <= Act.type
  | when no Icon.number:
    | Target = Act.target
    | when Target >< self or Target >< pentagram:
      | Order = PickedUnit.order.init{@Act.list.join}
| ActIcons <= map I MaxActIcons: hidden: icon 0 click/ActClick
| for K,V $params.acts: V.icon_gfx <= $img{"icons_[V.icon]"}
| ArrowClick = Icon =>
| Arrows = 9{I=>icon data/I $img{"icons_arrow[I]"} click/ArrowClick}
| PickedUnitTitle = txt size/medium ''
| PickedUnitOwner = txt size/medium 'unknown'
| PickedUnitLevel = txt size/medium 'unknown'
| PickedUnitMoved = txt size/medium 'unknown'
| UnitPanel = unit_panel Me
| GameUnitUI = hidden: dlg: mtx
  |  0   0| UnitPanel
| EndTurnIcon = icon $img{"icons_hourglass"} click/(Icon => $world.end_turn)
| GameUI = dlg: mtx
  |  0   0| View
  |  0   0| GameUnitUI
  |  4 ScreenH-100| layH{s/4 ActIcons.drop{ActIcons.size/2}}
  |  4 ScreenH-56 | layH{s/4 ActIcons.take{ActIcons.size/2}}
  |  4 ScreenH-10 | InfoText
  | ScreenW-54 ScreenH-64 | EndTurnIcon
| ViewUI = tabs brush: t
           brush(BrushUI)
           play(GameUI)
| View.on_unit_pick <= Unit =>
  | PickedUnit <= Unit
  | NonNil = Unit.type <> unit_nil
  | GameUnitUI.show <= NonNil
  | for Icon ActIcons: Icon.show <= 0
  | for I,Act Unit.acts.i.take{min{MaxActIcons Unit.acts.size}}
    | Active = 1
    | when Act.act >< summon and not Unit.owner.pentagram:
      | Active <= 0
    | Icon = ActIcons.I.widget
    | Player = Unit.owner
    | ResearchSpent = Player.research.(Act.type)
    | ResearchRemain = Act.research - ResearchSpent
    | Icon.data <= Act.type
    | Icon.fg <= Act.icon_gfx
    | Icon.number <= if ResearchRemain > 0 then ResearchRemain else No
    | Icon.research <= Unit.owner.researching >< Act.type
                       and ResearchRemain > 0
    | ActIcons.I.show <= Active
  | UnitPanel.set_unit{Unit}
| ModeIcon = No
| EditorModeIconClick = Icon =>
  | ModeIcon.picked <= 0
  | Icon.picked <= 1
  | ModeIcon <= Icon
  | Mode = Icon.data
  | View.mode <= Mode
  | ViewUI.pick{Mode}
  | when Mode >< play: $world.init_game
| BrushIcon = icon data/brush $img{icons_brush} click/EditorModeIconClick
| PlayIcon = icon data/play $img{icons_play} click/EditorModeIconClick
| WorldIcon = icon data/pick $img{icons_world} click: Icon =>
  | pause
  | WorldProperties.show <= 1
| SaveIcon = icon data/pick $img{icons_save} click: Icon =>
  | $save{"[$data]/work/worlds/test.txt"}
  //| show_message 'Saved' 'Your map is saved!'
| LoadIcon = icon data/pick $img{icons_load} click: Icon =>
  | $load{"[$data]/work/worlds/test.txt"}
| ExitIcon = icon data/pick $img{icons_exit} click: Icon =>
  | pause
  | Tabs.pick{main_menu}
| Icons = BrushIcon,spacer{8 0},PlayIcon,spacer{8 0},WorldIcon,
          spacer{8 0},SaveIcon,LoadIcon,spacer{8 0},ExitIcon
| ModeIcon <= BrushIcon
| BrushIcon.picked <= 1
| Ingame <= dlg w/ScreenW h/ScreenH: mtx
  |  0   0| spacer ScreenW ScreenH
  |  0   0| ViewUI
  |  ScreenW-54 4| layV s/8 Icons
  |  0   0| PauseSpacer
  |170 100| WorldProperties
  |  0   0| MessageBox
| View.init
| MenuBG = $img{ui_menu_bg}
| X = ScreenW/2 - 162
| MMButtons = layV s/8: list
    button{'Campaign'       state/disabled (=>)}
    button{'Scenario'       state/disabled (=>Tabs.pick{scenario})}
    button{'Multi Player'   state/disabled (=>)}
    button{'Load Game'      state/disabled (=>)}
    button{'World Editor'   (=> | View.mode <= \brush
                                | unpause
                                | Tabs.pick{ingame})}
    spacer{0 8}
    button{'Exit Program'   (=>get_gui{}.exit)}
| MainMenu <= dlg: mtx
  |   0   0 | MenuBG
  |  16 ScreenH-16 | txt 'SymtaEngine v0.1; Copyright (c) 2015 Nikita Sadkov'
//  | X 240 | MMButtons
  | X 220 | button{'   NEW GAME' skin/scroll (=>)}
  | X 290 | button{'   LOAD GAME' skin/scroll (=>)}
  | X 360 | button{'   WORLD EDITOR' skin/scroll (=> | View.mode <= \brush
                                                     | unpause
                                                     | Tabs.pick{ingame})}
  | X 500 | button{'   EXIT' skin/scroll (=>get_gui{}.exit)}
| Tabs <= tabs ingame: t
          main_menu(MainMenu)
          ingame(Ingame)
          scenario(ScenarioMenu)
| BankList.pick{0}
| View.mode <= \brush
//| pause
| gui Tabs cursor/$img{ui_cursor_point}
