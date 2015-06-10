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

// recasts pentagram, when it doesnt exist or occupied by enemy
ai.update_leader =
| Pentagram = $player.pentagram
| Leader = $player.leader
| Turn = $world.turn
| when Leader and Leader.moved >> Turn: Leader <= 0
| less Pentagram: leave $cast_pentagram
| Blocker = $world.block_at{Pentagram.xyz}
| when got Blocker:
  | EnemyBlocker = Blocker.owner.id <> $player.id
  | when EnemyBlocker: leave $cast_pentagram
| 0

ai.remove_blocker Blocker =
| Turn = $world.turn
| when Blocker.moved>>Turn: leave 0
| Ms = Blocker.list_moves{Blocker.xyz}.keep{?type><move}
| A = if Blocker.attack then #200 else #100
| harmCheck M = 
  | X,Y,Z = M.xyz
  | Harm = HarmMap.X.Y
  | (Harm^^#FF) and (Harm^^#FF00)<A
| Ms <= Ms.skip{&harmCheck} // avoid harm when enemies near pentagram
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
//| when Leader: less Blocker.id >< Leader.id:
//  | when Turn-Pentagram.moved>6: leave $cast_pentagram

ai.update_research =
| Pentagram = $player.pentagram
| less Pentagram: leave 0
| Summons = Pentagram.acts.keep{?act >< summon}
| less Summons.size: leave 0
| S = Summons.find{?effect >< unit_goblin}
| when got S and $player.research_remain{S} > 0:
  | $player.researching <= S.type
  | leave 1
| 0

ai.update_pentagram =
| Pentagram = $player.pentagram
| less Pentagram: leave 0
| Blocker = $world.block_at{Pentagram.xyz}
| when got Blocker: leave 0
| Summons = Pentagram.acts.keep{?act >< summon}
| less Summons.size: leave 0
| S = Summons.find{?effect >< unit_goblin}
| Turn = $world.turn
| when got S and $player.research_remain{S} << 0:
  | when Pentagram.moved >> Turn or S.cost>$player.mana: leave 0
  | $order_act{Pentagram S}
  | leave 1
| 0

PFMap = dup 134: dup 134: dup 64: #FFFFFFFFFFFF
PFQueue = queue 256*256
PFCount = #FFFFFF

pf_reset_count =
| for Ys PFMap: for Xs Ys: Xs.init{#FFFFFFFFFFFF}
| PFCount <= #FFFFFF

world.pathfind Closest U Check =
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
    | when Check M:
      | case $units_at{M.xyz}/*.skip{?empty}*/ [T@_]:
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

unit.pathfind Closest Check = $world.pathfind{Closest Me Check}

world.path U Target =
| XYZ = Target
| Path = [XYZ]
| UX,UY,UZ = U.xyz
| UCost = PFMap.UX.UY.UZ
| while PFMap.(XYZ.0).(XYZ.1).(XYZ.2)-UCost > 1
  | Ms = U.list_moves{XYZ}
  | XYZ <= Ms{[PFMap.(?xyz.0).(?xyz.1).(?xyz.2) ?xyz]}.sort{?0 < ??0}.0.1
  | push XYZ Path
| when Path.size > 1 and Path.0 >< U.xyz: pop Path
| Path.list

ai.attack_with U =
| World = $world
| OId = U.owner.id
| Check = Move =>
  | if Move.type><attack then 1
    else | Node = World.units_at{Move.xyz}.find{?type><special_node}
         | if got Node and no World.block_at{Move.xyz} then 1
           else 0
| TargetXYZ = U.pathfind{1 Check}
| less TargetXYZ: leave 0
| XYZ = $world.path{U TargetXYZ}.0
| Turn = $world.turn
| Ms = U.list_moves{U.xyz}
| M = Ms.find{?xyz >< XYZ}
| less got M: leave 0
| $marked_order{U M}
| leave 1

Count = 0

ai.update_units Units =
| Player = $player
| Pentagram = Player.pentagram
| Leader = Player.leader
| PentID = 0
| PentXYZ = [-1 -1 -1]
| LeaderID = 0
| when Leader: LeaderID <= Leader.id
| when Pentagram:
  | PentID <= Pentagram.id
  | PentXYZ <= Pentagram.xyz
| for U Units: less U.handled:
  | U.handled <= 1
  | Attacker = U.attack /*and U.attacker*/
  | when Attacker:
    | when no $world.units_at{U.xyz}.find{?type><special_node}:
      | when $attack_with{U}: leave 1
  | less Attacker:
    | when U.id >< LeaderID: when $update_leader: leave 1
    | when U.id >< PentID: when $update_pentagram: leave 1
  | when U.xyz >< PentXYZ and U.id <> PentID:
    | when $remove_blocker{U}: leave 1
| $update_research
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