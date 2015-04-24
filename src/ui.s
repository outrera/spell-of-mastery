use gui widgets view icon

ScreenW = No
ScreenH = No

MessageBox = No
MessageBoxTitle = No
MessageBoxText = No
MessageBoxOk = No

init_message_box Main =
| MessageBoxTitle <= txt medium '' 
| MessageBoxText <= txt medium ''
| MessageBoxOk <= hidden: button 'Ok' skin/medium_small: =>
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
| Save = button 'Save' skin/medium_small state/disabled (=>)
| Load = button 'Load' skin/medium_small state/disabled (=>)
| hidden: dlg: mtx
  |   0   0 | spacer ScreenW ScreenH
  | 270 100 | Main.img{ui_panel1}
  | 346 110 | txt medium 'Game Menu'
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


MaxActIcons = 24
ActIcons = []
ActIcon = 0

type info_line.widget{main} info_text/txt{small ''}

info_line.render =
| $info_text.value <= ""
| case ActIcons.keep{(?.show and ?.over)} [Icon@_]
  | Act = $main.params.acts.(Icon.data)
  | Info = Act.type.replace{_ ' '}
  | when got Icon.number: Info <= "research [Info] ([Icon.number] moves)"
  | less got Icon.number:
    | Cost = if got Act.cost then Act.cost else 0
    | Info <= "[Info] ([Act.cost] moves)"
  | $info_text.value <= Info.upcase
| $info_text.render

unit_panel.draw G P =
| less $unit: leave
| ClassName = $unit.class_name
| IconXY = P+[18 16]
| Icon = $unit.main.sprites."icons_unit_[ClassName]"
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


MapsFolder = 'work/worlds/'
SavesFolder = 'work/saves/'

// FIXME: refactor following into UI type
main.run =
| ScreenW <= $params.ui.width
| ScreenH <= $params.ui.height
| set_main Me
| init_message_box Me
| MapsFolder = "[$data][MapsFolder]"
| SavesFolder = "[$data][SavesFolder]"
| PanelW = 200
| View = view Me ScreenW ScreenH
| Tabs = No
| Ingame = No
| ScenarioMenu = No
| MainMenu = No
| PauseSpacer = hidden: spacer ScreenW ScreenH
| pause = | PauseSpacer.show <= 1; View.pause
| unpause = | PauseSpacer.show <= 0; View.unpause
| InfoText = info_line Me
| WorldProperties = No
| parse_int_normalized Default Text =
  | if Text.size>0 and Text.all{?is_digit} then Text.int else Default
| WorldProperties <= hidden: world_props $world: P =>
  | W = parse_int_normalized{$world.w P.width.value}.clip{4 240}
  | H = parse_int_normalized{$world.h P.height.value}.clip{4 240}
  | when W <> $world.w or H <> $world.h:
    | $world.create{W H}
  | $world.filename <= P.filename.value
  | $world.name <= P.name.value
  | $world.description <= P.description.value
  | unpause
  | WorldProperties.show <= 0
| LoadWorldDlg = No
| hideLoadWorldDlg = 
  | LoadWorldDlg.show <= 0
  | unpause
| LoadWorldDlgW = load_world_dlg $world MapsFolder &hideLoadWorldDlg: X =>
  | $load{X}
  | hideLoadWorldDlg
| LoadWorldDlgW.folder <= MapsFolder
| LoadWorldDlg <= hidden: LoadWorldDlgW
| PlayerWidget = droplist $world.players{}{?name} w/110 f: Name =>
  | when got!it $world.players.find{?name >< Name}: $world.player <= it
| $world.on_player_change <= Player =>
  | PlayerWidget.picked <= Player.id
| $world.on_update <= =>
  | when got $world.params.winner
    | pause
    | sound_play: sound_load "[$data]/music/victory.ogg" music/1
    | Tabs.pick{victory}
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
| PickedUnitTitle = txt medium ''
| PickedUnitOwner = txt medium 'unknown'
| PickedUnitLevel = txt medium 'unknown'
| PickedUnitMoved = txt medium 'unknown'
| UnitPanel = unit_panel Me
| GameUnitUI = hidden: dlg: mtx
  |  0   0| UnitPanel
| EndTurnIcon = hidden: icon $img{"icons_hourglass"} click/(Icon => $world.end_turn)
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
    | Icon.frame <= 0
    | Icon.w <= Icon.fg.w
    | Icon.h <= Icon.fg.h
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
  | when Mode >< play: $world.new_game
| BrushIcon = icon data/brush $img{icons_brush} click/EditorModeIconClick
| PlayIcon = icon data/play $img{icons_play} click/EditorModeIconClick
| WorldIcon = icon data/pick $img{icons_world} click: Icon =>
  | pause
  | WorldProperties.show <= 1
  | WorldProperties.update
| SaveIcon = icon data/pick $img{icons_save} click: Icon =>
  | $save{"[MapsFolder][$world.filename].txt"}
  //| show_message 'Saved' 'Your map is saved!'
| LoadIcon = icon data/pick $img{icons_load} click: Icon =>
  | pause
  | LoadWorldDlg.show <= 1 
  //| $load{"[MapsFolder][$world.filename].txt"}
| ExitIcon = icon data/pick $img{icons_exit} click: Icon =>
  | pause
  | Tabs.pick{main_menu}
| EditorIcons = hidden: layV s/8
    BrushIcon,spacer{8 0},PlayIcon,spacer{8 0},WorldIcon,
    spacer{8 0},SaveIcon,LoadIcon,spacer{8 0},ExitIcon
| ModeIcon <= BrushIcon
| BrushIcon.picked <= 1
| GearsIcon = hidden: button 'GEARS' skin/gears: =>
  | pause
  | Tabs.pick{game_menu}
| HourglassIcon = hidden: button 'HOURGLASS' skin/hourglass: => $world.end_turn
| Ingame <= dlg w/ScreenW h/ScreenH: mtx
  |  0   0| spacer ScreenW ScreenH
  |  0   0| ViewUI
  |  ScreenW-54 4| EditorIcons
  |  ScreenW-111 0| GearsIcon
  |  ScreenW-73 110| HourglassIcon
  |  0   0| PauseSpacer
  |170 100| WorldProperties
  |170 100| LoadWorldDlg
  |  0   0| MessageBox
| View.init
| begin_ingame Editor = 
  | EditorIcons.show <= Editor
  | EndTurnIcon.show <= Editor
  | GearsIcon.show <= not Editor
  | HourglassIcon.show <= not Editor
  | View.mode <= [play brush].Editor
| MenuBG = $img{ui_menu_bg}
| X = ScreenW/2 - 162
| load NewGame Path =
  | begin_ingame 0
  | $load{Path}
  | ViewUI.pick{play}
  | when NewGame: $world.new_game
  | unpause
  | Tabs.pick{ingame}
| save_slot Name = 
  | $save{"[SavesFolder][Name].txt"}
  | unpause
  | Tabs.pick{ingame}
  //| show_message 'Saved' 'Your game is saved!'
| load_slot Name = 
  | load 0 "[SavesFolder][Name].txt"
  //| show_message 'Saved' 'Your game is loaded!'
| new_load_button N = button "SLOT [N.upcase]" skin/scroll: => load_slot N
| LoadButtons = @table: map N [a b c d]: N,(hidden: new_load_button N)
| CopyrightLine = 'SymtaEngine v0.1; Copyright (c) 2015 Nikita Sadkov'
| MainMenu <= dlg: mtx
  |   0   0 | MenuBG
  |  16 ScreenH-16 | txt small CopyrightLine
  | X 220 | button 'NEW GAME' skin/scroll: => load 1 "[MapsFolder]default.txt"
  | X 290 | button 'LOAD GAME' skin/scroll: =>
            | for N,B LoadButtons: B.show <= "[SavesFolder][N].txt".exists
            | Tabs.pick{load_menu}
  | X 360 | button 'WORLD EDITOR' skin/scroll: =>
            | $world.create{8 8}
            | begin_ingame 1
            | unpause
            | Tabs.pick{ingame}
  | X 500 | button 'EXIT' skin/scroll: => get_gui{}.exit
| GameMenu = dlg: mtx
  |   0   0 | MenuBG
  |  16 ScreenH-16 | txt small CopyrightLine
  | X 290 | button 'SAVE GAME' skin/scroll: => Tabs.pick{save_menu}
  | X 360 | button 'RESUME GAME' skin/scroll: =>
            | unpause
            | Tabs.pick{ingame}
  | X 500 | button 'EXIT TO MENU' skin/scroll: => Tabs.pick{main_menu}
| VictoryBG = $img{ui_victory_bg}
| Victory = dlg: mtx
  |   0   0 | VictoryBG
  | 100 100 | txt medium: =>
              | Player = $world.players.($world.params.winner)
              | Type = $world.params.victory_type.replace{_ ' '}
              | "[Player.name] has won by [Type]!"
  | ScreenW-360 ScreenH-100
        | button 'EXIT TO MENU' skin/scroll: =>
          | Tabs.pick{main_menu}
| SaveMenu = dlg: mtx
  |   0   0 | MenuBG
  |  16 ScreenH-16 | txt small CopyrightLine
  | X 200 | button 'SLOT A' skin/scroll: => save_slot a
  | X 270 | button 'SLOT B' skin/scroll: => save_slot b
  | X 340 | button 'SLOT C' skin/scroll: => save_slot c
  | X 410 | button 'SLOT D' skin/scroll: => save_slot d
  | X 500 | button 'CANCEL' skin/scroll: =>
            | unpause
            | Tabs.pick{ingame}
| LoadMenu = dlg: mtx
  |   0   0 | MenuBG
  |  16 ScreenH-16 | txt small CopyrightLine
  | X 200 | LoadButtons.a
  | X 270 | LoadButtons.b
  | X 340 | LoadButtons.c
  | X 410 | LoadButtons.d
  | X 500 | button 'CANCEL' skin/scroll: =>
            | Tabs.pick{main_menu}
| Tabs <= tabs ingame: t
          main_menu(MainMenu)
          game_menu(GameMenu)
          save_menu(SaveMenu)
          load_menu(LoadMenu)
          ingame(Ingame)
          victory(Victory)
          scenario(ScenarioMenu)
| BankList.pick{0}
| begin_ingame 1
//| pause
| gui Tabs cursor/$img{ui_cursor_point}
