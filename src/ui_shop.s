use gui widgets ui_icon ui_widgets

SpellCost = 500

shop_icon_infoline Icon =
| Act,UI = Icon.data
| Title = Act.title
| if Icon.picked then "Unpick [Title]"
  else "Buy [Title] ([SpellCost] gold)"

ui.shop_act_picked Icon =
| Act,UI = Icon.data
| Picked = Icon.picked
| Icon.picked <= not Picked

ui.create_shop_dlg =
| Acts = $main.acts
| Spells = $cfg.leader.mage.spells
| Summons = $cfg.world.setup_summons
| create_pick_icon ActName =
  | Act = Acts.ActName
  | when no Act: bad "missing act [ActName]"
  | Icon = icon 0: Icon => $shop_act_picked{Icon}
  | Icon.data <= [Act Me]
  | Icon.fg <= Act.icon_gfx
  | Icon.picked_overlay <= \icon_hl
  | Icon.infoline_handler <= &shop_icon_infoline
  //| Icon.grayed <= 0
  | Icon
| SpellIcons = map ActName Spells: create_pick_icon ActName
| SummonIcons = map ActName Summons: create_pick_icon ActName
| Icons = [@SpellIcons @SummonIcons]
| $shopIcons <= Icons
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
  |   0 $height-170| notification_widget Me
  |  52        52  | IconsLay
  |  32        $height-48
     | button 'Back' skin/medium_small: => $pick{world}
  |  $width-128   $height-48
     | button 'Confirm' skin/medium_small: =>
       | for Icon Icons: when Icon.picked:
         | Act = Icon.data.0
         | Act.researched <= 1
       |  $pick{world}

ui.enter_shop =
| //FIXME randomly generate spells available for the current turn

