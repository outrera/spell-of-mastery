use gui widgets view ui_icon ui_widgets macros

type ui.$tabs{main}
  tabs
  width
  height
  world
  message_box
  creditsRoll
  view
  paused
  mapsFolder/"work/worlds/"
  savesFolder/"work/saves/"
  panelTab/spell
  actIcons/[]
  maxUnitActIcons/24
  maxGroundActIcons/10
  curActIcon/0
  unitActIcons/[]
  groundActIcons/[]
  unitActIconsLay
  groundActIconsLay
  menuButtonsX/0
  menuBG
  iconsPanelBG
  inputBlocker
  worldProperties
  saveWorldDlg
  loadWorldDlg
  bankList
  playButton
  menuTab
  hotKeyInvoke/0
  brushPicker
  playerWidget
  playerPickers/0
  copyrightText
  lastBrush/[0 0]
| $world <= $main.world
| $width <= $params.ui.width
| $height <= $params.ui.height
| $menuButtonsX <= $width/2 - 162


ui.render =
| $inputBlocker.show <= $paused or $world.actors.get.size
                     or not ($world.players.($world.player).human
                             or $world.editor)
| HumanName = $world.human.name
| for PP $playerPickers: PP.picked <= PP.name >< HumanName
| $tabs.render

ui.player = $world.human
ui.data = $main.data
ui.load File =
| $main.load{File}
| $view.clear
ui.save File = $main.save{File}
ui.params = $main.params
ui.pause =
| $paused <= 1
| $inputBlocker.show <= 1
ui.unpause =
| $paused <= 0
| $inputBlocker.show <= 0

ui.img File = $main.img{File}
ui.create W H =
| $world.create{W H}
| $view.clear

ui.pick_main_menu pause/1 =
| when Pause: $pause
| $main.music{"title.ogg"}
| $pick{main_menu}

ui.create_victory_dlg =
| dlg: mtx
  |   0   0 | $img{ui_victory_bg}
  | 100 100 | txt medium: =>
              | Player = $world.players.($world.params.winner)
              | Type = $world.params.victory_type.replace{_ ' '}
              | "[Player.name] has won!\n[Type]"
  | $width-360 $height-100
        | button 'EXIT TO MENU' skin/scroll: => $pick_main_menu{pause/0}

ui.create_defeat_dlg = 
| dlg: mtx
  |   0   0 | $img{ui_defeat_bg}
  | 140 100 | txt medium: =>
              | Player = $world.human
              | Type = $world.params.victory_type.replace{_ ' '}
              | "[Player.name] has been defeated!\n"
  | $width-360 $height-100
        | button 'EXIT TO MENU' skin/scroll: => $pick_main_menu{pause/0}

ui.create_new_game_dlg =
| X = $menuButtonsX
| dlg: mtx
  |   0   0 | $menuBG
  |  16 $height-16 | $copyrightText
  | X 220 | button 'CAMPAIGN' skin/scroll: =>
            | $load_game{1 "[$mapsFolder]default.txt"}
            //| $load_game{1 "[$mapsFolder]level0.txt"}
  | X 290 | button 'SCENARIO' skin/scroll: => $pick{scenario_menu}
  | X 360 | button 'MULTIPLAYER' skin/scroll: => 
  | X 500 | button 'BACK' skin/scroll: => $pick{main_menu}


ui.create_scenario_menu =
| loadScenarioBack = $pick{new_game_menu}
| LoadScenarioDlg = load_dlg $world $mapsFolder &loadScenarioBack: X =>
  | $load_game{1 X}
| dlg: mtx
  |   0   0 | $menuBG
  |  220 200 | LoadScenarioDlg
  |  16 $height-16 | $copyrightText

ui.create_load_menu_dlg =
| loadScenarioBack = $pick{new_game_menu}
| LoadScenarioDlg = load_dlg $world $savesFolder &loadScenarioBack: X =>
  | $load_game{0 X}
  | $world.paused <= 0
| dlg: mtx
  |   0   0 | $menuBG
  |  220 200 | LoadScenarioDlg
  |  16 $height-16 | $copyrightText

ui.create_main_menu_dlg =
| X = $menuButtonsX
| dlg: mtx
  |   0   0 | $menuBG
  |  16 $height-16 | $copyrightText
  | X 220 | button 'NEW GAME' skin/scroll: => $pick{new_game_menu}
  | X 290 | button 'LOAD GAME' skin/scroll: => $pick{load_menu}
  | X 360 | button 'WORLD EDITOR' skin/scroll: =>
            | $create{8 8}
            | $begin_ingame{1}
            | $unpause
            | $pick{ingame}
  | X 500 | button 'EXIT' skin/scroll: => get_gui{}.exit
  |  $width-80 $height-20
     | button 'Credits' skin/small_medium: =>
       | $main.music{"credits.ogg"}
       | $creditsRoll.reset
       | $pick{credits}

ui.begin_ingame Editor =
| $main.music{playlist}
| $world.editor <= Editor
| $playButton.show <= Editor

ui.load_game NewGame Path =
| $begin_ingame{0}
| $load{Path}
| when NewGame: $world.new_game
| $unpause
| $pick{ingame}

parse_int_normalized Default Text =
| if Text.size>0 and Text.all{?is_digit} then Text.int else Default

ui.create_world_props = 
| hidden: world_props $world: P =>
  | W = parse_int_normalized{$world.w P.width.value}.clip{4 240}
  | H = parse_int_normalized{$world.h P.height.value}.clip{4 240}
  | when W <> $world.w or H <> $world.h: $create{W H}
  | $world.name <= P.name.value
  | $world.description <= P.description.value
  | $unpause
  | $worldProperties.show <= 0

ui.create_save_world_dlg =
| Dlg = No
| hideDlg = 
  | Dlg.show <= 0
  | $unpause
| DlgW =
| DlgW <= save_dlg $world $mapsFolder &hideDlg: X =>
  | Path = "[DlgW.folder][DlgW.filename.value].txt"
  | $save{Path}
  //| $main.show_message{'Saved' 'Your map is saved!'}
  | hideDlg
| Dlg <= hidden: DlgW
| Dlg

ui.create_load_world_dlg =
| Dlg = No
| hideDlg = 
  | Dlg.show <= 0
  | $unpause
| DlgW = load_dlg $world $mapsFolder &hideDlg: X =>
  | $load{X}
  | World = $world
  | World.human <= World.players.1
  | World.human.human <= 1
  | when World.editor:
    | World.paused <= 1
    | World.explore{1}
  | hideDlg
| Dlg <= hidden: DlgW
| Dlg

ui.create_credits_dlg =
| $creditsRoll <= credits_roll Me $main.credits
| dlg: mtx
  |  0   0 | $img{ui_stars}
  |  0   0 | $creditsRoll
  |  $width-80 $height-20
     | button 'Exit' skin/small_medium: => $pick_main_menu{pause/0}

ui.create_bank_list =
| TileBanks = $main.params.world.tile_banks
| BankName =
| BankNames = [@TileBanks unit leader @$main.bank_names.skip{unit}.skip{leader}]
| PanelW = 200 //FIXME: hardcoded stuff is bad
| ItemList = litems w/(PanelW-80) lines/40 [] f: N =>
  | Brush = if got TileBanks.find{BankName}
            then [tile N]
            else [obj BankName,N]
  | $view.set_brush{Brush}
  | $lastBrush.init{Brush}
| BankList = litems w/80 lines/40 BankNames f: N =>
  | BankName <= N
  | if got TileBanks.find{BankName}
    then | ItemList.data <= $main.tile_names{BankName}
         | ItemList.pick{0}
         //| ItemList.pick{TileNames.locate{soil}}
    else | ItemList.data <= $main.classes_banks.BankName
         | ItemList.pick{0}
| BankList,ItemList

ui.create_play_button =
| Icon = icon data/play $img{icons_tab_play} click/
  | Icon =>
    | $world.new_game
    | $unpause
| Icon.picked_fg <= $img{icons_tab_pause}
| hidden{Icon}

ui.handle_brush_tab Picked =
| if $panelTab><brush
  then when Picked<>brush:
       | $brushPicker.show <= 0
       | $playerWidget.show <= 0
       | $view.set_brush{0,0}
  else when Picked><brush:
       | $brushPicker.show <= 1
       | $playerWidget.show <= 1
       | $view.set_brush{$lastBrush}

ui.create_menu_tab =
| WorldIcon = icon $img{icons_menu_world} click: Icon =>
  | $pause
  | $worldProperties.show <= 1
  | $worldProperties.update
| SaveIcon = icon data/pick $img{icons_menu_save} click: Icon =>
  | $pause
  | $saveWorldDlg.show <= 1
  | $saveWorldDlg.folder <= if $world.editor then $mapsFolder else $savesFolder
  | $saveWorldDlg.filename.value <= $world.filename
| LoadIcon = icon data/pick $img{icons_menu_load} click: Icon =>
  | $pause
  | $loadWorldDlg.show <= 1 
  | $loadWorldDlg.folder <= if $world.editor then $mapsFolder else $savesFolder
| ExitIcon = icon data/pick $img{icons_menu_exit} click: Icon =>
  | $main.show_message{'Exit to Main Menu?'
                       'Are you sure want to exit?'
       buttons/[yes,'Yes' no,'No']
       click/|$0 yes => $pick_main_menu}
| hidden: layH s/4 SaveIcon,LoadIcon,WorldIcon,spacer{8 0},ExitIcon

ui.create_icons_panel_tabs =
| $menuTab <= $create_menu_tab
| $menuTab.show <= 1
| Click = Icon =>
  | $main.sound{ui_click}
  | when $panelTab><brush or Icon.data><brush: $handle_brush_tab Icon.data
  | $panelTab <= Icon.data
  | ShowActIcons = no [brush menu].find{$panelTab}
  | $unitActIconsLay.show <= ShowActIcons
  | $groundActIconsLay.show <= ShowActIcons
  | $menuTab.show <= $panelTab><menu
| Icons = map Name [unit spell summon bag brush menu]:
  | Icon = icon data/Name $img{"icons_tab_[Name]"} click/Click
  | when Name><menu: Icon.picked<=1
  | Icon.picked_overlay <= \icon_hl
  | Icon
| for Icon Icons: Icon.group <= Icons
| Icons

ui.create_ingame_ui =
| $playerPickers <= map Player $world.players:
  | player_picker Player.name 0 Player.colors.1: Item =>
    | Name = Item.name
    | when got@@it $world.players.find{?name >< Name}: $world.human <= it
| $playerPickers.1.picked <= 1
| $playerWidget <= hidden: layH $playerPickers
| BankList,ItemList = $create_bank_list
| $bankList <= BankList
| $brushPicker <= hidden: layH: BankList,ItemList
| IPY = $height-$iconsPanelBG.h
| $unitActIconsLay <= hidden: layV s/14
                     layH{s/8 $unitActIcons.drop{$unitActIcons.size/2}}
                    ,layH{s/8 $unitActIcons.take{$unitActIcons.size/2}}
| $groundActIconsLay <= hidden: layV s/4 $groundActIcons.flip
| IconsPanelTabs = $create_icons_panel_tabs
| $playButton <= $create_play_button
| EndTurnButton = icon data/endturn $img{icons_tab_endturn} click/|Icon=>$world.end_turn
| HeaderIcons = layH s/8 [@IconsPanelTabs spacer{16 0} $playButton spacer{140 0} EndTurnButton]
| dlg: mtx
  |  0   0| $view
  |  0   0| resource_counters $view
  |  0   0| $brushPicker
  |  0 IPY| $iconsPanelBG
  | 140 IPY-28| HeaderIcons
  | 146 $height-118| $unitActIconsLay
  | 146 $height-110| $menuTab
  | 164 $height-20 | infoline
  | 0 $height-170 | notification_widget $view
  | $width-50 80 | $groundActIconsLay
  | 0 $height-128 | minimap $main | X Y => $view.center_at{[X Y 0]}
  | 0 IPY | $playerWidget

ui.create_ingame_dlg =
| $saveWorldDlg <= $create_save_world_dlg
| $loadWorldDlg <= $create_load_world_dlg
| Ingame = dlg w/$width h/$height: mtx
  |  0   0| spacer $width $height
  |  0   0| $create_ingame_ui
  |  0   0| $inputBlocker
  |170 100| $worldProperties
  |170 100| $loadWorldDlg
  |170 100| $saveWorldDlg
  |  0   0| $message_box
| input_split Ingame: Base In => Base.input{In}

ui.create_dialog_tabs =
| $copyrightText <= txt small 'Spell of Mastery v0.4; Copyright (c) 2016-2018 Nikita Sadkov'
| IsDebug = $main.params.ui.debug><1
| InitTab = if IsDebug then \ingame else \main_menu
| tabs InitTab: t
          main_menu($create_main_menu_dlg)
          new_game_menu($create_new_game_dlg)
          scenario_menu($create_scenario_menu)
          load_menu($create_load_menu_dlg)
          ingame($create_ingame_dlg)
          victory($create_victory_dlg)
          defeat($create_defeat_dlg)
          credits($create_credits_dlg)

ui.update = //called by world.update each game cycle
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
    | $load{"[$mapsFolder][NextWorld].txt"}
    | $world.new_game

ui.update_act_icon I Act Count Unit =
| Icons = if I<0 then | I <= -(I+1); $groundActIcons 
          else $unitActIcons
| Active = 1
| Icon = Icons.I.widget
| ResearchRemain = Unit.owner.research_remain{Act}
| ActName = Act.name
| Icon.data <= ActName
| Icon.unit <= Unit
| Icon.fg <= Act.icon_gfx
| Icon.grayed <= 0
| Cool = Unit.cooldown_of{ActName}
| when Cool and Cool.1:
  | TurnsDone = Unit.world.turn - Cool.0
  | TurnsTotal = Cool.1
  | Icon.grayed <= 100-(TurnsDone*100)/TurnsTotal
| Number = if ResearchRemain <> 0 then ResearchRemain else No
| when got Count: Number <= Count
| Icon.text.init{[0 0 Number]}
| Frame = if ResearchRemain <> 0 then 'icon_fancy0' else 'icon_fancy1'
| Icon.frame.init{[3 3 icon_act]}
| Icon.w <= Icon.fg.w
| Icon.h <= Icon.fg.h
| Icon.hotkey <= Act.hotkey
| Icons.I.show <= Active

ui.update_panel_buttons Unit As GAs =
| As = As.take{min{$maxUnitActIcons As.size}}
| GAs = GAs.take{min{$maxGroundActIcons GAs.size}}
| Player = Unit.owner
| I = 0
| for Act [@As @GAs{[gact ?]}]:
  | Count = No
  | GAct = 0 //ground act
  | case Act [gact A]
    | GAct <= 1
    | Act <= A
  | when Act.is_list:
    | Count <= Act.0
    | Act <= Act.1
  | when Unit.can{Act} or Unit.owner.can_research{Act}:
    | $update_act_icon{(if GAct then -I-1 else I) Act Count Unit}
    | I += 1

ui.on_unit_pick Units =
| for Icon $actIcons: Icon.show <= 0
| Unit = 0
| As = 0
| GAs = []
| Unit = if Units.size then Units.0 else $world.nil
| Acts = $main.params.acts
| if Unit.has{menu} then
     | MenuActName,XYZ,TargetSerial = Unit.get{menu}
     | As <= if TargetSerial><research
             then [Acts.m_yes Acts.m_no]
             else Acts.MenuActName.menu
  else if $panelTab >< unit then
     | As <= if Unit.removed then [] else Unit.acts.skip{?tab}
  else if $panelTab >< summon or $panelTab >< spell then
     | Unit <= $world.human.leader
     | As <= Unit.acts.keep{?tab><$panelTab}
  else if $panelTab >< bag then
     | As <= map K,A Unit.items: [A Acts."drop_[K]"]
     | GAs <= map K,A Unit.cell.items: [A Acts."take_[K]"]
  else leave
| $update_panel_buttons{Unit As GAs}

unit.research_act Act =
| O = $owner
| Needs = O.lore-Act.lore
| when Needs < 0:
  | O.notify{"Not enough lore for `[Act.title]` (collect [-Needs])"}
  | leave
| O.notify{"Research this?"}
| $owner.picked <= [Me]
| $set{menu [Act.name $xyz research]}

ui.actClickIcon Icon =
| HKI = $hotKeyInvoke
| $hotKeyInvoke <= 0
| $world.act <= 0
| $main.sound{ui_click}
| when $curActIcon: $curActIcon.picked <= 0
| $curActIcon <= Icon
| Unit = Icon.unit
| O = Unit.owner
| when $paused or O.id <> $player.id: leave
| ActName = Icon.data
| Act = $params.acts.ActName
| Cost = Act.cost
| ResearchRemain = Unit.owner.research_remain{Act}
| Cool = Unit.cooldown_of{ActName}
| when Cool:
  | TurnsLeft = Cool.0 + Cool.1 - Unit.world.turn
  | O.notify{"[Act.title] needs [TurnsLeft] turns to recharge"}
  | leave
| when ResearchRemain:
  | Unit.research_act{Act}
  | leave
| when got Cost and Cost>0 and Cost>O.mana:
  | O.notify{"[Act.title] needs [Cost-O.mana] more mana"}
  | leave
| when Unit.mov < Act.mov:
  | O.notify{"[Act.title] requires [Act.mov] moves."}
  | leave
| when Act.range >< 0:
  | $view.handle_picked_act2{Unit Act Unit.xyz Unit}
  | leave
| $world.act <= Act
| $world.act_unit.init{Unit,Unit.serial}
| when HKI: $view.mice_click <= \leftup //FIXME: kludge

ui.create_act_icons =
| map I $maxUnitActIcons+$maxGroundActIcons:
  | hidden: icon 0 click/|Icon => $actClickIcon{Icon}

ui.process_input Base In =
| Base.input{In}
| when $inputBlocker.show: leave 
| case In [key Key 1]
  | for Icon $actIcons: when Icon.show: when Icon.hotkey><Key:
    | $hotKeyInvoke <= 1
    | Icon.on_click{}{Icon}

ui.init =
| $mapsFolder <= "[$data][$mapsFolder]"
| $savesFolder <= "[$data][$savesFolder]"
| $view <= view $main Me $width $height-128
| $create{8 8}
| $menuBG <= $img{ui_menu_bg}
| $iconsPanelBG <= $img{ui_panel}
| $message_box <= message_box Me
| $inputBlocker <= hidden: spacer $width $height
| $worldProperties <= $create_world_props
| $actIcons <= $create_act_icons
| $unitActIcons <= $actIcons.take{$maxUnitActIcons}
| $groundActIcons <= $actIcons.drop{$maxUnitActIcons}
| Tabs = $create_dialog_tabs
| $tabs <= input_split Tabs: Base In => $process_input{Base In}
| $bankList.pick{0}
| $view.set_brush{0,0}
| $begin_ingame{1}

export ui