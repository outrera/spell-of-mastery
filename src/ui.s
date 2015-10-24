use gui widgets view ui_icon ui_widgets macros

ScreenW = No
ScreenH = No

MapsFolder = 'work/worlds/'
SavesFolder = 'work/saves/'

MaxActIcons = 24
ActIcons = []
ActIcon = 0

Pause =
Unpause =


type ui.$base{main} base width height world message_box view
| $world <= $main.world
| $width <= $params.ui.width
| $height <= $params.ui.height
| ScreenW <= $width
| ScreenH <= $height

ui.data = $main.data
ui.load File =
| $main.load{File}
| $view.clear
ui.save File = $main.save{File}
ui.params = $main.params
ui.act_icons = ActIcons
ui.pause = Pause{}
ui.unpause = Unpause{}
ui.img File = $main.img{File}
ui.create W H =
| $world.create{W H}
| $view.clear

research_act Me Unit Act =
| O = Unit.owner
| Needs = $world.player.lore-Act.research
| when Needs < 0:
  | O.notify{"Not enough lore for `[Act.title]` (collect [-Needs])"}
  | leave
| $main.show_message{'Research?' buttons/[yes,'Yes' no,'No']
                     'Are you sure want to spent lore on this?'}
| O.researching <= Act.name
| Research = $main.params.acts.research
| Unit.order.init{target Unit @Research.list.join}

ui.init =
| MapsFolder <= "[$data][MapsFolder]"
| SavesFolder <= "[$data][SavesFolder]"
| PanelW = 200
| $view <= view $main ScreenW ScreenH
//| StartTime = clock
| $create{8 8}
//| EndTime = clock
//| say EndTime-StartTime
//| halt
| $message_box <= message_box Me
| Tabs = No
| Ingame = No
| MainMenu = No
| InputBlocker = hidden: spacer ScreenW ScreenH
| pause = | InputBlocker.show <= 1; $view.pause
| unpause = | InputBlocker.show <= 0; $view.unpause
| Pause <= => pause
| Unpause <= => unpause
| InfoText = info_line Me
| WorldProperties = No
| parse_int_normalized Default Text =
  | if Text.size>0 and Text.all{?is_digit} then Text.int else Default
| WorldProperties <= hidden: world_props $world: P =>
  | W = parse_int_normalized{$world.w P.width.value}.clip{4 240}
  | H = parse_int_normalized{$world.h P.height.value}.clip{4 240}
  | when W <> $world.w or H <> $world.h: $create{W H}
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
  | $world.explore{1}
  | hideLoadWorldDlg
| LoadWorldDlgW.folder <= MapsFolder
| LoadWorldDlg <= hidden: LoadWorldDlgW
| PlayerWidget = droplist $world.players{}{?name} w/110 f: Name =>
  | when got!it $world.players.find{?name >< Name}: $world.player <= it
| $world.on_player_change <= Player =>
  | PlayerWidget.picked <= Player.id
| $world.on_update <= =>
  | when $world.player.human: InputBlocker.show <= 0
  | Winner = $world.params.winner
  | when got Winner:
    | NextWorld = $world.params.next_world
    | less got NextWorld:
      | pause
      | if $world.players.Winner.human
        then | $main.music{"victory.ogg"}
             | Tabs.pick{victory}
        else | $main.music{"defeat.ogg"}
             | Tabs.pick{defeat}
    | when got NextWorld:
      | $load{"[MapsFolder][NextWorld].txt"}
      | $world.new_game
| TileBanks = $main.params.world.tile_banks
| BankName =
| BankNames = [@TileBanks unit leader @$main.bank_names.skip{unit}.skip{leader}]
| ItemList = litems w/(PanelW-80) lines/40 [] f: N =>
  | Brush = if got TileBanks.find{BankName}
            then [tile N]
            else [obj BankName,N]
  | $view.set_brush{Brush}
| BankList = litems w/80 lines/40 BankNames f: N =>
  | BankName <= N
  | if got TileBanks.find{BankName}
    then | ItemList.data <= $main.tile_names{BankName}
         | ItemList.pick{0}
         //| ItemList.pick{TileNames.locate{plain}}
    else | ItemList.data <= $main.classes_banks.BankName
         | ItemList.pick{0}
| PickedUnit = 0
| ActClick = Icon =>
  | $world.act <= 0
  | $main.sound{ui_click}
  | when ActIcon: ActIcon.picked <= 0
  | Icon.picked <= 1
  | ActIcon <= Icon
  | Act = $params.acts.(Icon.data)
  | Remain = Icon.number
  | less got Remain: Remain <= 0
  | O = PickedUnit.owner
  | if Remain > 0 then
      | research_act Me PickedUnit Act
    else if Remain < 0 then
      | O.notify{"[Act.title] needs [-Remain] turns to recharge."}
    else | if Act.range >< 0
           then when O.id >< $world.player.id:
                | PickedUnit.order.init{target PickedUnit @Act.list.join}
           else $world.act <= Act
| ActIcons <= map I MaxActIcons: hidden: icon 0 click/ActClick
| for K,V $params.acts: V.icon_gfx <= $img{"icons_[V.icon]"}
| PickedUnitTitle = txt medium ''
| PickedUnitOwner = txt medium 'unknown'
| PickedUnitLevel = txt medium 'unknown'
| PickedUnitMoved = txt medium 'unknown'
| UnitPanel = unit_panel Me
| GameUnitUI = hidden: dlg: mtx
  |  0   0| UnitPanel
| EndTurnIcon = hidden: icon $img{"icons_hourglass"} click/(Icon => $world.end_turn)
| GameUI = dlg: mtx
  |  0   0| $view
  |  0   0| GameUnitUI
  |  4 ScreenH-100| layH{s/4 ActIcons.drop{ActIcons.size/2}}
  |  4 ScreenH-56 | layH{s/4 ActIcons.take{ActIcons.size/2}}
  |  4 ScreenH-10 | InfoText
  | ScreenW-54 ScreenH-64 | EndTurnIcon
| BrushUI = dlg: mtx
  | 0 0 | $view
  | 0 0 | layH: BankList,ItemList
  | PanelW 0 | PlayerWidget
| PickUI = GameUI
| ViewUI = tabs brush: t brush(BrushUI) pick(PickUI) play(GameUI)
| $view.on_unit_pick <= Unit =>
  | PickedUnit <= Unit
  | NonNil = Unit.type <> unit_nil
  | GameUnitUI.show <= NonNil
  | for Icon ActIcons: Icon.show <= 0
  //| when nit.moved < $world.turn:
  | As = Unit.acts.i.take{min{MaxActIcons Unit.acts.size}}
  | for I,Act As: when Act.enabled^get_bit{Unit.owner.id}:
    | Active = 1
    | when Act.act >< summon and not Unit.owner.pentagram:
      | Active <= 0
    | Icon = ActIcons.I.widget
    | Player = Unit.owner
    | ResearchRemain = Player.research_remain{Act}
    | Icon.data <= Act.name
    | Icon.fg <= Act.icon_gfx
    | Icon.number <= if ResearchRemain <> 0 then ResearchRemain else No
    | Icon.research <= ResearchRemain <> 0
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
  | $view.mode <= Mode
  | EndTurnIcon.show <= Mode >< play
  | ViewUI.pick{Mode}
  | if Mode >< play then $world.new_game else $world.explore{1}
| BrushIcon = icon data/brush $img{icons_brush} click/EditorModeIconClick
| PickIcon = icon data/pick $img{icons_pick} click/EditorModeIconClick
| PlayIcon = icon data/play $img{icons_play} click/EditorModeIconClick
| WorldIcon = icon $img{icons_world} click: Icon =>
  | pause
  | WorldProperties.show <= 1
  | WorldProperties.update
| SaveIcon = icon data/pick $img{icons_save} click: Icon =>
  | $save{"[MapsFolder][$world.filename].txt"}
  //| $main.show_message{'Saved' 'Your map is saved!'}
| LoadIcon = icon data/pick $img{icons_load} click: Icon =>
  | pause
  | LoadWorldDlg.show <= 1 
  //| $load{"[MapsFolder][$world.filename].txt"}
| play_title_music = $main.music{"title.ogg"}
| pick_main_menu pause/1 =
  | when Pause: pause
  | play_title_music
  | Tabs.pick{main_menu}
| ExitIcon = icon data/pick $img{icons_exit} click: Icon => pick_main_menu
| EditorIcons = hidden: layV s/8
    BrushIcon,spacer{8 0},PickIcon,spacer{8 0},PlayIcon,spacer{8 0},
    WorldIcon,spacer{8 0},SaveIcon,LoadIcon,spacer{8 0},ExitIcon
| ModeIcon <= BrushIcon
| BrushIcon.picked <= 1
| GearsIcon = hidden: button 'GEARS' skin/gears: =>
  | pause
  | Tabs.pick{game_menu}
| HourglassIcon = hidden: button 'HOURGLASS' skin/hourglass: =>
  | InputBlocker.show <= 1
  | $world.end_turn
| Ingame <= dlg w/ScreenW h/ScreenH: mtx
  |  0   0| spacer ScreenW ScreenH
  |  0   0| ViewUI
  |  ScreenW-54 4| EditorIcons
  |  ScreenW-111 0| GearsIcon
  |  ScreenW-73 110| HourglassIcon
  |  0   0| InputBlocker
  |170 100| WorldProperties
  |170 100| LoadWorldDlg
  |  0   0| $message_box
| begin_ingame Editor =
  | less Editor: $main.music{playlist}
  | EditorIcons.show <= Editor
  | EndTurnIcon.show <= Editor
  | GearsIcon.show <= not Editor
  | HourglassIcon.show <= not Editor
  | $view.mode <= [play brush].Editor
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
  //| $main.show_message{'Saved' 'Your game is saved!'}
| load_slot Name = 
  | load 0 "[SavesFolder][Name].txt"
  //| $main.show_message{'Loaded' 'Your game is loaded!'}
| new_load_button N = button "SLOT [N.upcase]" skin/scroll: => load_slot N
| LoadButtons = @table: map N [a b c d]: N,(hidden: new_load_button N)
| CopyrightLine = 'SymtaEngine v0.2; Copyright (c) 2015 Nikita Sadkov'
| CreditsRoll = credits_roll Me $main.credits
| ScenarioMenu = No
| loadScenarioBack = Tabs.pick{new_game_menu}
| LoadScenarioDlg = load_world_dlg $world MapsFolder &loadScenarioBack: X =>
  | load 1 X
| LoadScenarioDlg.folder <= MapsFolder
| ScenarioMenu <= dlg: mtx
  |   0   0 | MenuBG
  |  220 200 | LoadScenarioDlg
  |  16 ScreenH-16 | txt small CopyrightLine
| NewGameMenu = No
| NewGameMenu <= dlg: mtx
  |   0   0 | MenuBG
  |  16 ScreenH-16 | txt small CopyrightLine
  | X 220 | button 'CAMPAIGN' skin/scroll: => load 1 "[MapsFolder]level0.txt"
  | X 290 | button 'SCENARIO' skin/scroll:  => Tabs.pick{scenario_menu}
  | X 360 | button 'MULTIPLAYER' skin/scroll: => 
  | X 500 | button 'BACK' skin/scroll: => Tabs.pick{main_menu}
| MainMenu <= dlg: mtx
  |   0   0 | MenuBG
  |  16 ScreenH-16 | txt small CopyrightLine
  | X 220 | button 'NEW GAME' skin/scroll: => Tabs.pick{new_game_menu}
  | X 290 | button 'LOAD GAME' skin/scroll: =>
            | for N,B LoadButtons: B.show <= "[SavesFolder][N].txt".exists
            | Tabs.pick{load_menu}
  | X 360 | button 'WORLD EDITOR' skin/scroll: =>
            | $create{8 8}
            | begin_ingame 1
            | unpause
            | Tabs.pick{ingame}
  | X 500 | button 'EXIT' skin/scroll: => get_gui{}.exit
  |  ScreenW-80 ScreenH-20
     | button 'Credits' skin/small_medium: =>
       | $main.music{"credits.ogg"}
       | CreditsRoll.reset
       | Tabs.pick{credits}
| GameMenu = dlg: mtx
  |   0   0 | MenuBG
  |  16 ScreenH-16 | txt small CopyrightLine
  | X 290 | button 'SAVE GAME' skin/scroll: => Tabs.pick{save_menu}
  | X 360 | button 'RESUME GAME' skin/scroll: =>
            | unpause
            | Tabs.pick{ingame}
  | X 500 | button 'EXIT TO MENU' skin/scroll: => pick_main_menu pause/0
| VictoryBG = $img{ui_victory_bg}
| Victory = dlg: mtx
  |   0   0 | VictoryBG
  | 100 100 | txt medium: =>
              | Player = $world.players.($world.params.winner)
              | Type = $world.params.victory_type.replace{_ ' '}
              | "[Player.name] has won!\n[Type]"
  | ScreenW-360 ScreenH-100
        | button 'EXIT TO MENU' skin/scroll: => pick_main_menu pause/0
| DefeatBG = $img{ui_defeat_bg}
| Defeat = dlg: mtx
  |   0   0 | DefeatBG
  | 140 100 | txt medium: =>
              | Player = $world.human
              | Type = $world.params.victory_type.replace{_ ' '}
              | "[Player.name] has been defeated!\n"
  | ScreenW-360 ScreenH-100
        | button 'EXIT TO MENU' skin/scroll: =>  pick_main_menu pause/0
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
  | X 500 | button 'CANCEL' skin/scroll: => Tabs.pick{main_menu}
| Ingame = input_split Ingame: Base In =>
  | Handled = 0
  | when $view.mode >< play: less $view.paused: case In [key z 0]
    | when $world.player.human: $world.end_turn
    | Handled <= 1
  | less Handled: Base.input{In}
| Credits = dlg: mtx
  |  0   0 | $img{ui_stars}
  |  0   0 | CreditsRoll
  |  ScreenW-80 ScreenH-20
     | button 'Exit' skin/small_medium: => pick_main_menu pause/0
| IsDebug = $main.params.world.release<>1
| InitTab = if IsDebug then \ingame else \main_menu
| Tabs <= tabs InitTab: t
          main_menu(MainMenu)
          new_game_menu(NewGameMenu)
          scenario_menu(ScenarioMenu)
          game_menu(GameMenu)
          save_menu(SaveMenu)
          load_menu(LoadMenu)
          ingame(Ingame)
          victory(Victory)
          defeat(Defeat)
          scenario(ScenarioMenu)
          credits(Credits)
| BankList.pick{0}
| begin_ingame 1
//| pause
| $base <= Tabs

main.run =
| set_main Me
| $ui <= ui Me
| $ui.init
| gui $ui cursor/$img{ui_cursor_point}


