use gui widgets ui_icon ui_widgets

//stuff related to setting up new campaign game goes here

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

setup_icon_infoline Icon =
| Act,UI = Icon.data
| Title = Act.title
| if Icon.picked then "Unpick [Title]" else "Pick [Title]"

ui.setup_act_picked Icon =
| Act,UI = Icon.data
| Picked = Icon.picked
| CountName,LimName = if Act.tab >< summon
    then summons_count,start_summons
    else spells_count,start_spells
| Count = $cfg.world.CountName
| less Picked:
  | Lim = $cfg.world.LimName
  | less Count < Lim:
    | $notify{"Can't pick more than [Lim] [LimName.drop{6}]"}
    | leave
  | $cfg.world.CountName <= Count+1
| when Picked:
  | $cfg.world.CountName <= Count-1
| Icon.picked <= not Picked

ui.create_new_game_setup_dlg =
| Acts = $main.acts
| Spells = $cfg.leader.mage.spells
| Summons = $cfg.world.setup_summons
| create_pick_icon ActName =
  | Act = Acts.ActName
  | when no Act: bad "missing act [ActName]"
  | Icon = icon 0: Icon => $setup_act_picked{Icon}
  | Icon.data <= [Act Me]
  | Icon.fg <= Act.icon_gfx
  | Icon.picked_overlay <= \icon_hl
  | Icon.infoline_handler <= &setup_icon_infoline
  //| Icon.grayed <= 0
  | Icon
| SpellIcons = map ActName Spells: create_pick_icon ActName
| SummonIcons = map ActName Summons: create_pick_icon ActName
| Icons = [@SpellIcons @SummonIcons]
| $setupIcons <= Icons
| IconsPerLine = 12
| SpellsLay = map Group SpellIcons.group{IconsPerLine}
              | layH s/8 Group
| SummonsLay = map Group SummonIcons.group{IconsPerLine}
               | layH s/8 Group
| IconsLay = layV s/14 [@SpellsLay @SummonsLay]
| dlg w/$width h/$height: mtx
  |   0          0 | $img{ui_bookshelf}
  |   300        20| txt medium 'Pick Starting Spells'
  |   16 $height-20| infoline
  |   0 $height-170| notification_widget Me
  |  52        52  | IconsLay
  |  32        $height-48
     | button 'Back' skin/medium_small: => $pick{main_menu}
  |  $width-128   $height-48
     | button 'Proceed' skin/medium_small: =>
       | for Icon Icons: when Icon.picked:
         | Act = Icon.data.0
         | Act.researched <= 1
       | $world.clear
       | $pick_world

ui.pick_new_game =
| $cfg.world.summons_count <= 0
| $cfg.world.spells_count <= 0
| DP = $cfg.world.default_picks
| for Icon $setupIcons
  | Act = Icon.data.0
  | Icon.picked <= 0
  | Act.researched <= 0
  | when DP.has{Act.name}: $setup_act_picked{Icon}
| $pick{new_game_setup}


ui.create_scenario_menu =
| loadScenarioBack = $pick{new_game_menu}
| LoadScenarioDlg = load_dlg $site $mapsFolder &loadScenarioBack: X =>
  | $load_game{1 X}
| dlg: mtx
  |   0   0 | $menuBG
  |  220 200 | LoadScenarioDlg
  |  16 $height-16 | $copyrightText

ui.create_load_menu_dlg =
| loadScenarioBack = $pick{main_menu}
| LoadScenarioDlg = load_dlg $site $savesFolder &loadScenarioBack: X =>
  | $load_game{0 X}
  | $site.paused <= 0
| dlg: mtx
  |   0   0 | $menuBG
  |  220 200 | LoadScenarioDlg
  |  16 $height-16 | $copyrightText
