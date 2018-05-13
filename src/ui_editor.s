use gui widgets ui_icon ui_widgets

ui.create_bank_list =
| TileBanks = $cfg.site.tile_banks
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



parse_int_normalized Default Text =
| if Text.size>0 and Text.all{?is_digit} then Text.int else Default

ui.create_site_props_dlg = 
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
  | $site.editor <= 1
  | Site.paused <= 1
  | Site.explore{1}
  | hideDlg
| Dlg <= hidden: DlgW
| Dlg



ui.create_play_button =
| Icon = icon tab_play: Icon =>
  | $site.new_game
  | $unpause
| Icon.picked_fg <= $img{icons_tab_pause}
| hidden Icon

