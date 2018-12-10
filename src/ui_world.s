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
| BX = $width-444
| BP = icon world_flag: Icon => $world.base_placement
| Shop = icon world_shop: Icon => $enter_shop
| ET = icon tab_endturn: Icon => $world.end_turn
| EX = icon menu_exit: Icon => $pick_title_menu
| Borrow = icon world_borrow: Icon => $world.borrow
| Repay = icon world_repay: Icon => $world.repay
| WorldButtons = layH s/26 [BP Shop Borrow Repay ET EX]
| dlg w/$width h/$height: mtx
  |   0           0| $world
  |   0 $height-20 | infoline
  |   0 $height-170| notification_widget Me
  |  4         BY  | $create_worldSiteTabs 
  |  BX        BY  | WorldButtons


ui.generate W H Blueprint =
| $site.generate{W H Blueprint}
| $view.clear


ui.place_site_player =
| Ls = []
| LeaderXYZ = 0
| for U $site.units: less U.removed: when U.owner.id >< 1:
  | when U.type><trigger_spawn_patrol: push U.xyz Ls
  | when U.type><trigger_spawn_leader: LeaderXYZ <= U.xyz
| $site.new_game
| Acts = $main.acts
| for Name,Act Acts:
  | Act.picks.($site.human.id) <= Act.picked
  | $site.human.enable{Act Act.researched}
| Ls = Ls.shuffle
| for Act $enterSiteIcons1{}{?data}:
  | when Act.picked>0 and Act.tab><summon: less Ls.end:
    | Type = Act.name
    | times I Act.picked:
      | XYZ = pop Ls
      | S = $site.human.alloc_unit{Type}
      | S.aistate <= \spawned
      | S.move{XYZ}
| when LeaderXYZ:
  | S = $site.human.alloc_unit{leader_mage}
  | S.aistate <= \spawned
  | S.move{LeaderXYZ}
      
ui.place_site_enemy =
| Budget = max 400 ($world.site_gold*3+3)/4
| Units = []
| Spells = []
| for Icon $enterSiteIcons1:
  | Act = Icon.data
  | if Act.tab><summon then push Act Units
    else push Act Spells
| Total = 0
| Us = Units.shuffle
| Picked = []
| for U Us: when U.gold<<100 or (Budget-Total)/max{1 U.gold}>5:
  | Count = max 1 $world.rand{U.maxPicks}
  | times I Count: when Total+U.gold << Budget:
    | Total += U.gold
    | push U Picked
| Patrol = []
| Guards = []
| RGuards = []
| Player = $site.players.5 //for now we use hardcoded player 5 for enemy
| LeaderXYZ = 0
| for U $site.units: less U.removed: when U.owner.id >< 5:
  | when U.type><trigger_spawn_leader: LeaderXYZ <= U.xyz
  | when U.type><trigger_spawn_patrol:
    | push U.xyz.copy Patrol
    | U.free
  | when U.type><trigger_spawn_guard:
    | push U.xyz.copy Guards
    | U.free
  | when U.type><trigger_spawn_ranged:
    | push U.xyz.copy RGuards
    | U.free
| when LeaderXYZ:
  | S = Player.alloc_unit{leader_heretic}
  | S.aistate <= \spawned
  | S.move{LeaderXYZ}
| SBudget = max 100 ($world.site_gold+3)/4
| STotal = 0
| for S Spells: S.picks.(Player.id) <= 0
| Ss = Spells.shuffle
| for S Ss: when S.gold<<100 or (SBudget-STotal)/max{1 S.gold}>5:
  | Count = max 1 $world.rand{S.maxPicks}
  | times I Count: when STotal+S.gold << SBudget:
    | STotal += S.gold
    | S.picks.(Player.id) += 1
| Picked <= Picked{?name}.shuffle
| RTs = [unit_blob unit_goblin unit_elf unit_vampire unit_observer]
| Rs = Picked.keep{U => RTs.has{U}}
| Ms = Picked.skip{U => RTs.has{U}}
| RSz = min RGuards.size Rs.size
| RGuards <= RGuards.shuffle
| Ps = [@RGuards.take{RSz}
        @Guards.shuffle
        @RGuards.drop{RSz}
        @Patrol.shuffle]
| for Type [@Rs @Ms]: less Ps.end:
  | XYZ = pop Ps
  | S = Player.alloc_unit{Type}
  | S.aistate <= if Patrol.has{XYZ} then \patrol else \guard
  | S.move{XYZ}

ui.enter_site_proceed =
| Site = $enterSiteDst
| Type = if not Site then \city
         else if Site and Site.type><city then \city
         else \forest
| $generate{6 6 Type}
| $site.data.serial <= if Site then Site.serial else 0
| $place_site_player
| $place_site_enemy
| $begin_ingame{0}

ui.enter_site_back =
| $world.gold <= $world.site_gold
| $pick{world}

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
| when $world.gold < Act.gold:
  | $notify{"[Act.gold] gold needed"}
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
| $world.gold -= Act.gold
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
| $world.gold += Act.gold
| Icon.text.2 <= Avail-1
| less Icon.text.2: Icon.hidden <= 1
| for Icon $enterSiteIcons1:
  | A = Icon.data
  | when A.name >< Act.name
    | Icon.text.2 += 1
    | Icon.hidden <= 0

ui.create_enter_site_icons InfoFn PickedFn =
| Acts = $main.acts
| Spells = $cfg.world.spells
| Summons = $cfg.world.summons
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
  | W/2-100     20 | txt titleb 'Available Spells'
  |   16      H-20 | infoline
  |   0         40 | notification_widget Me
  |  52         52 | IconsLay
  | W/2-100    290 | txt titleb 'Picked Spells'
  |  52        320 | IconsLay2
  | W/2-100   H-48 | txt titleb | => "Gold: [$world.gold]"
  |  32        H-48
     | button 'Back' skin/medium_small: =>
       | $enter_site_back
  |  $width-128   H-48
     | button 'Proceed' skin/medium_small: =>
       | $enter_site_proceed

ui.enter_site Site =
| GUI = get_gui{}
| when got GUI: GUI.cursor <= $img{ui_cursor_point}
| when Site: $enterSiteDst <= Site
| $world.site_gold <= $world.gold
| Seed = $world.seed
| $world.seed <= $world.turn_seed
| for Icon $enterSiteIcons1:
  | Act = Icon.data
  | Act.picked <= 0
  | Icon.text.2 <= 3
  //| less Site: Act.researched <= 0
  /*| times I Act.maxPicks: when $world.rand{100} < Act.pickChance:
    | Icon.text.2 += 1*/
  | Icon.hidden <= not Act.researched
| $world.seed <= Seed
| for Icon $enterSiteIcons2:
  | Act = Icon.data
  | Act.picked <= 0
  | Icon.text.2 <= 0
  | Icon.hidden <= 1
| $pick{enter_site}
