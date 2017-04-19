use gui widgets view ui_icon ui_widgets macros

CopyrightLine = 'SymtaEngine v0.3; Copyright (c) 2016 Nikita Sadkov'
MapsFolder = 'work/worlds/'
SavesFolder = 'work/saves/'

PanelW = 200 //FIXME: hardcoded stuff is bad

AllActIcons = []
MaxUnitActIcons = 24
UnitActIcons = []
MaxGroundActIcons = 10
GroundActIcons = []
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
ResourceCounters =

MenuBG =
IconsPanelBG =
PanelTab = \spell

BrushPicker =
PlayerWidget =
PlayerPickers = 0
PickedIconOverlay = 0
PlayIcon =

LastBrush = [0 0]

type ui.$tabs{main} tabs width height world message_box view
| $world <= $main.world
| $width <= $params.ui.width
| $height <= $params.ui.height

ui.render =
| PlayIcon.picked <= not $world.paused
| HumanName = $world.human.name
| for PP PlayerPickers: PP.picked <= PP.name >< HumanName
| $tabs.render

ui.player = $world.human
ui.data = $main.data
ui.load File =
| $main.load{File}
| $view.clear
ui.save File = $main.save{File}
ui.params = $main.params
ui.act_icons = AllActIcons
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
| Needs = $player.lore-Act.lore
| when Needs < 0:
  | O.notify{"Not enough lore for `[Act.title]` (collect [-Needs])"}
  | leave
| Needs = $player.mana-Act.lore
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
            | load_game Me 1 "[MapsFolder]default.txt"
            //| load_game Me 1 "[MapsFolder]level0.txt"
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
  | if Icon.picked
    then | when $world.editor
           | less $world.params.init><1
             | $world.new_game
             | $world.params.init <= 1
         | $view.unpause
    else $view.pause
| PlayIcon <= icon data/play $img{icons_tab_play} click/PlayIconClick
| PlayIcon.picked_fg <= $img{icons_tab_pause}
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
UnitActIconsLay =
GroundActIconsLay =

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
  | ShowActIcons = no [brush menu].find{PanelTab}
  | UnitActIconsLay.show <= ShowActIcons
  | GroundActIconsLay.show <= ShowActIcons
  | MenuTab.show <= PanelTab><menu
| Icons = map Name [spell summon build unit bag brush menu]:
  | Icon = icon data/Name $img{"icons_tab_[Name]"} click/Click
  | when Name><menu: Icon.picked<=1
  | Icon.picked_overlay <= PickedIconOverlay
  | Icon
| for Icon Icons: Icon.group <= Icons
| layH{s/6 Icons}

create_view_ui Me =
| PlayerPickers <= map Player $world.players:
  | player_picker Player.name 0 Player.colors.1: Item =>
    | Name = Item.name
    | when got@@it $world.players.find{?name >< Name}: $world.human <= it
| PlayerPickers.1.picked <= 1
| PlayerWidget <= hidden: layH PlayerPickers
| BankList,ItemList = create_bank_list Me
| BrushPicker <= hidden: layH: BankList,ItemList
| UnitPanel <= unit_panel Me
| IconsPanelTabs = create_icons_panel_tabs Me
| EditorTabs <= create_editor_tabs Me
| GameUnitUI <= hidden: dlg: mtx
  | 0  0 | UnitPanel
| IPY = $height-IconsPanelBG.h
| UnitActIconsLay <= hidden: layV s/4 
                     layH{s/4 UnitActIcons.drop{UnitActIcons.size/2}}
                    ,layH{s/4 UnitActIcons.take{UnitActIcons.size/2}}
| GroundActIconsLay <= hidden: layV s/4 GroundActIcons.flip
| ResourceCounters <= resource_counters $view
| EndTurnButton = button 'END TURN' skin/hourglass: => $world.new_turn
| dlg: mtx
  |  0   0| $view
  |  0   0| ResourceCounters
  |  0 $height-136-UnitPanel.bg.h| GameUnitUI
  |  0   0| BrushPicker
  |  0 IPY| IconsPanelBG
  | 140 IPY-28| IconsPanelTabs
  | 640 IPY-28| EditorTabs
  | 142 $height-110| UnitActIconsLay
  | 142 $height-110| MenuTab
  | 164 $height-10 | infoline
  | $width-50 80 | GroundActIconsLay
  | $width-80 48 | EndTurnButton
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

ui_update_panel_buttons Me Unit As GAs =
| Acts = $main.params.acts
| As = As.i.take{min{MaxUnitActIcons As.size}}
| As = As.keep{Act=>Act.is_list or Act.enabled^get_bit{Unit.owner.id}}
| GAs = GAs.i.map{I,Act=>[-I-1 Act]}.take{min{MaxGroundActIcons GAs.size}}
| Player = Unit.owner
| for I,Act @As,@GAs:
  | Count = No
  | when Act.is_list:
    | Count <= Act.0
    | Act <= Act.1
  | Preqs = Act.needs.all{Ns=>Ns.any{N=>Player.research_remain{Acts.N}<<0}}
  | Icons = if I<0 then | I <= -(I+1); GroundActIcons 
            else UnitActIcons
  | when Preqs:
    | Active = 1
    | Icon = Icons.I.widget
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
    | when got Count: Number <= Count
    | Icon.text.init{[0 0 Number]}
    | Frame = if ResearchRemain <> 0 then 'icon_fancy0' else 'icon_fancy1'
    | Icon.frame.init{[3 3 Frame]}
    | Icon.w <= Icon.fg.w
    | Icon.h <= Icon.fg.h
    | Icon.hotkey <= Act.hotkey
    | Icons.I.show <= Active

ui.on_unit_pick Units =
| if Units.size><1
  then | GameUnitUI.show <= 1
       | UnitPanel.set_unit{Units.0}
  else | GameUnitUI.show <= 0
       | UnitPanel.set_unit{0}
| for Icon AllActIcons: Icon.show <= 0
| Unit = 0
| As = 0
| GAs = []
| Player = $world.human
|  if PanelTab >< unit then
     | less Units.size: leave
     | Unit <= Units.0
     | As <= Unit.acts
     | when Unit.leader: As <= As.skip{?tab}
     | T = As{[?name 1]}.table
     | for U Units.tail: for A U.acts: when got T.(A.name): T.(A.name)++
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
       else if PanelTab >< bag then
         | when Units.size<>1: leave
         | Unit <= Units.0
         | Acts = $main.params.acts
         | As <= map K,A Unit.items: [A Acts."drop_[K]"]
         | GAs <= map K,A Unit.cell.items: [A Acts."take_[K]"]
       else leave
| ui_update_panel_buttons Me Unit As GAs

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
            | for U Us: U.order_at{self act/Act}
           else | $world.act <= Act
                | if PanelTab><unit then $world.act_unit.init{0,0}
                  else $world.act_unit.init{Unit,Unit.serial}
                | when HKI: $view.mice_click <= \leftup //FIXME: kludge
| map I MaxUnitActIcons+MaxGroundActIcons: hidden: icon 0 click/&actClick

ui_input Me Base In =
| Base.input{In}
| when InputBlocker.show: leave 
| case In [key Key 1]
  | for Icon AllActIcons: when Icon.show: when Icon.hotkey><Key:
    | HotKeyInvoke <= 1
    | Icon.on_click{}{Icon}

ui.init =
| MapsFolder <= "[$data][MapsFolder]"
| SavesFolder <= "[$data][SavesFolder]"
| $view <= view $main Me $width $height-128
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
| AllActIcons <= create_act_icons Me
| UnitActIcons <= AllActIcons.take{MaxUnitActIcons}
| GroundActIcons <= AllActIcons.drop{MaxUnitActIcons}
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


