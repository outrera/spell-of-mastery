use gui widgets view world ui_icon ui_widgets macros

type ui.$tabs{main}
  tabs
  width
  height
  site
  message_box
  creditsRoll
  view
  paused
  mapsFolder/"work/sites/"
  savesFolder/"work/saves/"
  world
  confirmFn //callaback for yes/no confirmation
  panelTabs
  panelTabsMore/(t) //sparse element related to picked tab
  panelTabsSelect/(t)
  panelTabsDeselect/(t)
  panelBG
  curPanelTab/menu
  actIcons/[]
  maxUnitActIcons/24
  maxGroundActIcons/10
  curActIcon/0
  unitActIcons/[]
  groundActIcons/[]
  groundActIconsLay
  menuButtonsX/0
  menuBG
  inputBlocker
  siteProperties
  saveSiteDlg
  loadSiteDlg
  bankList
  hotKeyInvoke/0
  playerWidget
  playerPickers/0
  copyrightText
  brushPicker
  lastBrush/[0 0]
  editorWidgets/[]
  notes
  noteLife/1.0
| $site <= $main.site
| Prm = $params.ui
| $width <= Prm.width
| $height <= Prm.height
| $noteLife <= Prm.note_life
| NoteSize = Prm.note_size
| $notes <= dup Prm.max_notes: [0.0 (dup NoteSize ``)]
| $menuButtonsX <= $width/2 - 162

ui.notify Text =
| Clock = clock
| Used = $notes.keep{?0 > Clock}
| Free = $notes.skip{?0 > Clock}
| less Free.size: push Used^pop Free
| N = Free.0
| N.0 <= Clock + $noteLife
| Chars = N.1
| Chars.clear{``}
| for I min{Chars.size Text.size}: Chars.I <= Text.I
| $notes.init{[@Used @Free]}

ui.render =
| $inputBlocker.show <= $paused or $site.actors.get.size
                     or not ($site.players.($site.player).human
                             or $site.editor)
| HumanName = $site.human.name
| for PP $playerPickers: PP.picked <= PP.name >< HumanName
| $tabs.render

ui.player = $site.human
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
| $site.create{W H}
| $view.clear

ui.pick_title_menu pause/1 =
| when Pause: $pause
| $main.music{"title.ogg"}
| $pick{main_menu}

ui.pick_world pause/1 =
| when Pause: $pause
| $main.music{"title.ogg"}
| $pick{world}

ui.create_victory_dlg =
| dlg: mtx
  |   0   0 | $img{ui_victory_bg}
  | 100 100 | txt medium: =>
              | Player = $site.players.($site.params.winner)
              | Type = $site.params.victory_type.replace{_ ' '}
              | "[Player.name] has won!\n[Type]"
  | $width-360 $height-100
        | button 'EXIT TO MENU' skin/scroll: => $pick_title_menu{pause/0}

ui.create_defeat_dlg = 
| dlg: mtx
  |   0   0 | $img{ui_defeat_bg}
  | 140 100 | txt medium: =>
              | Player = $site.human
              | Type = $site.params.victory_type.replace{_ ' '}
              | "[Player.name] has been defeated!\n"
  | $width-360 $height-100
        | button 'EXIT TO MENU' skin/scroll: => $pick_title_menu{pause/0}

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
| LoadScenarioDlg = load_dlg $site $mapsFolder &loadScenarioBack: X =>
  | $load_game{1 X}
| dlg: mtx
  |   0   0 | $menuBG
  |  220 200 | LoadScenarioDlg
  |  16 $height-16 | $copyrightText

ui.create_load_menu_dlg =
| loadScenarioBack = $pick{new_game_menu}
| LoadScenarioDlg = load_dlg $site $savesFolder &loadScenarioBack: X =>
  | $load_game{0 X}
  | $site.paused <= 0
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
| $site.editor <= Editor
| for W $editorWidgets: W.show <= Editor

ui.load_game NewGame Path =
| $begin_ingame{0}
| $load{Path}
| when NewGame: $site.new_game
| $unpause
| $pick{ingame}

parse_int_normalized Default Text =
| if Text.size>0 and Text.all{?is_digit} then Text.int else Default

ui.create_site_props = 
| hidden: site_props $site: P =>
  | W = parse_int_normalized{$site.w P.width.value}.clip{4 240}
  | H = parse_int_normalized{$site.h P.height.value}.clip{4 240}
  | when W <> $site.w or H <> $site.h: $create{W H}
  | $site.name <= P.name.value
  | $site.description <= P.description.value
  | $unpause
  | $siteProperties.show <= 0

ui.create_save_site_dlg =
| Dlg = No
| hideDlg = 
  | Dlg.show <= 0
  | $unpause
| DlgW =
| DlgW <= save_dlg $site $mapsFolder &hideDlg: X =>
  | Path = "[DlgW.folder][DlgW.filename.value].txt"
  | $save{Path}
  //| $main.show_message{'Saved' 'Your map is saved!'}
  | hideDlg
| Dlg <= hidden: DlgW
| Dlg

ui.create_load_site_dlg =
| Dlg = No
| hideDlg = 
  | Dlg.show <= 0
  | $unpause
| DlgW = load_dlg $site $mapsFolder &hideDlg: X =>
  | $load{X}
  | Site = $site
  | Site.human <= Site.players.1
  | Site.human.human <= 1
  | when Site.editor:
    | Site.paused <= 1
    | Site.explore{1}
  | hideDlg
| Dlg <= hidden: DlgW
| Dlg

ui.create_credits_dlg =
| $creditsRoll <= credits_roll Me $main.credits
| dlg: mtx
  |  0   0 | $img{ui_stars}
  |  0   0 | $creditsRoll
  |  $width-80 $height-20
     | button 'Exit' skin/small_medium: => $pick_title_menu{pause/0}

ui.create_bank_list =
| TileBanks = $main.params.site.tile_banks
| BankName =
| BankNames = [@TileBanks unit leader @$main.bank_names.skip{unit}.skip{leader}]
| PanelW = 200 //FIXME: hardcoded stuff is bad
| ItemList = litems PanelW-80 $height-$panelBG.h []: N =>
  | Brush = if got TileBanks.find{BankName}
            then [tile N]
            else [obj BankName,N]
  | $view.set_brush{Brush}
  | $lastBrush.init{Brush}
| BankList = litems 80 $height-$panelBG.h BankNames: N =>
  | BankName <= N
  | if got TileBanks.find{BankName}
    then | ItemList.data <= $main.tile_names{BankName}
         | ItemList.pick{0}
         //| ItemList.pick{TileNames.locate{soil}}
    else | ItemList.data <= $main.classes_banks.BankName
         | ItemList.pick{0}
| BankList,ItemList

ui.create_panel_tab_menu =
| SiteIcon = icon menu_site: Icon =>
  | $pause
  | $siteProperties.show <= 1
  | $siteProperties.update
| SaveIcon = icon menu_save: Icon =>
  | $pause
  | $saveSiteDlg.show <= 1
  | $saveSiteDlg.folder <= if $site.editor then $mapsFolder else $savesFolder
  | $saveSiteDlg.filename.value <= $site.filename
| LoadIcon = icon menu_load: Icon =>
  | $pause
  | $loadSiteDlg.show <= 1
  | $loadSiteDlg.folder <= if $site.editor then $mapsFolder else $savesFolder
| ExitIcon = icon menu_exit: Icon =>
  | $confirm{"Sure want to exit?" |$0 yes => $pick_title_menu}
| LeaveIcon = icon menu_leave: Icon =>
  | $pick_world
  //| $confirm{"Leave this site?" |$0 yes => $pick_world}
| layV s/4 [(layH s/4 SaveIcon,LoadIcon,SiteIcon,spacer{8 0},ExitIcon)
            (LeaveIcon)]

ui.confirm Msg Fn =
| $notify{Msg}
| $confirmFn <= Fn
| $panelTabs.pick{confirm}

ui.confirm_done State =
| $panelTabs.pick{$curPanelTab}
| Fn = $confirmFn
| $confirmFn <= 0
| Fn{State}

ui.create_panel_tab_confirm =
| YesIcon = icon menu_yes: Icon => $confirm_done{yes}
| NoIcon = icon menu_no: Icon => $confirm_done{no}
| layH s/4 YesIcon,NoIcon

ui.create_play_button =
| Icon = icon tab_play: Icon =>
  | $site.new_game
  | $unpause
| Icon.picked_fg <= $img{icons_tab_pause}
| hidden Icon


ui.create_panel_tab_bag =
| $panelTabsMore.bag <= [$groundActIconsLay]
| $unitActIconsLay

ui.create_panel_tab_brush =
| $playerPickers <= map Player $site.players:
  | player_picker Player.name 0 Player.colors.1: Item =>
    | Name = Item.name
    | when got@@it $site.players.find{?name >< Name}: $site.human <= it
| $playerPickers.1.picked <= 1
| $playerWidget <= hidden: layH $playerPickers
| BankList,ItemList = $create_bank_list
| $bankList <= BankList
| ItemSlider = slider v $height-$panelBG.h-38: N =>
  | ItemList.offset <= @int N*ItemList.data.size.float
| $brushPicker <= hidden: layH: BankList,ItemList,ItemSlider
| $panelTabsMore.brush <= [$brushPicker $playerWidget]
| $panelTabsSelect.brush <= From To => $view.set_brush{$lastBrush}
| $panelTabsDeselect.brush <= From To => $view.set_brush{0,0}
| spacer{1 1}

ui.create_panel_tabs =
| $actIcons <= $create_act_icons
| $unitActIcons <= $actIcons.take{$maxUnitActIcons}
| ActIconsLay = layV s/14
                     layH{s/8 $unitActIcons.drop{$unitActIcons.size/2}}
                    ,layH{s/8 $unitActIcons.take{$unitActIcons.size/2}}
| $groundActIcons <= $actIcons.drop{$maxUnitActIcons}
| $groundActIconsLay <= hidden: layV s/4 $groundActIcons.flip
| $panelTabs <= tabs menu: t
          unit    | ActIconsLay
          spell   | ActIconsLay
          summon  | ActIconsLay
          bag     | ActIconsLay
          menu    | $create_panel_tab_menu
          brush   | $create_panel_tab_brush
          confirm | $create_panel_tab_confirm
| $panelTabs

ui.panel_tab_picked TabName = 
| when got@@it $panelTabsDeselect.$curPanelTab: (it){$curPanelTab TabName}
| when got@@it $panelTabsSelect.$curPanelTab: (it){$curPanelTab TabName}
| Ms = $panelTabsMore.$curPanelTab
| when got Ms: for M Ms: M.show <= 0
| $curPanelTab <= TabName
| Ms = $panelTabsMore.$curPanelTab
| when got Ms: for M Ms: M.show <= 1
| $panelTabs.pick{TabName}

ui.create_panel_tabs_header =
| Click = Icon => $panel_tab_picked{Icon.data}
| TabIconsBare = []
| TabsIcons = map Name [unit spell summon bag menu brush]:
  | Icon = icon "tab_[Name]" Click
  | Icon.data <= Name
  | when Name><$curPanelTab: Icon.picked<=1
  | Icon.picked_overlay <= \icon_hl
  | push Icon TabIconsBare
  | when Name><brush:
    | Icon <= hidden Icon
    | push Icon $editorWidgets
  | Icon
| for Icon TabIconsBare: Icon.group <= TabIconsBare
| PlayButton = $create_play_button
| push PlayButton $editorWidgets
| EndTurnButton = icon tab_endturn: Icon => $site.end_turn
| layH s/8 [@TabsIcons spacer{16 0} PlayButton spacer{140 0} EndTurnButton]

ui.create_ingame_ui =
| $create_panel_tabs //should preceede create_panel_tabs_header
| PY = $height-$panelBG.h
| dlg: mtx
  |  0   0          | $view
  |  0   0          | resource_counters $view
  |  0   0          | $brushPicker
  |  0  PY          | $panelBG
  | 140 PY-28       | $create_panel_tabs_header
  | 146 $height-114 | $panelTabs
  | 164 $height-20  | infoline
  | 0   $height-170 | notification_widget Me
  | $width-50 80    | $groundActIconsLay
  | 0   $height-128 | minimap $main | X Y => $view.center_at{[X Y 0]}
  | 0   PY          | $playerWidget

ui.create_ingame_dlg =
| $saveSiteDlg <= $create_save_site_dlg
| $loadSiteDlg <= $create_load_site_dlg
| Ingame = dlg w/$width h/$height: mtx
  |  0   0| spacer $width $height
  |  0   0| $create_ingame_ui
  |  0   0| $inputBlocker
  |170 100| $siteProperties
  |170 100| $loadSiteDlg
  |170 100| $saveSiteDlg
  |  0   0| $message_box
| input_split Ingame: Base In => Base.input{In}

ui.create_world_dlg =
| $world <= world $main Me $width $height
| BY = $height-64
| ET = icon tab_endturn: Icon => $world.end_turn
| EX = icon menu_exit: Icon => $pick_title_menu
| Buttons = layH s/4 [ET spacer{44 0} EX]
| dlg w/$width h/$height: mtx
  |   0           0| $world
  |   0 $height-20 | infoline
  |   0 $height-170| notification_widget Me
  |  32          BY| Buttons

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
          world($create_world_dlg)

ui.update = //called by site.update each game cycle
| WinnerId = $site.params.winner
| when got WinnerId:
  | Winner = $site.players.WinnerId
  | NextSite = when Winner.human: $site.params.next_site
  | less got NextSite:
    | $pause
    | if Winner.human
      then | $main.music{"victory.ogg"}
           | $pick{victory}
      else | $main.music{"defeat.ogg"}
           | $pick{defeat}
  | when got NextSite:
    | $load{"[$mapsFolder][NextSite].txt"}
    | $site.new_game

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
  | TurnsDone = Unit.site.turn - Cool.0
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
| Unit = if Units.size then Units.0 else $site.nil
| Acts = $main.params.acts
| if Unit.has{menu} then
     | MenuActName,XYZ,TargetSerial = Unit.get{menu}
     | As <= if TargetSerial><research
             then [Acts.m_yes Acts.m_no]
             else Acts.MenuActName.menu
  else if $curPanelTab >< unit then
     | As <= if Unit.removed then [] else Unit.acts.skip{?tab}
  else if $curPanelTab >< summon or $curPanelTab >< spell then
     | Unit <= $site.human.leader
     | As <= Unit.acts.keep{?tab><$curPanelTab}
  else if $curPanelTab >< bag then
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
| $site.act <= 0
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
  | TurnsLeft = Cool.0 + Cool.1 - Unit.site.turn
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
| $site.act <= Act
| $site.act_unit.init{Unit,Unit.serial}
| when HKI: $view.mice_click <= \leftup //FIXME: kludge

ui.create_act_icons =
| map I $maxUnitActIcons+$maxGroundActIcons:
  | hidden: icon 0: Icon => $actClickIcon{Icon}

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
| $menuBG <= $img{ui_menu_bg}
| $panelBG <= $img{ui_panel}
| $view <= view $main Me $width $height-($panelBG.h-10)
| $create{8 8}
| $message_box <= message_box Me
| $inputBlocker <= hidden: spacer $width $height
| $siteProperties <= $create_site_props
| Tabs = $create_dialog_tabs
| $tabs <= input_split Tabs: Base In => $process_input{Base In}
| $bankList.pick{0}
| $view.set_brush{0,0}
| $begin_ingame{1}

export ui