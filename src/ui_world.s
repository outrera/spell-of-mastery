use gui widgets ui_icon ui_widgets world

ui.create_world_base_tab =
| icon world_airship: Icon => $world.airship_targeting

ui.create_worldSiteTabs =
| $worldSiteTabs <= tabs none: t
    none | spacer 0 0
    base | $create_world_base_tab
| $worldSiteTabs

ui.site_picked S =
| Type = S.type
| if got $worldSiteTabs.table.Type then $worldSiteTabs.pick{Type}
  else $worldSiteTabs.pick{none}

ui.create_world_dlg =
| $world <= world $main Me $width $height
| BY = $height-64
| BX = $width-220
| BP = icon world_flag: Icon => $world.base_placement
| ET = icon tab_endturn: Icon => $world.end_turn
| EX = icon menu_exit: Icon => $pick_title_menu
| WorldButtons = layH s/4 [BP spacer{22 0} ET spacer{22 0} EX]
| dlg w/$width h/$height: mtx
  |   0           0| $world
  |   0 $height-20 | infoline
  |   0 $height-170| notification_widget Me
  |  4         BY  | $create_worldSiteTabs 
  |  BX        BY  | WorldButtons


ui.generate W H Blueprint =
| $site.generate{W H Blueprint}
| $view.clear

ui.enter_site Site =
| $generate{6 6 forest}
| $site.data.serial <= Site.serial
| $site.new_game
| Acts = $main.acts
| for Name,Act Acts:
  | $site.human.enable{Act Act.researched}
| $begin_ingame{0}
| $unpause
| $pick{ingame}
