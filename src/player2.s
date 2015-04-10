use stack gui

player.active =
| PID = $id
| Turn = $world.turn
| $world.active.list.keep{(?owner.id >< PID and ?moved <> Turn
                           and not ?removed)}

Map = dup 256: dup 256: 0
HarmMap = dup 256: dup 256: 0

unit.order_act Act = $order.init{@Act.list.join}

player.research_remain Act =
| ResearchSpent = $research.(Act.type)
| ResearchRemain = Act.research - ResearchSpent
| ResearchRemain

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

ai.pentagram =
| Leader = $player.leader
| Pentagram = $player.pentagram
| Blocker = $world.block_at{Pentagram.xyz}
| when got Blocker:
  | EnemyBlocker = Blocker.owner.id <> $player.id
  | when EnemyBlocker
    | when Leader: case Leader.acts.keep{?act >< pentagram} [Act@_]
      | $order_act{Leader Act} // recreate pentagram near the leader
      | leave 1
  | less EnemyBlocker
    | Ms = Blocker.list_moves{Blocker.xyz}.keep{?type><move}
    | Unsafe = if Blocker.attack then 11 else 1
    | Ms = Ms.skip{HarmMap.(?.xyz.0).(?.xyz.1)><Unsafe}
    | when Ms.size
      | Turn = $world.turn
      | $marked_order{Blocker Ms.(Turn%Ms.size)} //move out of the way
      | leave 1
| Summons = if got Blocker then [] else Pentagram.acts.keep{?act >< summon}
| when Summons.size
  | S = Summons.find{?effect >< unit_ratman}
  | when got S
    | if $player.research_remain{S} > 0
      then | $player.researching <= S.type
           | $end_turn
           | leave 1
      else | $order_act{Pentagram S}
           | leave 1
| 0

ai.update =
| Turn = $world.turn
| Player = $player
| PID = $player.id
| Units = $player.active
| Pentagram = $player.pentagram
| when $player.moves << 0
  | $end_turn
  | leave
| for U Units: // check if we can attack someone
  | Ms = U.list_moves{U.xyz}
  | As = Ms.keep{?type >< attack}
  | case As [A@_]
    | $marked_order{U A}
    | leave
| Es = $world.active.list.keep{(?attack and ?owner.id <> PID and not ?removed)}
| Ts = Es{U=>U.list_moves{U.xyz}}.join
| for Xs HarmMap: for I Xs.size: Xs.I <= 0
| for U Units.keep{?attack}{U=>U.list_moves{U.xyz}}.join: 
  | XYZ = U.xyz
  | HarmMap.(XYZ.0).(XYZ.1) <= 10
| for T Ts
  | XYZ = T.xyz
  | X,Y,Z = XYZ
  | Harm = HarmMap.X.Y + 1
  | HarmMap.X.Y <= Harm
  | when T.type >< attack: //move unit out of threat zone
    | U = $world.block_at{T.xyz}
    | when U.owner.id >< $player.id: when Harm<>11 or U.leader:
      | Moves = U.list_moves{U.xyz}.keep{?type><move}
      | when Pentagram: Moves.skip{?xyz><Pentagram.xyz}
      | for Move Moves
        | XYZ = Move.xyz
        | less Ts.any{?xyz><XYZ}
          | $marked_order{U Move}
          | leave
| less Pentagram:
  | Leader = $player.leader
  | when Leader:
    | case Leader.acts.keep{?act >< pentagram} [Act@_]
      | $order_act{Leader Act}
      | leave
| when Pentagram and Turn%2><0: when $pentagram: leave
| for Xs Map: for I Xs.size: Xs.I <= #FFFFFFFFFFFF
| Attackers = Units.keep{?attack}
| Div = Turn%Attackers.size
| Attackers = [@Attackers.drop{Div} @Attackers.take{Div}]
| for N,U Attackers.i.flip:
  | UID = U.id
  | X,Y,Z = U.xyz
  | Targets = []
  | StartCost = N*#1000000
  | Map.X.Y <= StartCost
  | Stack = [[0 U.xyz StartCost]]
  | StartTime = get_gui{}.ticks{}
  | till Stack.end
    | Node = pop Stack
    | [Prev XYZ Cost] = Node
    | X,Y,Z = XYZ
    | NextCost = Cost+1
    | for M U.list_moves{XYZ}:
      | when M.type >< attack:
        | case $world.units_at{M.xyz}.skip{?empty} [T@_]:
          | less Targets.any{?id >< T.id}: push T Targets
      | case M.xyz X,Y,Z: when NextCost < Map.X.Y:
        | Map.X.Y <= NextCost
        | push [Node M.xyz NextCost] Stack
  | EndTime = get_gui{}.ticks{}
//  | say EndTime-StartTime
  | when Targets.size
    | Target = Targets{[Map.(?xyz.0).(?xyz.1) ?]}.sort{?0 < ??0}.0.1
    | Path = []
    | XYZ = Target.xyz
    | Loop = 1
    | while Loop
      | Ms = U.list_moves{XYZ}
      | for M Ms: case M.xyz X,Y,Z: when (Map.X.Y^^#FFFFFF) >< 1:
        | Ms = U.list_moves{U.xyz}
        | Ms = Ms.skip{HarmMap.(?.xyz.0).(?.xyz.1)><11}
        | XYZ = X,Y,Z
        | case Ms.keep{?xyz >< XYZ} [M@_]
          | if M.type >< swap
            then | AISwapXYZ = $params.aiSwapXYZ
                 | if U.xyz <> AISwapXYZ
                   then | $marked_order{U M}
                        | AISwapXYZ.init{U.xyz}
                   else | U.moved <= Turn // FIXME: hack
            else $marked_order{U M}
          | leave
        | Loop <= 0
      | XYZ <= Ms{[Map.(?xyz.0).(?xyz.1) ?xyz]}.sort{?0 < ??0}.0.1.copy
/*| for U Units:
  | Ms = U.list_moves{U.xyz}
  | case Ms [M@_]:
    | $marked_order{U M}
    | leave*/
| when Turn%2<>0: when Pentagram and $pentagram: leave
| $end_turn


export