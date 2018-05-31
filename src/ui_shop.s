use gui widgets ui_icon ui_widgets

//FIXME: move loan buttons here

BuyCost = 500
SellCost = 500
TotalCost = 0

shop_buy_infoline Icon =
| Act,UI = Icon.data
| Title = Act.title
| if Icon.picked then "Don't buy [Title]"
  else "Buy [Title] ([BuyCost] gold)"

shop_sell_infoline Icon =
| Act,UI = Icon.data
| Title = Act.title
| if Icon.picked then "Don't sell [Title]"
  else "Sell [Title] ([SellCost] gold)"

ui.shop_act_buy Icon =
| Act,UI = Icon.data
| Picked = Icon.picked
| if Picked then TotalCost -= BuyCost
  else
    | when $world.gold < TotalCost+BuyCost
      | $notify{"Not enough gold to purchase this spell."}
      | leave
    | TotalCost += BuyCost
| Icon.picked <= not Picked

ui.shop_act_sell Icon =
| Act,UI = Icon.data
| Picked = Icon.picked
| if Picked then
    | when $world.gold < TotalCost+SellCost
      | $notify{"Not enough gold to trade without this spell."}
      | leave
    | TotalCost += SellCost
  else
    | TotalCost -= SellCost
| Icon.picked <= not Picked

ui.create_shop_icons InfoFn PickedFn =
| Acts = $main.acts
| Spells = $cfg.leader.mage.spells
| Summons = $cfg.world.summons
| create_pick_icon ActName =
  | Act = Acts.ActName
  | when no Act: bad "missing act [ActName]"
  | Icon = icon 0 PickedFn
  | Icon.data <= [Act Me]
  | Icon.fg <= Act.icon_gfx
  | Icon.picked_overlay <= \icon_picked
  | Icon.infoline_handler <= InfoFn
  //| Icon.grayed <= 0
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

ui.create_shop_dlg =
| Icons,IconsLay =
    $create_shop_icons{&shop_buy_infoline
                       (Icon => $shop_act_buy{Icon})}
| Icons2,IconsLay2 =
    $create_shop_icons{&shop_sell_infoline
                       (Icon => $shop_act_sell{Icon})}
| $shopIcons <= Icons
| $shopIcons2 <= Icons2
| W = $width
| H = $height
| dlg w/$width h/$height: mtx
  |   0          0 | $img{ui_bookshelf}
  |   300        20| txt medium 'Buy Spells'
  |   16 $height-20| infoline
  |   0 $height-170| notification_widget Me
  |  52        52  | IconsLay
  | W/2-100    290 | txt medium 'Sell Spells'
  |  52        320 | IconsLay2
  | W/2-100   H-48 | txt medium | => "Gold: [$world.gold-TotalCost]"
  |  32        $height-48
     | button 'Back' skin/medium_small: => $pick{world}
  |  $width-128   $height-48
     | button 'Confirm' skin/medium_small: =>
       | $world.gold -= TotalCost
       | for Icon Icons: when Icon.picked:
         | Act = Icon.data.0
         | Act.researched <= 1
       | for Icon Icons2: when Icon.picked:
         | Act = Icon.data.0
         | Act.researched <= 0
       |  $pick{world}

ui.enter_shop =
| TotalCost <= 0
| BuyCost <= $cfg.world.spell_buy_cost
| SellCost <= $cfg.world.spell_sell_cost
| SavedSeed = lcg_get
| lcg_set $world.turn_seed
| Icons = $shopIcons
| Icons2 = $shopIcons2
| for Icon Icons2
  | Act = Icon.data.0
  | Icon.picked <= 0
  | Icon.hidden <= not Act.researched
| for Icon Icons
  | Act = Icon.data.0
  | Icon.picked <= 0
  | Icon.hidden <= 1
| for Icon Icons.shuffle.take{max{1 Icons.size/4}}
  | Act = Icon.data.0
  | Icon.hidden <= Act.researched
| lcg_set SavedSeed
| $pick{shop}


