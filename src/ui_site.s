use gui widgets ui_icon ui_widgets ui_minimap

ui.load File =
| $main.load{File}
| $view.clear
ui.save File = $main.save{File}
ui.pause =
| $paused <= 1
| $inputBlocker.show <= 1
ui.unpause =
| $paused <= 0
| $inputBlocker.show <= 0

ui.create W H =
| $site.create{W H 4 soil}
| $view.clear

ui.begin_ingame Editor =
| $main.music{playlist}
| $site.editor <= Editor
| for W $editorWidgets: W.show <= Editor
| $unpause
| $pick{ingame}

ui.load_game NewGame Path =
| $load{Path}
| when NewGame: $site.new_game
| $begin_ingame{0}

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

ui.create_panel_tabs =
| $actIcons <= $create_act_icons
| $unitActIcons <= $actIcons.take{$maxUnitActIcons}
| ActIconsLay = layV s/14
                     layH{s/8 $unitActIcons.drop{$unitActIcons.size/2}}
                    ,layH{s/8 $unitActIcons.take{$unitActIcons.size/2}}
| $panelTabs <= tabs $curPanelTab: t
          unit    | ActIconsLay
          brush   | $create_panel_tab_brush
          confirm | $create_panel_tab_confirm
| $panelTabs


ui.panel_tab_picked TabName = 
| when got@@it $panelTabsDeselect.$curPanelTab: (it){$curPanelTab TabName}
| when got@@it $panelTabsSelect.TabName: (it){$curPanelTab TabName}
| Ms = $panelTabsMore.$curPanelTab
| when got Ms: for M Ms: M.show <= 0
| $curPanelTab <= TabName
| Ms = $panelTabsMore.$curPanelTab
| when got Ms: for M Ms: M.show <= 1
| $panelTabs.pick{TabName}

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
  | $confirm{"Leave this site?"
     |$0 yes =>
       | $pick_world
       | $world.leave_site{retreat}}
| SaveIcon,LoadIcon,SiteIcon,ExitIcon,LeaveIcon


ui.create_panel_tabs_header =
| PlayButton = $create_play_button
| push PlayButton $editorWidgets
| EndTurnButton = icon tab_endturn: Icon => $site.end_turn
| SaveIcon,LoadIcon,SiteIcon,ExitIcon,LeaveIcon = $create_panel_tab_menu
| layH s/8 [PlayButton SaveIcon LoadIcon SiteIcon
            ExitIcon LeaveIcon
            spacer{120 0} EndTurnButton]

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
  | 4   $height-124 | minimap $main | X Y => $view.center_at{[X Y 0]}
  | 0   PY          | $playerWidget


ui.process_ingame_input Base In =
| when $paused: leave 
| Base.input{In}
| case In [key Key 1]
  | for Icon $actIcons: when Icon.show: when Icon.hotkey><Key:
    | $hotKeyInvoke <= 1
    | Icon.on_click{}{Icon}
    | leave
| case In [key Key 0]
  | $view.input{In}

ui.create_ingame_dlg =
| $saveSiteDlg <= $create_save_site_dlg
| $loadSiteDlg <= $create_load_site_dlg
| Ingame = dlg w/$width h/$height: mtx
  |  0   0| spacer $width $height
  |  0   0| input_split $create_ingame_ui: Base In =>
            | $process_ingame_input{Base In}
  |  0   0| $inputBlocker
  |170 100| $siteProperties
  |170 100| $loadSiteDlg
  |170 100| $saveSiteDlg
  |  0   0| $message_box
| Ingame

ui.update = //called by site.update each game cycle
| when got $site.data.winner:
  | $pause
  | $show_results
  | leave
