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
| $site.data.serial <= if $enterSiteDst then $enterSiteDst.serial else 0
| Ls = []
| for U $site.units: less U.removed:
  | when U.type><trigger_landing: push U.xyz Ls
| $site.new_game
| Acts = $main.acts
| for Name,Act Acts:
  | $site.human.enable{Act Act.researched}
| Ls = Ls.shuffle
| for Act $enterSiteIcons1{}{?data}:
   when Act.picked>0 and Act.tab><summon: less Ls.end:
  | Type = Act.name
  | times I Act.picked:
    | XYZ = pop Ls
    | S = $site.human.alloc_unit{Type}
    | S.aistate <= \spawned
    | S.move{XYZ}
| $begin_ingame{0}
| $unpause
| $pick{ingame}

enter_site_pick_infoline Icon =
| Act = Icon.data
| Title = Act.title
| "Pick [Title]"

enter_site_unpick_infoline Icon =
| Act = Icon.data
| Title = Act.title
| "Unpick [Title]"

ui.enter_site_picked Icon =
| Act = Icon.data
| Avail = Icon.text.2
| less Avail>0:
  | $notify{"Not available"}
  | leave
| when Act.tab><summon:
  | NUnits = 0
  | MaxUnits = $cfg.world.max_units
  | for Icon $enterSiteIcons2
    | A = Icon.data
    | when A.tab><summon: NUnits += A.picked
  | less NUnits < MaxUnits:
    | $notify{"Unit limit reached."}
    | leave
| Act.picked += 1
| Icon.text.2 <= Avail-1
| less Icon.text.2: Icon.hidden <= 1
| for Icon $enterSiteIcons2:
  | A = Icon.data
  | when A.name >< Act.name
    | Icon.text.2 <= Act.picked
    | Icon.hidden <= 0

ui.enter_site_unpicked Icon =
| Act = Icon.data
| Avail = Icon.text.2
| less Avail>0:
  | $notify{"can't decrease it any more"}
  | leave
| Act.picked -= 1
| Icon.text.2 <= Avail-1
| less Icon.text.2: Icon.hidden <= 1
| for Icon $enterSiteIcons1:
  | A = Icon.data
  | when A.name >< Act.name
    | Icon.text.2 += 1
    | Icon.hidden <= 0

ui.create_enter_site_icons InfoFn PickedFn =
| Acts = $main.acts
| Spells = $cfg.leader.mage.spells
| Summons = $cfg.world.setup_summons
| create_pick_icon ActName =
  | Act = Acts.ActName
  | when no Act: bad "missing act [ActName]"
  | Icon = icon 0 PickedFn
  | Icon.data <= Act
  | Icon.fg <= Act.icon_gfx
  | Icon.infoline_handler <= InfoFn
  | Icon
| SpellIcons = map ActName Spells: create_pick_icon ActName
| SummonIcons = map ActName Summons: create_pick_icon ActName
| Icons = [@SpellIcons @SummonIcons]
| IconsPerLine = 12
| SpellsLay = map Group SpellIcons.group{IconsPerLine}
              | layH s/8 Group
| SummonsLay = map Group SummonIcons.group{IconsPerLine}
               | layH s/8 Group
| IconsLay = layV s/14 [@SpellsLay @SummonsLay]
| Icons,IconsLay

ui.create_enter_site_dlg =
| Icons,IconsLay =
     $create_enter_site_icons{&enter_site_pick_infoline
                              (Icon => $enter_site_picked{Icon})}
| Icons2,IconsLay2 =
     $create_enter_site_icons{&enter_site_unpick_infoline
                              (Icon => $enter_site_unpicked{Icon})}
| $enterSiteIcons1 <= Icons
| $enterSiteIcons2 <= Icons2
| W = $width
| H = $height
| dlg w/W h/H: mtx
  |   0          0 | $img{ui_bookshelf}
  | W/2-100     20 | txt medium 'Available Spells'
  |   16      H-20 | infoline
  |   0         40 | notification_widget Me
  |  52         52 | IconsLay
  | W/2-100    290 | txt medium 'Picked Spells'
  |  52        320 | IconsLay2
  | W/2-100   H-48 | txt medium | => "Gold: [$world.gold]"
  |  32        H-48
     | button 'Back' skin/medium_small: => $pick{world}
  |  $width-128   H-48
     | button 'Proceed' skin/medium_small: =>
       | $enter_site_proceed

ui.enter_site Site =
| GUI = get_gui{}
| when got GUI: GUI.cursor <= $img{ui_cursor_point}
| when Site: $enterSiteDst <= Site
| for Icon $enterSiteIcons1:
  | Act = Icon.data
  | Icon.text.2 <= Act.maxPicks
  | Icon.hidden <= not Act.researched
| for Icon $enterSiteIcons2:
  | Act = Icon.data
  | Icon.text.2 <= 0
  | Icon.hidden <= 1
| $pick{enter_site}
