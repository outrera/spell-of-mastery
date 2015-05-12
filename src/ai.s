use gui queue

HarmMap = dup 256: dup 256: 0

ai.end_turn =
| $world.update_pick{[]}
| $world.end_turn

ai.order_act U Act =
| $world.update_pick{[U]}
| U.order_act{Act}

ai.marked_order U Move =
| Ms = U.mark_moves
| Mark = Ms.find{?xyz><Move.xyz}
| $player.picked.moved <= $world.turn
| $world.update_pick{[U]}
| U.guess_order_at_mark{Mark}
| for M Ms: M.free

ai.cast_pentagram =
| Leader = $player.leader
| when Leader: case Leader.acts.keep{?act >< pentagram} [Act@_]
  | $order_act{Leader Act}
  | leave 1
| leave 0

ai.update_leader =
| Pentagram = $player.pentagram
| Leader = $player.leader
| Turn = $world.turn
| when Pentagram and Pentagram.moved >> Turn: leave 0
| when Leader and Leader.moved >> Turn: Leader <= 0
| less Pentagram: leave $cast_pentagram
| Blocker = $world.block_at{Pentagram.xyz}
| when got Blocker:
  | EnemyBlocker = Blocker.owner.id <> $player.id
  | when EnemyBlocker: leave $cast_pentagram
  | less EnemyBlocker
    | when Blocker.moved>>Turn: leave 0
    | Ms = Blocker.list_moves{Blocker.xyz}.keep{?type><move}
    | A = if Blocker.attack then #200 else #100
    | harmCheck M = 
      | X,Y,Z = M.xyz
      | Harm = HarmMap.X.Y
      | (Harm^^#FF) and (Harm^^#FF00)<A
    | Ms <= Ms.skip{&harmCheck} // avoid harm for battles near pentagram
    | when Ms.size
      | $marked_order{Blocker Ms.rand} //move out of the way
      | leave 1
    | Ms = Blocker.list_moves{Blocker.xyz}.keep{?type><swap}
    | for M Ms
      | B = $world.block_at{M.xyz}
      | when B.leader
        | Ms = B.list_moves{B.xyz}.keep{?type><move}
        | when Ms.size
          | $marked_order{B Ms.rand} //move out of the way
          | leave 1
    | when Leader: less Blocker.id >< Leader.id:
      | when Turn-Pentagram.moved>6: leave $cast_pentagram
| Summons = if got Blocker then [] else Pentagram.acts.keep{?act >< summon}
| when Summons.size
  | S = Summons.find{?effect >< unit_goblin}
  | when got S
    | if $player.research_remain{S} > 0
      then | $player.researching <= S.type
           | $end_turn
           | leave 1
      else | when Pentagram.moved >> Turn and $player.mana>>S.cost: leave 0
           | $order_act{Pentagram S}
           | leave 1
| 0

PFMap = dup 134: dup 134: dup 64: #FFFFFFFFFFFF
PFQueue = queue 256*256
PFCount = #FFFFFF

pf_reset_count =
| for Ys PFMap: for Xs Ys: Xs.init{#FFFFFFFFFFFF}
| PFCount <= #FFFFFF

world.pathfind Closest U Type =
| X,Y,Z = U.xyz
| Targets = []
| !PFCount-1
| less PFCount: pf_reset_count
| StartCost = PFCount*#1000000
| PFMap.X.Y.Z <= StartCost
| PFQueue.push{[0 U.xyz StartCost]}
| till PFQueue.end
  | Node = PFQueue.pop
  | [Prev XYZ Cost] = Node
  | X,Y,Z = XYZ
  | NextCost = Cost+1
  | for M U.list_moves{XYZ}:
    | when M.type >< attack:
      | case $units_at{M.xyz}.skip{?empty} [T@_]:
        | less Targets.any{?id >< T.id}:
          | push T Targets
          | when Closest: _goto end
    | X,Y,Z = M.xyz
    | MXY = PFMap.X.Y
    | when NextCost < MXY.Z:
      | MXY.Z <= NextCost
      | PFQueue.push{[Node M.xyz NextCost]}
| _label end
| EndTime = get_gui{}.ticks{}
//| say EndTime-StartTime
| less Targets.size: leave 0
| Targets <= Targets{?xyz}
| PFQueue.clear
| when Closest: leave Targets.0
| Targets

unit.pathfind Closest Type = $world.pathfind{Closest Me Type}

world.path U Target =
| XYZ = Target
| Path = [XYZ]
| UX,UY,UZ = U.xyz
| UCost = PFMap.UX.UY.UZ
| till PFMap.(XYZ.0).(XYZ.1).(XYZ.2)-UCost >< 1
  | Ms = U.list_moves{XYZ}
  | XYZ <= Ms{[PFMap.(?xyz.0).(?xyz.1).(?xyz.2) ?xyz]}.sort{?0 < ??0}.0.1
  | push XYZ Path
| Path.list

ai.attack_with U =
| TargetXYZ = U.pathfind{1 attack}
| less TargetXYZ: leave 0
| XYZ = $world.path{U TargetXYZ}.0
| Turn = $world.turn
| Ms = U.list_moves{U.xyz}
| M = Ms.find{?xyz >< XYZ}
| less got M: leave 0
| B = $world.block_at{M.xyz}
| $marked_order{U M}
| leave 1

ai.update_units Units =
| less Units.size: leave 0
| Player = $player
| Pentagram = Player.pentagram
| Leader = Player.leader
| Turn = $world.turn
| AiNextUnit = have $player.params.ai_next_unit [0]
| AiUnitsRemain = have $player.params.ai_units_remain [0 0]
| when AiUnitsRemain.0 <> Turn: AiUnitsRemain.init{Turn,Units.size}
| UnitsRemain = AiUnitsRemain.1
| PentID = 0
| when Leader: PentID <= Leader.id
| when Pentagram: PentID <= Pentagram.id
| while UnitsRemain > 0
  | U = Units.(AiNextUnit.0%Units.size)
  | !AiNextUnit.0 + 1
  | !UnitsRemain-1
  | AiUnitsRemain.1 <= UnitsRemain
  | when U.id >< PentID: when $update_leader: leave 1
  | when U.attack and U.attacker: when $attack_with{U}: leave 1
| leave 0

ai.harm Attacker Victim =
| Victim.attacker <= 1 //have to be aggressive

ai.update =
| Player = $player
| PID = Player.id
| Units = Player.active
| Pentagram = Player.pentagram
| for U Units: // check if we can attack someone 
  | case U.list_moves{U.xyz}.keep{?type >< attack} [A@_]
    | U.attacker <= 1
    | $marked_order{U A}
    | leave
| for Xs HarmMap: for I Xs.size: Xs.I <= 0
| for U Units{U=>U.list_attack_moves{U.xyz}}.join:
  | XYZ = U.xyz
  | !HarmMap.(XYZ.0).(XYZ.1) + #100
| isEnemy U = U.owner.id <> PID and U.health and not U.removed
| Es = $world.active.list.keep{&isEnemy}
| Ts = Es{U=>U.list_attack_moves{U.xyz}{[U ?]}}.join
| for U,T Ts
  | XYZ = T.xyz
  | X,Y,Z = XYZ
  | O = U.owner
  | if U.ranged then HarmMap.X.Y <= #1
    else !HarmMap.X.Y + #1
| Ts <= Ts{?1}
| for U Units
  | X,Y,Z = U.xyz
  | Harm = HarmMap.X.Y
  | when Harm^^#FF: less (Harm^^#FF00) and not U.leader:
    | Moves = U.list_moves{U.xyz}.keep{?type><move}
    | when Pentagram: Moves.skip{?xyz><Pentagram.xyz}
    | AttackMoves = Moves.keep{M=>U.list_moves{M.xyz}.keep{?type><attack}.size}
    | when AttackMoves.size:
      | $marked_order{U AttackMoves.rand}
      | leave
    | SafeMoves = Moves.skip{M=>| XYZ = M.xyz; Ts.any{?xyz><XYZ}}
    | when SafeMoves.size
      | $marked_order{U SafeMoves.rand} //avoid harm
      | leave
| for U Units: when U.attack: //see if we can threat some enemy unit
  | X,Y,Z = U.xyz
  | Harm = HarmMap.X.Y
  | less Harm^^#FF
    | Ms = U.list_moves{U.xyz}.keep{?type >< move}
    | for M Ms // try provoking enemy attack, so we can counter-attack
      | X,Y,Z = M.xyz
      | Harm = HarmMap.X.Y
      | when Harm^^#FF and (Harm^^#FF00) > #100:
        | $marked_order{U M}
        | leave
    | for M Ms // otherwise try blocking enemy movements
      | X,Y,Z = M.xyz
      | Harm = HarmMap.X.Y
      | when Harm^^#FF00000 and (not Harm^^#FF or (Harm^^#FF00) > #100):
        | $marked_order{U M}
        | leave
| Quit = $update_units{Units}
| when Quit: leave
| $end_turn


export