use macros unit_flags util

SeenUnits = 0
OwnedUnits = 0
SeenEnemies = 0
PerCycle = 0

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
| $order_at{Cell.xyz 0}
| 0

unit.ai_pick_target Act =
| R = Act.range
| Targets =
    if R>>9000 then SeenUnits
    else if R><0 then [Me]
    else $world.units_in_range{Me.xyz Act.range}
| Ts = Targets.skip{?empty}.keep{?alive}
| Hint = Act.hint
| if Hint >< pentagram then
  else if Hint >< heal then
    | Ts <= Ts.keep{?is_ally{Me}}.keep{?harmed}
  else if Hint >< lifedrain then
    | less $harmed: leave 0
    | Ts <= Ts.keep{?is_enemy{Me}}
  else if Hint >< harm then
    | Ts <= Ts.keep{?is_enemy{Me}}
  else if Hint >< benefit then
    | Ts <= Ts.keep{?is_ally{Me}}
  else leave 0
| Ts <= Ts.keep{T => Act.validate{Me T.xyz T 0}}
| for Flag Act.flags //avoid overriding
  | FlagN = getUnitFlagsTable{}.Flag
  | when got FlagN: Ts <= Ts.skip{T => T.flags^get_bit{FlagN}}
| if Ts.size then Ts.0 else 0

unit.ai_ability_sub Act =
| when Act.mov > $mov: leave 0
| when $owner.mana < Act.cost: leave 0
| when $cooldown_of{Act.name}: leave 0
| less $owner.enabled{Act} and $earned{Act}: leave 0
| when Act.hint >< dismiss: leave 0
| when Act.hint >< pentagram:
  | less $owner.pentagram.removed: leave 0
  | less $cell.is_floor_empty: 
    | TargetNode = $pathfind{1000 |Dst=>Dst.is_floor_empty}
    | when TargetNode:
      | $advance_to{TargetNode.xyz}
      | leave 1
    | leave 0
| Target = $ai_pick_target{Act}
| less Target: leave 0 //no suitable target for this act
| Cost = Act.cost
| Me.owner.mana+=Cost
| when $can_do{Act}
  | $order_act{Act Target}
  | leave 1
| Me.owner.mana -= Cost //havent casted the spell
| 0

// for final build do some random-shuffle $acts to make it less predictable
list_rotate I Xs =
| N = Xs.size
| less N: leave Xs
| N <= I%N
| [@Xs.drop{N} @Xs.take{N}]

unit.ai_ability =
| for Act list_rotate{$world.turn $acts}: when $ai_ability_sub{Act}: leave 1
| 0

ai_leader_harmed Me Attacker Victim =

ai.harm Attacker Victim =
| when Victim.leader: ai_leader_harmed Me Attacker Victim

unit.ai_roam =
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

unit.enemies_in_sight =
| $units_in_range{$sight}.keep{X=>$is_enemy{X} and not X.invisible}

unit.ai_runaway Btrack =
| Es = $enemies_in_sight
| Rs = $reachable{}{?1}.skip{?block}
| Best = 0
| BestDist = 0
| for R Rs:
  | Dist = 9000
  | for E Es:
    | Found = $world.closest_reach{$sight Me R E.xyz}
    | Path = if Found then Found.path else []
    | when Path.size<Dist: Dist <= Path.size
  | when BestDist<Dist:
    | BestDist <= Dist
    | Best <= R
| when Best:
  | $order_at{Best.xyz 0}
  | when Btrack: less $get{btrack}: $backtrack <= $xyz
| $handled <= 1

unit.ai_update =
| less $mov > 0:
  | $handled <= 1
  | leave 0
| when $afraid:
  | when $enemies_in_sight.size: $ai_runaway{1}
  | leave 0
| when not $charging or $charging_charge+$will>>$charging_cost:
  | when $ai_ability: leave break
| when $atk:
  | Cs = $reachable
  | case Cs.keep{?0><attack} [[Type Cell]@_]:
    | Block = Cell.block
    | when Block and not Block.invisible:
      | $backtrack <= $xyz
      | $order_at{Cell.xyz 0}
      | leave break
  | when $mov:
    | Es = $enemies_in_sight
    | PursueRange = max $sight 10
    | Flt = Cs{[?1 1]}.table //filtering table
    | Es = Es.skip{E => Flt.(E.cell)><1}
    | EsR = Es.keep{E => $path_to{E.xyz}.size<PursueRange}
    | less EsR.size: EsR <= Es.keep{E => $path_near{E.xyz}.size<PursueRange}
    | case EsR [E@_]:
      | $backtrack <= $xyz
      | $advance_to{E.xyz}
      | less $handled: $handled <= 1
      | leave break
| when $aistate <> roam:
  | BtXYZ = $get{btrack}
  | when BtXYZ and $advance_to{BtXYZ}: $backtrack <= 0
| when $aistate >< roam and $ai_roam: leave break
| $handled <= 1
| \next

ai.get_clean_pentagram =
| Pentagram = $player.pentagram
| when Pentagram.removed: leave 0
| when not Pentagram.cell.block: leave Pentagram
| 0

ai.update_build =
| Leader = $player.leader
| Pentagram = $get_clean_pentagram
| less Pentagram: leave 0
| Spawns = Leader.acts.keep{?onEndTable.spawn^got}
| less Spawns.size: leave 0
| Missing = PerCycle.missing_attackers
| less got Missing: leave
| for Type Missing:
  | S = Spawns.find{?onEndTable.spawn >< Type}
  | when got S and Leader.can_do{S}:
    | Leader.order_act{S Me}
    | leave 1
| 0

ai.clean_pentagram =
| Pentagram = $player.pentagram
| when Pentagram.removed: leave 0
| B = Pentagram.cell.block
| less B and B.mov and B.owner.id><$player.id: leave 0
| Cs = B.reachable.keep{?0><move}
| Cs = Cs.sort{A B => A.1.xyz.mdist{B.1.xyz}.sum}.flip
| for Type,Cell Cs:
  | when not Cell.block and got Cell.units.find{?ai><hold}:
    | B.order_at{Cell.xyz 0} //move unit out of pentagram
    | leave 1
| case Cs [[Type Cell]@_]:
  | B.order_at{Cell.xyz 0} //move unit out of pentagram
  | leave 1
| 0

ai.update_units =
| when $update_build: leave 0
| for U OwnedUnits: less U.handled:
  | R = U.ai_update
  | when R >< break: leave 0
| for U OwnedUnits: when U.handled><wait:
  | R = U.ai_update //handle units with delayed movement
  | when R >< break: leave 0
| when $clean_pentagram: leave 0
| 1 //return true, meaning that we have handled all units

ai.group_roam Types =
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
    | less $group_roam{Types{"unit_[?]"}}: leave 0
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

ai.update_turn =
| when $player.params.attack_with_guards >< 1:
  | for U OwnedUnits: U.aistate <= \roam
  | $player.params.attack_with_guards <= 0
| when $player.id: while $script><1: //FIXME: this can hung
| when $update_units: $world.end_turn

ai.update =
| PerCycle <= t
| Player = $player
| SeenUnits <= $world.active.list.keep{U=>Player.seen{U.xyz}}
                     .keep{(?unit and not ?removed)}
| PID = Player.id
| OwnedUnits <= SeenUnits.keep{?owner.id><PID}
| SeenEnemies <= SeenUnits.keep{?owner.is_enemy{Player}}.skip{?invisible}
| $update_turn
| SeenUnits <= 0
| OwnedUnits <= 0
| SeenEnemies <= 0
| PerCycle <= 0

export
