use gui widgets ui_icon ui_widgets

ui.update_act_icon I Act Count Unit =
| Icons = if I<0 then | I <= -(I+1); $groundActIcons 
          else $unitActIcons
| Active = 1
| Icon = Icons.I.widget
| ResearchRemain = Unit.owner.research_remain{Act}
| ActName = Act.name
| Icon.data <= ActName
| Icon.unit <= Unit
| Icon.fg <= Act.icon_gfx
| Icon.grayed <= 0
| Cool = Unit.cooldown_of{ActName}
| when Cool and Cool.1:
  | TurnsDone = Unit.site.turn - Cool.0
  | TurnsTotal = Cool.1
  | Icon.grayed <= 100-(TurnsDone*100)/TurnsTotal
| Number = if ResearchRemain <> 0 then ResearchRemain else No
| when got Count: Number <= Count
| Icon.text.init{[0 0 Number]}
| Frame = if ResearchRemain <> 0 then 'icon_fancy0' else 'icon_fancy1'
| Icon.frame.init{[3 3 icon_act]}
| Icon.w <= Icon.fg.w
| Icon.h <= Icon.fg.h
| Icon.hotkey <= Act.hotkey
| Icons.I.show <= Active

ui.update_panel_buttons Unit As GAs =
| As = As.take{min{$maxUnitActIcons As.size}}
| GAs = GAs.take{min{$maxGroundActIcons GAs.size}}
| Player = Unit.owner
| I = 0
| for Act [@As @GAs{[gact ?]}]:
  | Count = No
  | GAct = 0 //ground act
  | case Act [gact A]
    | GAct <= 1
    | Act <= A
  | when Act.is_list:
    | Count <= Act.0
    | Act <= Act.1
  | when Unit.can{Act} or Unit.owner.can_research{Act}:
    | $update_act_icon{(if GAct then -I-1 else I) Act Count Unit}
    | I += 1

ui.on_unit_pick Unit =
| for Icon $actIcons: Icon.show <= 0
| As = 0
| GAs = []
| Acts = $main.acts
| if Unit.has{menu} then
     | MenuActName,XYZ,TargetSerial = Unit.get{menu}
     | As <= if TargetSerial><research
             then [Acts.m_yes Acts.m_no]
             else Acts.MenuActName.menu
  else if $curPanelTab >< unit then
     | As <= if Unit.removed then []
             else [@Unit.acts.skip{?tab} @Unit.acts.keep{?tab}]
  else if $curPanelTab >< bag then
     | As <= map K,A Unit.items: [A Acts."drop_[K]"]
     | GAs <= map K,A Unit.cell.items: [A Acts."take_[K]"]
  else leave
| $update_panel_buttons{Unit As GAs}

unit.research_act Act =
| O = $owner
| Needs = O.lore-Act.lore
| when Needs < 0:
  | O.notify{"Not enough lore for `[Act.title]` (collect [-Needs])"}
  | leave
| O.notify{"Research this?"}
| $owner.picked <= Me
| $set{menu [Act.name $xyz research]}

ui.actClickIcon Icon =
| HKI = $hotKeyInvoke
| $hotKeyInvoke <= 0
| $site.act <= 0
| when $curActIcon: $curActIcon.picked <= 0
| $curActIcon <= Icon
| Unit = Icon.unit
| O = Unit.owner
| when $paused or O.id <> $player.id: leave
| ActName = Icon.data
| Act = $main.acts.ActName
| Cost = Act.cost
| ResearchRemain = Unit.owner.research_remain{Act}
| Cool = Unit.cooldown_of{ActName}
| when Cool:
  | TurnsLeft = Cool.0 + Cool.1 - Unit.site.turn
  | O.notify{"[Act.title] needs [TurnsLeft] turns to recharge"}
  | leave
| when ResearchRemain:
  | Unit.research_act{Act}
  | leave
| when got Cost and Cost>0 and Cost>O.mana:
  | O.notify{"[Act.title] needs [Cost-O.mana] more mana"}
  | leave
| when Unit.mov < Act.mov:
  | O.notify{"[Act.title] requires [Act.mov] moves."}
  | leave
| when Act.range >< 0:
  | $view.handle_picked_act2{Unit Act Unit.xyz Unit}
  | leave
| $site.act <= Act
| $site.act_unit.init{Unit,Unit.serial}
| $site.last_picked <= 0
| when HKI: $view.mice_click <= \leftup //FIXME: kludge

act_icon_infoline Icon =
| ActName = Icon.data
| Unit = Icon.unit
| less Unit: leave ''
| Act = Unit.main.acts.ActName
| when no Act: leave ''
| Info = Act.title
| Number = Icon.text.2
| Cool = Unit.cooldown_of{ActName}
| Cost = Act.cost
| if Cool then
    | Info <= "[Info] ([Cool.0+Cool.1-Unit.site.turn] TURNS TO RECHARGE)"
  else if not Unit.owner.researched{Act} then
    | Info <= "research [Info] ([Act.lore] LORE)"
  else when got Cost and Cost:
    | Info <= "[Info] ([Cost] MANA)"
| Info.upcase

ui.create_act_icons =
| map I $maxUnitActIcons+$maxGroundActIcons:
  | Icon = icon 0: Icon => $actClickIcon{Icon}
  | Icon.infoline_handler <= &act_icon_infoline
  | hidden Icon