use gui widgets view ui_icon ui_widgets macros

CopyrightLine = 'SymtaEngine v0.3; Copyright (c) 2016 Nikita Sadkov'
MapsFolder = 'work/worlds/'
SavesFolder = 'work/saves/'

PanelW = 200 //FIXME: hardcoded stuff is bad

MaxActIcons = 24
ActIcons = []
ActIcon = 0

MenuButtonsX = 0

InputBlocker =
WorldProperties = No
SaveWorldDlg =
LoadWorldDlg =
CreditsRoll =
GameUnitUI =
UnitPanel =
BankList =
HotKeyInvoke = 0

MenuBG =
IconsPanelBG =
PanelTab = \spell

PlayerPicker = 0
PickedIconOverlay = 0

BrushPicker =
PlayerWidget =
PlayIcon =

LastBrush = [0 0]

type ui.$tabs{main} tabs width height world message_box view
| $world <= $main.world
| $width <= $params.ui.width
| $height <= $params.ui.height

ui.render =
| PlayIcon.picked <= not $world.paused
| $tabs.render

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
| PlayIcon.picked <= 0
ui.unpause =
| InputBlocker.show <= 0
| less $world.editor: $view.unpause
| PlayIcon.picked <= not $world.paused

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
| Unit.order.init{Research Unit}

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


create_scenario_menu Me =
| loadScenarioBack = $pick{new_game_menu}
| LoadScenarioDlg = load_dlg $world MapsFolder &loadScenarioBack: X =>
  | load_game Me 1 X
| LoadScenarioDlg.folder <= MapsFolder
| dlg: mtx
  |   0   0 | MenuBG
  |  220 200 | LoadScenarioDlg
  |  16 $height-16 | txt small CopyrightLine

create_load_menu_dlg Me =
| loadScenarioBack = $pick{new_game_menu}
| LoadScenarioDlg = load_dlg $world SavesFolder &loadScenarioBack: X =>
  | load_game Me 1 X
| LoadScenarioDlg.folder <= SavesFolder
| dlg: mtx
  |   0   0 | MenuBG
  |  220 200 | LoadScenarioDlg
  |  16 $height-16 | txt small CopyrightLine

create_main_menu_dlg Me =
| X = MenuButtonsX
| dlg: mtx
  |   0   0 | MenuBG
  |  16 $height-16 | txt small CopyrightLine
  | X 220 | button 'NEW GAME' skin/scroll: => $pick{new_game_menu}
  | X 290 | button 'LOAD GAME' skin/scroll: => $pick{load_menu}
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

EditorTabs =
begin_ingame Me Editor =
| $main.music{playlist}
| $world.editor <= Editor
| EditorTabs.show <= Editor

load_game Me NewGame Path =
| begin_ingame Me 0
| $load{Path}
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
  | $world.name <= P.name.value
  | $world.description <= P.description.value
  | $unpause
  | WorldProperties.show <= 0

create_save_world_dlg Me =
| Dlg = No
| hideDlg = 
  | Dlg.show <= 0
  | $unpause
| DlgW =
| DlgW <= save_dlg $world MapsFolder &hideDlg: X =>
  | Path = "[DlgW.folder][DlgW.filename.value].txt"
  | $save{Path}
  //| $main.show_message{'Saved' 'Your map is saved!'}
  | hideDlg
| DlgW.folder <= MapsFolder
| Dlg <= hidden: DlgW
| Dlg

create_load_world_dlg Me =
| Dlg = No
| hideDlg = 
  | Dlg.show <= 0
  | $unpause
| DlgW = load_dlg $world MapsFolder &hideDlg: X =>
  | $load{X}
  | World = $world
  | World.human <= World.players.1
  | World.human.human <= 1
  | when World.editor:
    | World.paused <= 1
    | World.explore{1}
  | hideDlg
| DlgW.folder <= MapsFolder
| Dlg <= hidden: DlgW
| Dlg

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
  | LastBrush.init{Brush}
| BankList <= litems w/80 lines/40 BankNames f: N =>
  | BankName <= N
  | if got TileBanks.find{BankName}
    then | ItemList.data <= $main.tile_names{BankName}
         | ItemList.pick{0}
         //| ItemList.pick{TileNames.locate{soil}}
    else | ItemList.data <= $main.classes_banks.BankName
         | ItemList.pick{0}
| BankList,ItemList

create_editor_tabs Me =
| PlayIconClick = Icon =>
  | Icon.picked <= not Icon.picked
  | if Icon.picked then $view.unpause else $view.pause
| PlayIcon <= icon data/play $img{icons_tab_play} click/PlayIconClick
| PlayIcon.picked_overlay <= PickedIconOverlay
| hidden: layH s/0 PlayIcon,spacer{8 0}//,BrushIcon


handle_brush_tab Me Picked =
| if PanelTab><brush
  then when Picked<>brush:
       | BrushPicker.show <= 0
       | PlayerWidget.show <= 0
       | $view.set_brush{0,0}
  else when Picked><brush:
       | BrushPicker.show <= 1
       | PlayerWidget.show <= 1
       | $view.set_brush{LastBrush}

MenuTab = 
ActIconsLay =

create_menu_tab Me =
| WorldIcon = icon $img{icons_menu_world} click: Icon =>
  | $pause
  | WorldProperties.show <= 1
  | WorldProperties.update
| SaveIcon = icon data/pick $img{icons_menu_save} click: Icon =>
  | $pause
  | SaveWorldDlg.show <= 1
  | SaveWorldDlg.folder <= if $world.editor then MapsFolder else SavesFolder
  | SaveWorldDlg.filename.value <= $world.filename
| LoadIcon = icon data/pick $img{icons_menu_load} click: Icon =>
  | $pause
  | LoadWorldDlg.show <= 1 
  | LoadWorldDlg.folder <= if $world.editor then MapsFolder else SavesFolder
| ExitIcon = icon data/pick $img{icons_menu_exit} click: Icon =>
  | $main.show_message{'Exit to Main Menu?'
                       'Are you sure want to exit?'
       buttons/[yes,'Yes' no,'No']
       click/|$0 yes => pick_main_menu Me}
| hidden: layH s/4 SaveIcon,LoadIcon,WorldIcon,spacer{8 0},ExitIcon

handle_menu_tab Me Picked =

create_icons_panel_tabs Me =
| MenuTab <= create_menu_tab Me
| MenuTab.show <= 1
| Click = Icon =>
  | $main.sound{ui_click}
  | when PanelTab><brush or Icon.data><brush: handle_brush_tab Me Icon.data
  | PanelTab <= Icon.data
  | ActIconsLay.show <= no [brush menu].find{PanelTab}
  | MenuTab.show <= PanelTab><menu
| Icons = map Name [spell summon build unit brush menu]:
  | Icon = icon data/Name $img{"icons_tab_[Name]"} click/Click
  | when Name><menu: Icon.picked<=1
  | Icon.picked_overlay <= PickedIconOverlay
  | Icon
| for Icon Icons: Icon.group <= Icons
| layH{s/6 Icons}

create_view_ui Me =
| PlayerPickers = map Player $world.players:
  | player_picker Player.name 0 Player.colors.1: Item =>
    | PlayerPicker.picked <= 0
    | Item.picked <= 1
    | PlayerPicker <= Item
    | Name = Item.name
    | when got!it $world.players.find{?name >< Name}: $world.human <= it
| PlayerPicker <= PlayerPickers.1
| PlayerPicker.picked <= 1
| PlayerWidget <= hidden: layH PlayerPickers
| BankList,ItemList = create_bank_list Me
| BrushPicker <= hidden: layH: BankList,ItemList
| for K,V $params.acts: V.icon_gfx <= $img{"icons_[V.icon]"}
| UnitPanel <= unit_panel Me
| IconsPanelTabs = create_icons_panel_tabs Me
| EditorTabs <= create_editor_tabs Me
| GameUnitUI <= hidden: dlg: mtx
  | 0  $height-128-UnitPanel.bg.h | UnitPanel
| IPY = $height-IconsPanelBG.h
| ActIconsLay <= hidden: layV s/4 
                     layH{s/4 ActIcons.drop{ActIcons.size/2}}
                    ,layH{s/4 ActIcons.take{ActIcons.size/2}}
| dlg: mtx
  |  0   0| $view
  |  0   0| BrushPicker
  |  0 IPY| IconsPanelBG
  |  0   0| GameUnitUI
  | 140 IPY-28| IconsPanelTabs
  | 640 IPY-28| EditorTabs
  | 142 $height-110| ActIconsLay
  | 142 $height-110| MenuTab
  | 134 $height-10 | info_line Me
  | 0 $height-128 | minimap $main | X Y => $view.center_at{[X Y 0]}
  | 0 IPY | PlayerWidget

create_ingame_dlg Me =
| Ingame = dlg w/$width h/$height: mtx
  |  0   0| spacer $width $height
  |  0   0| create_view_ui Me
  |  0   0| InputBlocker
  |170 100| WorldProperties
  |170 100| LoadWorldDlg
  |170 100| SaveWorldDlg
  |  0   0| $message_box
| input_split Ingame: Base In => Base.input{In}

create_dialog_tabs Me =
| CreditsRoll <= credits_roll Me $main.credits
| ScenarioMenu = create_scenario_menu Me
| NewGameMenu = create_new_game_dlg Me
| MainMenu = create_main_menu_dlg Me
| Victory = create_victory_dlg Me
| Defeat = create_defeat_dlg Me
| LoadMenu = create_load_menu_dlg Me
| Credits = create_credits_dlg Me
| Ingame = create_ingame_dlg Me
| IsDebug = $main.params.ui.debug><1
| InitTab = if IsDebug then \ingame else \main_menu
| tabs InitTab: t
          main_menu(MainMenu)
          new_game_menu(NewGameMenu)
          scenario_menu(ScenarioMenu)
          load_menu(LoadMenu)
          ingame(Ingame)
          victory(Victory)
          defeat(Defeat)
          scenario(ScenarioMenu)
          credits(Credits)

ui.update = //called by world.update each game cycle
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

ui_update_panel_buttons Me Unit As =
| Acts = $main.params.acts
| As = As.i.take{min{MaxActIcons As.size}}
| Player = Unit.owner
| for I,Act As: when Act.enabled^get_bit{Unit.owner.id}:
  | Preqs = Act.needs.all{Ns=>Ns.any{N=>Player.research_remain{Acts.N}<<0}}
  | when Preqs:
    | Active = 1
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
    | HK = Act.hotkey
    | Icon.hotkey <= if got HK then HK else 0
    | ActIcons.I.show <= Active

ui.on_unit_pick Units =
| if Units.size><1
  then | GameUnitUI.show <= 1
       | UnitPanel.set_unit{Units.0}
  else | GameUnitUI.show <= 0
       | UnitPanel.set_unit{0}
| for Icon ActIcons: Icon.show <= 0
| Unit = 0
| As = 0
| Player = $world.human
|  if PanelTab >< unit then
     | less Units.size: leave
     | Unit <= Units.0
     | As <= Unit.acts
     | when Unit.leader: As <= As.skip{?tab}
     | T = As{[?name 1]}.table
     | for U Units.tail: for A U.acts: when got T.(A.name): !T.(A.name)+1
     | NUnits = Units.size
     | As = As.keep{A=>T.(A.name)><NUnits}
   else
     | if PanelTab >< spell then
         | Unit <= Player.leader
         | less Unit: leave
         | As <= Unit.acts.keep{?tab><spell}
       else if PanelTab >< summon then
         | Unit <= Player.pentagram
         | less Unit: leave
         | As <= Unit.acts
       else if PanelTab >< build then
         | Unit <= Player.leader
         | less Unit: leave
         | As <= Unit.acts.keep{?tab><build}
       else leave
| ui_update_panel_buttons Me Unit As

create_act_icons Me =
| actClick Icon =
  | HKI = HotKeyInvoke
  | HotKeyInvoke <= 0
  | $world.act <= 0
  | $main.sound{ui_click}
  | when ActIcon.is_icon: ActIcon.picked <= 0
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
    else if got Cost and Cost>0 and Cost>O.mana then
      | O.notify{"[Act.title] needs [Cost-O.mana] more mana"}
    else when O.id >< $player.id:
         | if Act.range >< 0 
           then 
            | Us = if PanelTab><unit then $main.ui.view.picked else [Unit]
            | for U Us: U.order.init{Act U}
           else | $world.act <= Act
                | if PanelTab><unit then $world.act_unit.init{0,0}
                  else $world.act_unit.init{Unit,Unit.serial}
                | when HKI: $view.mice_click <= \leftup //FIXME: kludge
| map I MaxActIcons: hidden: icon 0 click/&actClick

ui_input Me Base In =
| Base.input{In}
| when InputBlocker.show: leave 
| case In [key Key 1]
  | for Icon ActIcons: when Icon.show: when Icon.hotkey><Key:
    | HotKeyInvoke <= 1
    | Icon.on_click{}{Icon}

ui.init =
| MapsFolder <= "[$data][MapsFolder]"
| SavesFolder <= "[$data][SavesFolder]"
| $view <= view $main Me $width $height
| $create{8 8}
| MenuButtonsX <= $width/2 - 162
| X = MenuButtonsX
| PickedIconOverlay <= [0 0 $img{"ui_icon_hl"}]
| MenuBG <= $img{ui_menu_bg}
| IconsPanelBG <= $img{ui_panel}
| $message_box <= message_box Me
| InputBlocker <= hidden: spacer $width $height
| WorldProperties <= create_world_props Me
| SaveWorldDlg <= create_save_world_dlg Me
| LoadWorldDlg <= create_load_world_dlg Me
| ActIcons <= create_act_icons Me
| Tabs = create_dialog_tabs Me
| $tabs <= input_split Tabs: Base In => ui_input Me Base In
| BankList.pick{0}
| $view.set_brush{0,0}
| begin_ingame Me 1

main.run =
| set_main Me
| $ui <= ui Me
| $ui.init
| gui $ui cursor/$img{ui_cursor_point}


