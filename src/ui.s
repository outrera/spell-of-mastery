use gui widgets view ui_icon ui_widgets macros

CopyrightLine = 'SymtaEngine v0.2; Copyright (c) 2015 Nikita Sadkov'
MapsFolder = 'work/worlds/'
SavesFolder = 'work/saves/'

PanelW = 200 //FIXME: hardcoded stuff is bad

MaxActIcons = 24
ActIcons = []
ActIcon = 0

PickedUnit = 0

MenuButtonsX = 0

InputBlocker =
WorldProperties = No
LoadWorldDlg =
CreditsRoll =
GameUnitUI =
UnitPanel =
BankList =

MenuBG =

type ui.$tabs{main} tabs width height world message_box view
| $world <= $main.world
| $width <= $params.ui.width
| $height <= $params.ui.height

ui.player = $world.human
ui.data = $main.data
ui.load File =
| $main.load{File}
| $view.clear
ui.save File = $main.save{File}
ui.params = $main.params
ui.act_icons = ActIcons
ui.pause =
| InputBlocker.show <= 1
| $view.pause
ui.unpause =
| InputBlocker.show <= 0
| $view.unpause

ui.img File = $main.img{File}
ui.create W H =
| $world.create{W H}
| $view.clear

pick_main_menu Me pause/1 =
| when Pause: $pause
| $main.music{"title.ogg"}
| $pick{main_menu}

research_act Me Unit Act =
| O = Unit.owner
| Needs = $player.lore-Act.lore.0
| when Needs < 0:
  | O.notify{"Not enough lore for `[Act.title]` (collect [-Needs])"}
  | leave
| Needs = $player.mana-Act.lore.1
| when Needs < 0:
  | O.notify{"Not enough mana for `[Act.title]` (collect [-Needs])"}
  | leave
| $main.show_message{'Research?' buttons/[yes,'Yes' no,'No']
                     'Are you sure want to spent lore on this?'}
| O.researching <= Act.name
| Research = $main.params.acts.research
| Unit.order.init{target Unit @Research.list.join}

create_victory_dlg Me =
| dlg: mtx
  |   0   0 | $img{ui_victory_bg}
  | 100 100 | txt medium: =>
              | Player = $world.players.($world.params.winner)
              | Type = $world.params.victory_type.replace{_ ' '}
              | "[Player.name] has won!\n[Type]"
  | $width-360 $height-100
        | button 'EXIT TO MENU' skin/scroll: => pick_main_menu Me pause/0

create_defeat_dlg Me = 
| dlg: mtx
  |   0   0 | $img{ui_defeat_bg}
  | 140 100 | txt medium: =>
              | Player = $world.human
              | Type = $world.params.victory_type.replace{_ ' '}
              | "[Player.name] has been defeated!\n"
  | $width-360 $height-100
        | button 'EXIT TO MENU' skin/scroll: => pick_main_menu Me pause/0

create_new_game_dlg Me =
| X = MenuButtonsX
| dlg: mtx
  |   0   0 | MenuBG
  |  16 $height-16 | txt small CopyrightLine
  | X 220 | button 'CAMPAIGN' skin/scroll: =>
            | load_game Me 1 "[MapsFolder]level0.txt"
  | X 290 | button 'SCENARIO' skin/scroll: => $pick{scenario_menu}
  | X 360 | button 'MULTIPLAYER' skin/scroll: => 
  | X 500 | button 'BACK' skin/scroll: => $pick{main_menu}

create_game_menu_dlg Me =
| X = MenuButtonsX
| dlg: mtx
  |   0   0 | MenuBG
  |  16 $height-16 | txt small CopyrightLine
  | X 290 | button 'SAVE GAME' skin/scroll: => $pick{save_menu}
  | X 360 | button 'RESUME GAME' skin/scroll: =>
            | $unpause
            | $pick{ingame}
  | X 500 | button 'EXIT TO MENU' skin/scroll: => pick_main_menu Me pause/0


create_scenario_menu Me =
| loadScenarioBack = $pick{new_game_menu}
| LoadScenarioDlg = load_world_dlg $world MapsFolder &loadScenarioBack: X =>
  | load_game Me 1 X
| LoadScenarioDlg.folder <= MapsFolder
| dlg: mtx
  |   0   0 | MenuBG
  |  220 200 | LoadScenarioDlg
  |  16 $height-16 | txt small CopyrightLine

LoadButtons =

create_load_menu_dlg Me =
| X = MenuButtonsX
| dlg: mtx
  |   0   0 | MenuBG
  |  16 $height-16 | txt small CopyrightLine
  | X 200 | LoadButtons.a
  | X 270 | LoadButtons.b
  | X 340 | LoadButtons.c
  | X 410 | LoadButtons.d
  | X 500 | button 'CANCEL' skin/scroll: => $pick{main_menu}

create_save_menu_dlg Me =
| X = MenuButtonsX
| save_slot Name = 
  | $save{"[SavesFolder][Name].txt"}
  | $unpause
  | $pick{ingame}
  //| $main.show_message{'Saved' 'Your game is saved!'}
| dlg: mtx
  |   0   0 | MenuBG
  |  16 $height-16 | txt small CopyrightLine
  | X 200 | button 'SLOT A' skin/scroll: => save_slot a
  | X 270 | button 'SLOT B' skin/scroll: => save_slot b
  | X 340 | button 'SLOT C' skin/scroll: => save_slot c
  | X 410 | button 'SLOT D' skin/scroll: => save_slot d
  | X 500 | button 'CANCEL' skin/scroll: =>
            | $unpause
            | $pick{ingame}

create_main_menu_dlg Me =
| X = MenuButtonsX
| dlg: mtx
  |   0   0 | MenuBG
  |  16 $height-16 | txt small CopyrightLine
  | X 220 | button 'NEW GAME' skin/scroll: => $pick{new_game_menu}
  | X 290 | button 'LOAD GAME' skin/scroll: =>
            | for N,B LoadButtons: B.show <= "[SavesFolder][N].txt".exists
            | $pick{load_menu}
  | X 360 | button 'WORLD EDITOR' skin/scroll: =>
            | $create{8 8}
            | begin_ingame Me 1
            | $unpause
            | $pick{ingame}
  | X 500 | button 'EXIT' skin/scroll: => get_gui{}.exit
  |  $width-80 $height-20
     | button 'Credits' skin/small_medium: =>
       | $main.music{"credits.ogg"}
       | CreditsRoll.reset
       | $pick{credits}

EditorIcons =
GearsIcon =
begin_ingame Me Editor =
| less Editor: $main.music{playlist}
| EditorIcons.show <= Editor
| GearsIcon.show <= not Editor
| $view.mode <= [play brush].Editor

ViewUI =
load_game Me NewGame Path =
| begin_ingame Me 0
| $load{Path}
| ViewUI.pick{play}
| when NewGame: $world.new_game
| $unpause
| $pick{ingame}

parse_int_normalized Default Text =
| if Text.size>0 and Text.all{?is_digit} then Text.int else Default

create_world_props Me = 
| hidden: world_props $world: P =>
  | W = parse_int_normalized{$world.w P.width.value}.clip{4 240}
  | H = parse_int_normalized{$world.h P.height.value}.clip{4 240}
  | when W <> $world.w or H <> $world.h: $create{W H}
  | $world.filename <= P.filename.value
  | $world.name <= P.name.value
  | $world.description <= P.description.value
  | $unpause
  | WorldProperties.show <= 0

create_load_world_dlg Me =
| LoadWorldDlg = No
| hideLoadWorldDlg = 
  | LoadWorldDlg.show <= 0
  | $unpause
| LoadWorldDlgW = load_world_dlg $world MapsFolder &hideLoadWorldDlg: X =>
  | $load{X}
  | $world.explore{1}
  | hideLoadWorldDlg
| LoadWorldDlgW.folder <= MapsFolder
| LoadWorldDlg <= hidden: LoadWorldDlgW
| LoadWorldDlg

create_credits_dlg Me =
| dlg: mtx
  |  0   0 | $img{ui_stars}
  |  0   0 | CreditsRoll
  |  $width-80 $height-20
     | button 'Exit' skin/small_medium: => pick_main_menu Me pause/0


create_bank_list Me =
| TileBanks = $main.params.world.tile_banks
| BankName =
| BankNames = [@TileBanks unit leader @$main.bank_names.skip{unit}.skip{leader}]
| ItemList = litems w/(PanelW-80) lines/40 [] f: N =>
  | Brush = if got TileBanks.find{BankName}
            then [tile N]
            else [obj BankName,N]
  | $view.set_brush{Brush}
| BankList <= litems w/80 lines/40 BankNames f: N =>
  | BankName <= N
  | if got TileBanks.find{BankName}
    then | ItemList.data <= $main.tile_names{BankName}
         | ItemList.pick{0}
         //| ItemList.pick{TileNames.locate{plain}}
    else | ItemList.data <= $main.classes_banks.BankName
         | ItemList.pick{0}
| BankList,ItemList

create_view_ui Me =
| PlayerWidget = droplist $world.players{}{?name} w/110 f: Name =>
  | when got!it $world.players.find{?name >< Name}: $world.human <= it
| BankList,ItemList = create_bank_list Me
| for K,V $params.acts: V.icon_gfx <= $img{"icons_[V.icon]"}
| UnitPanel <= unit_panel Me
| GameUnitUI <= hidden: dlg: mtx
  |  0   0| UnitPanel
| GameUI = dlg: mtx
  |  0   0| $view
  |  0   0| GameUnitUI
  |  4 $height-112| layH{s/4 ActIcons.drop{ActIcons.size/2}}
  |  4 $height-56 | layH{s/4 ActIcons.take{ActIcons.size/2}}
  |  4 $height-10 | info_line Me
| BrushUI = dlg: mtx
  | 0 0 | $view
  | 0 0 | layH: BankList,ItemList
  | PanelW 0 | PlayerWidget
| tabs brush: t brush(BrushUI) pick(GameUI) play(GameUI)

create_ingame_dlg Me =
| ViewUI <= create_view_ui Me
| Ingame = dlg w/$width h/$height: mtx
  |  0   0| spacer $width $height
  |  0   0| ViewUI
  |  $width-54 4| EditorIcons
  |  $width-111 0| GearsIcon
  |  0   0| InputBlocker
  |170 100| WorldProperties
  |170 100| LoadWorldDlg
  |  0   0| $message_box
| input_split Ingame: Base In => Base.input{In}

create_editor_icons Me =
| ModeIcon = No
| EditorModeIconClick = Icon =>
  | ModeIcon.picked <= 0
  | Icon.picked <= 1
  | ModeIcon <= Icon
  | Mode = Icon.data
  | $view.mode <= Mode
  | ViewUI.pick{Mode}
  | if Mode >< play then $world.new_game else $world.explore{1}
| BrushIcon = icon data/brush $img{icons_brush} click/EditorModeIconClick
//| PickIcon = icon data/pick $img{icons_pick} click/EditorModeIconClick
| PlayIcon = icon data/play $img{icons_play} click/EditorModeIconClick
| WorldIcon = icon $img{icons_world} click: Icon =>
  | $pause
  | WorldProperties.show <= 1
  | WorldProperties.update
| SaveIcon = icon data/pick $img{icons_save} click: Icon =>
  | $save{"[MapsFolder][$world.filename].txt"}
  //| $main.show_message{'Saved' 'Your map is saved!'}
| LoadIcon = icon data/pick $img{icons_load} click: Icon =>
  | $pause
  | LoadWorldDlg.show <= 1 
  //| $load{"[MapsFolder][$world.filename].txt"}
| ExitIcon = icon data/pick $img{icons_exit} click: Icon => pick_main_menu Me
| ModeIcon <= BrushIcon
| BrushIcon.picked <= 1
| hidden: layV s/8
    BrushIcon,spacer{8 0}/*,PickIcon,spacer{8 0}*/,PlayIcon,spacer{8 0},
    WorldIcon,spacer{8 0},SaveIcon,spacer{8 0},LoadIcon,spacer{8 0},ExitIcon

create_load_buttons Me =
| load_slot Name = 
  | load_game Me 0 "[SavesFolder][Name].txt"
  //| $main.show_message{'Loaded' 'Your game is loaded!'}
| new_load_button N = button "SLOT [N.upcase]" skin/scroll: => load_slot N
| @table: map N [a b c d]: N,(hidden: new_load_button N)

create_dialog_tabs Me =
| LoadButtons <= create_load_buttons Me
| CreditsRoll <= credits_roll Me $main.credits
| ScenarioMenu = create_scenario_menu Me
| NewGameMenu = create_new_game_dlg Me
| MainMenu = create_main_menu_dlg Me
| GameMenu = create_game_menu_dlg Me
| Victory = create_victory_dlg Me
| Defeat = create_defeat_dlg Me
| SaveMenu = create_save_menu_dlg Me
| LoadMenu = create_load_menu_dlg Me
| Credits = create_credits_dlg Me
| Ingame = create_ingame_dlg Me
| IsDebug = $main.params.world.release<>1
| InitTab = if IsDebug then \ingame else \main_menu
| tabs InitTab: t
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

ui_on_world_update Me =
| InputBlocker.show <= 0
| WinnerId = $world.params.winner
| when got WinnerId:
  | Winner = $world.players.WinnerId
  | NextWorld = when Winner.human: $world.params.next_world
  | less got NextWorld:
    | $pause
    | if Winner.human
      then | $main.music{"victory.ogg"}
           | $pick{victory}
      else | $main.music{"defeat.ogg"}
           | $pick{defeat}
  | when got NextWorld:
    | $load{"[MapsFolder][NextWorld].txt"}
    | $world.new_game

ui_on_view_unit_pick Me Units =
| for Icon ActIcons: Icon.show <= 0
| when Units.size<>1
  | GameUnitUI.show <= 0
  | UnitPanel.set_unit{0}
  | leave
| Unit = Units.0
| PickedUnit <= Unit
| GameUnitUI.show <= 1
| Acts = $main.params.acts
| Player = Unit.owner
| As = Unit.acts.i.take{min{MaxActIcons Unit.acts.size}}
| for I,Act As: when Act.enabled^get_bit{Unit.owner.id}:
  | Preqs = Act.needs.all{N=>Player.research_remain{Acts.N}<<0}
  | when Preqs:
    | Active = 1
    | when Act.act >< summon and not Unit.owner.pentagram:
      | Active <= 0
    | Icon = ActIcons.I.widget
    | ResearchRemain = Player.research_remain{Act}
    | ActName = Act.name
    | Icon.data <= ActName
    | Icon.unit <= Unit
    | Icon.fg <= Act.icon_gfx
    | Icon.grayed <= 0
    | Cool = Unit.cooldown_of{ActName}
    | when Cool and Cool.0:
      | Icon.grayed <= 100-((Cool.1-Cool.0)*100+Cool.1-1)/Cool.1
    | Number = if ResearchRemain <> 0 then ResearchRemain else No
    | Icon.text.init{[0 0 Number]}
    | Frame = if ResearchRemain <> 0 then 'icon_fancy0' else 'icon_fancy1'
    | Icon.frame.init{[3 3 Frame]}
    | Icon.w <= Icon.fg.w
    | Icon.h <= Icon.fg.h
    | ActIcons.I.show <= Active
| UnitPanel.set_unit{Unit}


create_act_icons Me =
| actClick Icon =
  | $world.act <= 0
  | $main.sound{ui_click}
  | when ActIcon: ActIcon.picked <= 0
  //| Icon.picked <= 1
  | Unit = Icon.unit
  | ActIcon <= Icon
  | ActName = Icon.data
  | Act = $params.acts.ActName
  | Cost = Act.cost
  | ResearchRemain = Unit.owner.research_remain{Act}
  | Cool = Unit.cooldown_of{ActName}
  | O = Unit.owner
  | if Cool then
      | O.notify{"[Act.title] needs [Cool.0/24] seconds to recharge"}
    else if ResearchRemain then
      | research_act Me Unit Act
    else if got Cost and Cost>O.mana then
      | O.notify{"[Act.title] needs [Cost-O.mana] more mana"}
    else | if Act.range >< 0
           then when O.id >< $player.id:
                | PickedUnit.order.init{Act PickedUnit}
           else $world.act <= Act
| map I MaxActIcons: hidden: icon 0 click/&actClick

create_ingame_icons Me =
| GearsIcon <= hidden: button 'GEARS' skin/gears: => | $pause; $pick{game_menu}

ui.init =
| MapsFolder <= "[$data][MapsFolder]"
| SavesFolder <= "[$data][SavesFolder]"
| $view <= view $main $width $height
| $create{8 8}
| MenuButtonsX <= $width/2 - 162
| X = MenuButtonsX
| MenuBG <= $img{ui_menu_bg}
| $message_box <= message_box Me
| InputBlocker <= hidden: spacer $width $height
| WorldProperties <= create_world_props Me
| LoadWorldDlg <= create_load_world_dlg Me
| $world.update_ui <= => ui_on_world_update Me
| $view.on_unit_pick <= Unit => ui_on_view_unit_pick Me Unit
| ActIcons <= create_act_icons Me
| EditorIcons <= create_editor_icons Me
| create_ingame_icons Me
| $tabs <= create_dialog_tabs Me
| BankList.pick{0}
| begin_ingame Me 1

main.run =
| set_main Me
| $ui <= ui Me
| $ui.init
| gui $ui cursor/$img{ui_cursor_point}


