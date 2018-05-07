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

ui.enter_site_proceed =
| $generate{6 6 forest}
| $site.data.serial <= $enterSiteDst.serial
| $site.new_game
| Acts = $main.acts
| for Name,Act Acts:
  | $site.human.enable{Act Act.researched}
| $begin_ingame{0}
| $unpause
| $pick{ingame}

enter_site_pick_infoline Icon =
| Act = Icon.data
| Title = Act.title
| "Pick [Title]"

ui.enter_site_picked Icon =
| Act = Icon.data
| Avail = Icon.text.2
| less Avail>0:
  | $notify{"Not available"}
  | leave
| Act.picked += 1
| Icon.text.2 <= Avail-1

ui.create_enter_site_dlg =
| Acts = $main.acts
| Spells = $cfg.leader.mage.spells
| Summons = $cfg.world.setup_summons
| create_pick_icon ActName =
  | Act = Acts.ActName
  | Icon = icon 0: Icon => $enter_site_picked{Icon}
  | Icon.data <= Act
  | Icon.fg <= Act.icon_gfx
  | Icon.picked_overlay <= \icon_hl
  | Icon.infoline_handler <= &enter_site_pick_infoline
  | Icon
| SpellIcons = map ActName Spells: create_pick_icon ActName
| SummonIcons = map ActName Summons: create_pick_icon ActName
| Icons = [@SpellIcons @SummonIcons]
| $enterSiteIcons1 <= Icons
| IconsPerLine = 12
| SpellsLay = map Group SpellIcons.group{IconsPerLine}
              | layH s/8 Group
| SummonsLay = map Group SummonIcons.group{IconsPerLine}
               | layH s/8 Group
| IconsLay = layV s/14 [@SpellsLay @SummonsLay]
| dlg w/$width h/$height: mtx
  |   0          0 | $img{ui_bookshelf}
  |   300        20| txt medium 'Available Spells'
  |   16 $height-20| infoline
  |   0         40 | notification_widget Me
  |  52        52  | IconsLay
  |   300     290  | txt medium 'Picked Spells'
  |  52       320  | IconsLay
  |  32        $height-48
     | button 'Back' skin/medium_small: => $pick{world}
  |  $width-128   $height-48
     | button 'Proceed' skin/medium_small: =>
       | for Act Icons{?data}: when Act.picked>0:
         | say [Act.name Act.picked]
       //| $enter_site_proceed

ui.enter_site Site =
| GUI = get_gui{}
| when got GUI: GUI.cursor <= $img{ui_cursor_point}
| when Site: $enterSiteDst <= Site
| for Icon $enterSiteIcons1:
  | Act = Icon.data
  | Icon.text.2 <= Act.maxPicks
  | Act.picked <= 0
| $pick{enter_site}