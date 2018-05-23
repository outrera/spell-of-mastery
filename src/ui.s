use gui widgets view ui_icon ui_widgets macros

type ui.$tabs{main}
  tabs
  width
  height
  site
  message_box
  creditsRoll
  view
  paused
  mapsFolder/"parts/"
  savesFolder/"work/saves/"
  world
  worldSiteTabs
  confirmFn //callaback for yes/no confirmation
  panelTabs
  panelTabsMore/(t) //sparse element related to picked tab
  panelTabsSelect/(t)
  panelTabsDeselect/(t)
  panelBG
  curPanelTab/unit
  actIcons/[]
  maxUnitActIcons/24
  curActIcon/0
  unitActIcons/[]
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
  setupIcons
  enterSiteDst
  enterSiteIcons1
  enterSiteIcons2
| $site <= $main.site
| Prm = $cfg.ui
| $width <= Prm.width
| $height <= Prm.height
| $noteLife <= Prm.note_life
| NoteSize = Prm.note_size
| $notes <= dup Prm.max_notes: [0.0 (dup NoteSize ``)]
| $menuButtonsX <= $width/2 - 162

ui.player = $site.human
ui.data = $main.data
ui.cfg = $main.cfg
ui.img File = $main.img{File}

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

ui.process_input Base In =
| Base.input{In}
| when $inputBlocker.show: leave 
| case In [key Key 1]
  | for Icon $actIcons: when Icon.show: when Icon.hotkey><Key:
    | $hotKeyInvoke <= 1
    | Icon.on_click{}{Icon}

ui.pick_title_menu pause/1 =
| when Pause: $pause
| $main.music{"title.ogg"}
| $pick{main_menu}

ui.pick_world pause/1 =
| when Pause: $pause
| $main.music{"title.ogg"}
| $pick{world}

ui.create_main_menu_dlg =
| X = $menuButtonsX
| dlg: mtx
  |   0   0 | $menuBG
  |  16 $height-16 | $copyrightText
  | X 220 | button 'NEW GAME' skin/scroll: => $pick_new_game
                                              //$pick{new_game_menu}
  | X 290 | button 'LOAD GAME' skin/scroll: => $pick{load_menu}
  //| X 360 | button 'WORLD EDITOR' skin/scroll: =>
  //          | $create{8 8}
  //          | $begin_ingame{1}
  | X 500 | button 'EXIT' skin/scroll: => get_gui{}.exit
  |  $width-80 $height-20
     | button 'Credits' skin/small_medium: =>
       | $main.music{"credits.ogg"}
       | $creditsRoll.reset
       | $pick{credits}

ui.create_credits_dlg =
| $creditsRoll <= credits_roll Me $main.credits
| dlg: mtx
  |  0   0 | $img{ui_stars}
  |  0   0 | $creditsRoll
  |  $width-80 $height-20
     | button 'Exit' skin/small_medium: => $pick_title_menu{pause/0}

ui.create_dialog_tabs StartTab =
| $copyrightText <= txt small 'Spell of Mastery v0.4; Copyright (c) 2016-2018 Nikita Sadkov'
| IsDebug = $cfg.ui.debug><1
| tabs StartTab: t
          main_menu($create_main_menu_dlg)
          new_game_setup($create_new_game_setup_dlg)
          //new_game_menu($create_new_game_dlg)
          scenario_menu($create_scenario_menu)
          load_menu($create_load_menu_dlg)
          ingame($create_ingame_dlg)
          victory($create_victory_dlg)
          defeat($create_defeat_dlg)
          credits($create_credits_dlg)
          world($create_world_dlg)
          enter_site($create_enter_site_dlg)

ui.init =
| $mapsFolder <= "[$data][$mapsFolder]"
| $savesFolder <= "[$data][$savesFolder]"
| StartInEditor = $cfg.ui.start_in_editor><1
| $menuBG <= $img{ui_menu_bg}
| $panelBG <= $img{ui_panel}
| $view <= view $main Me $width $height-($panelBG.h-10)
| when StartInEditor: $create{10 10}
| less StartInEditor: $generate{6 6 forest}
| $message_box <= message_box Me
| $inputBlocker <= hidden: spacer $width $height
| $siteProperties <= $create_site_props_dlg
| Tabs = $create_dialog_tabs{enter_site}
| $tabs <= input_split Tabs: Base In => $process_input{Base In}
| $bankList.pick{0}
| $view.set_brush{0,0}
| less StartInEditor: $enter_site{0}
| when StartInEditor: $begin_ingame{1}

export ui