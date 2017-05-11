use macros unit_flags util

SeenUnits = 0
OwnedUnits = 0
SeenEnemies = 0
PerCycle = 0

unit.can_do Act =
| when $owner.research_remain{Act}: leave 0
| when $owner.mana < Act.cost: leave 0
| when $cooldown_of{Act.name}: leave 0
| 1

PerTurn = 0

unit.`=backtrack` XYZ =
| less XYZ:
  | $strip_effect{btrack}
  | leave
| when $has{btrack}: leave
| $add_effect{btrack 0 XYZ}

path_around_busy_units Me XYZ = //Me is unit
| Target = $world.cell{@XYZ}
| check Dst =
  | if Dst><Target then 1
    else if Dst.block then \block
    else 0
| Found = $pathfind{10 &check}
| if Found then Found.path else []

unit.advance_to GoalXYZ =
| when $xyz >< GoalXYZ: leave 1
| Path = $path_to{GoalXYZ}
| less Path.size: leave 2
| Moves = map C $reachable: C.1
| Cell = No
| while Path.size and got Moves.find{Path.0}: Cell <= pop Path
| when no Cell:
  | Path = $path_around_to{10 GoalXYZ}
  | while Path.size and got Moves.find{Path.0}: Cell <= pop Path
  | when no Cell: leave 2
| B = Cell.block
| when B and not B.handled and not $is_enemy{B}:
  | less $handled:
    | $handled <= \wait //try to avoid swapping
    | leave 0
  | B.backtrack <= B.xyz
| $order_at{Cell.xyz}
| 0

cast_pentagram Me =
| case $acts.keep{?hint >< pentagram} [Act@_]
  | less $can_do{Act}: leave 0
  | $order_act{Act}
  | leave 1
| leave 0

cast_spell Me =
| Acts = $acts
| less Acts.size: leave 0
| PP = $owner.params
| when $leader:
  | Pentagram = $owner.pentagram
  | less Pentagram: // attacking enemies could give better results
    | when cast_pentagram Me: leave 1
| 0

ai_update_unit Me =
| when cast_spell Me: leave break
| when $combat:
  | Cs = $reachable
  | case Cs.keep{?0><attack} [[Type Cell]@_]:
    | $backtrack <= $xyz
    | $order_at{Cell.xyz}
    | $handled <= 1
    | leave break
  | when $steps:
    | Es = $units_in_range{$sight}.keep{X=>$is_enemy{X}}
    | Flt = Cs{[?1 1]}.table //filtering table
    | Es = Es.skip{E=>Flt.(E.cell)><1}
    | Es = Es.keep{E => $path_to{E.xyz}.size<10}
    | case Es [E@_]:
      | $backtrack <= $xyz
      | $advance_to{E.xyz}
      | leave break
| less $attacker:
  | BtXYZ = $get_effect_value{btrack}
  | when BtXYZ and $advance_to{BtXYZ}: $backtrack <= 0
| $handled <= 1
| \next

ai_update_units Me =
| Pentagram = $player.pentagram
| Leader = $player.leader
| for U OwnedUnits: less U.handled:
  | R = ai_update_unit U
  | when R >< break: leave 0
| for U OwnedUnits: when U.handled><wait:
  | R = ai_update_unit U
  | when R >< break: leave 0
| when Pentagram:
  | B = Pentagram.cell.block
  | when B and B.steps and B.owner.id><$player.id:
    | Cs = B.reachable.keep{?0><move}
    | case Cs [[Type Cell]@_]:
      | B.order_at{Cell.xyz} //move unit out of pentagram
      | leave 0
//| when Pentagram and Leader and Leader.ap: ai_update_build Me
| 1 //return true, meaning that we have handled all units

ai_update_turn Me =
| when $player.params.attack_with_guards >< 1:
  | for U OwnedUnits: U.attacker <= 1
  | $player.params.attack_with_guards <= 0
| when ai_update_units Me:
  | $world.end_turn

ai.update =
| PerTurn <= t
| Player = $player
| SeenUnits <= $world.active.list.keep{U=>Player.seen{U.xyz}}
                     .keep{(?unit and not ?removed)}
| PID = Player.id
| OwnedUnits <= SeenUnits.keep{?owner.id><PID}
| SeenEnemies <= SeenUnits.keep{?owner.is_enemy{Player}}.skip{?invisible}
| ai_update_turn Me
| SeenUnits <= 0
| OwnedUnits <= 0
| SeenEnemies <= 0
| PerTurn <= 0

export
