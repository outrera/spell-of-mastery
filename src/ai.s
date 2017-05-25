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
  | less Pentagram: when cast_pentagram Me: leave 1
| 0

ai_leader_harmed Me Attacker Victim =

ai.harm Attacker Victim =
| when Victim.leader><1: ai_leader_harmed Me Attacker Victim

roam Me =
| World = $world
| Owner = $owner
| OId = Owner.id
| Us = World.units_get{$xyz}
| when got Us.find{?ai><hold} and no Us.find{?ai><unhold}: leave 0
| Check = Dst =>
  | MoveIn = 0
  | Vs = Dst.units
  | for V Vs
    | AI = V.ai
    | when AI:
      | Block = Dst.block
      | if AI><unit and Block and Owner.is_enemy{Block.owner}
           and not Block.invisible then
           | MoveIn <= 1
        else if AI><hold and not Block and no Vs.find{?ai><unhold}
           then MoveIn <= 1
        else if AI><pentagram and Owner.is_enemy{V.owner} then
           | when not Block or Owner.is_enemy{Block}: MoveIn <= 1
        else if AI><avoid then
           | MoveIn <= \block
           | _goto end
        else if AI><block then
           | MoveIn <= \block
           | MoveIn <= 0
           | _goto end
        else
  | _label end
  | MoveIn
| TargetNode = $pathfind{1000 Check}
| less TargetNode: leave 0
| TargetXYZ = TargetNode.xyz
| $backtrack <= 0
| $advance_to{TargetXYZ}
| leave 1

ai_update_unit Me =
| less $steps > 0:
  | $handled <= 1
  | leave 0
| when cast_spell Me: leave break
| when $combat:
  | Cs = $reachable
  | case Cs.keep{?0><attack} [[Type Cell]@_]:
    | Block = Cell.block
    | when Block and not Block.invisible:
      | $backtrack <= $xyz
      | $order_at{Cell.xyz}
      | $handled <= 1
      | leave break
  | when $steps:
    | Es = $units_in_range{$sight}.keep{X=>$is_enemy{X} and not X.invisible}
    | Flt = Cs{[?1 1]}.table //filtering table
    | Es = Es.skip{E => Flt.(E.cell)><1}
    | Es = Es.keep{E => $path_to{E.xyz}.size<10}
    | case Es [E@_]:
      | $backtrack <= $xyz
      | $advance_to{E.xyz}
      | leave break
| when $aistate <> roam:
  | BtXYZ = $get_effect_value{btrack}
  | when BtXYZ and $advance_to{BtXYZ}: $backtrack <= 0
| when $aistate >< roam and roam Me: leave break
| $handled <= 1
| \next

ai_get_clean_pentagram Me =
| Pentagram = $player.pentagram
| when Pentagram and not Pentagram.cell.block: leave Pentagram
| 0

ai_update_build Me =
| Leader = $player.leader
| less Leader: leave 0
| Pentagram = ai_get_clean_pentagram Me
| less Pentagram: leave 0
| Spawns = Pentagram.acts.keep{?after_table.spawn^got}
| less Spawns.size: leave 0
| Missing = PerCycle.missing_attackers
| less got Missing: leave
| for Type Missing:
  | S = Spawns.find{?after_table.spawn >< Type}
  | when got S and Pentagram.can_do{S}:
    | Pentagram.order_act{S}
    | leave 1
| 0

ai_clean_pentagram Me =
| Pentagram = $player.pentagram
| when Pentagram:
  | B = Pentagram.cell.block
  | when B and B.steps and B.owner.id><$player.id:
    | Cs = B.reachable.keep{?0><move}
    | case Cs [[Type Cell]@_]:
      | B.order_at{Cell.xyz} //move unit out of pentagram
      | leave 1
| 0

ai_update_units Me =
| when ai_update_build Me: leave 0
| for U OwnedUnits: less U.handled:
  | R = ai_update_unit U
  | when R >< break: leave 0
| for U OwnedUnits: when U.handled><wait:
  | R = ai_update_unit U //handle units with delayed movement
  | when R >< break: leave 0
| when ai_clean_pentagram Me: leave 0
| 1 //return true, meaning that we have handled all units

ai_group_roam Me Types =
| Units = $player.units
| UTs = Units.keep{?aistate><spawned}.div{?type}
| As = []
| Missing = []
| for T Types:
  if UTs.T^~{[]}.size then push UTs.T^pop As
  else push T Missing
| when Missing.size:
  | PerCycle.missing_attackers <= Missing.flip
  | leave 0
| PerCycle.missing_attackers <= No
| for A As: A.aistate <= \roam
| leave 1

ai.script =
| Player = $player
| PParams = Player.params
| Params = $main.params
| AIType = PParams.aiType
| AIStep = PParams.aiStep
| AISteps = Params.main.ai.AIType
| when PParams.aiWait > $world.turn: leave 0
| less got AISteps
  | $world.notify{"AI: missing type `[AIType]`"}
  | leave 0
| AISteps = AISteps.tail
| less AIStep<AISteps.size:
  | AIStep <= 0
  | PParams.aiStep <= 0
| Command = AISteps.AIStep
| case Command
  [roam @Types]
    | less ai_group_roam Me Types{"unit_[?]"}: leave 0
    | PParams.aiStep++
  [goto NewAIType when @Condition]
    | if case Condition [[`>>` lossage X]]
              Player.params.lossage+PParams.difficulty*2>>X
      then | PParams.aiType <= NewAIType
           | PParams.aiStep <= 0
      else | PParams.aiStep++
  [goto NewAIType]
    | PParams.aiType <= NewAIType
    | PParams.aiStep <= 0
  [wait Turns]
    | PParams.aiWait <= $world.turn+Turns
    | PParams.aiStep++
  [set Var Value]
    | PParams.Var <= Value
    | PParams.aiStep++
  Else
    | bad 'invalid AI command: [Command]'
| leave 1

ai_update_turn Me =
| when $player.params.attack_with_guards >< 1:
  | for U OwnedUnits: U.aistate <= \roam
  | $player.params.attack_with_guards <= 0
| when $player.id: while $script><1: //FIXME: this can hung
| when ai_update_units Me: $world.end_turn

ai.update =
| PerCycle <= t
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
| PerCycle <= 0

export
