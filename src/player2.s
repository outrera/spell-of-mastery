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

ai.update =
| Turn = $world.turn
| Player = $player
| PID = $player.id
| Units = $player.active
| Pentagram = $player.pentagram
| Leader = $player.leader
| when $player.moves << 0
  | $end_turn
  | leave
| marked_order U Move =
  | Ms = U.mark_moves
  | Mark = Ms.find{?xyz><Move.xyz}
  | $player.picked.moved <= $world.turn
  | $world.update_pick{[U]}
  | U.guess_order_at_mark{Mark}
  | for M Ms: M.free
| for U Units: // check if we can attack someone
  | Ms = U.list_moves{U.xyz}
  | As = Ms.keep{?type >< attack}
  | case As [A@_]
    | marked_order U A
    | leave
| Es = $world.active.list.keep{(?attack and ?owner.id <> PID and not ?removed)}
| Ts = Es{U=>U.list_moves{U.xyz}}.join
| for Xs HarmMap: for I Xs.size: Xs.I <= 0
| for T Ts
  | XYZ = T.xyz
  | HarmMap.(XYZ.0).(XYZ.1) <= 1
  | when T.type >< attack: //move unit out of threat zone
    | U = $world.block_at{T.xyz}
    | when U.owner.id >< $player.id:
      | Moves = U.list_moves{U.xyz}.keep{?type><move}
      | when Pentagram: Moves.skip{?xyz><Pentagram.xyz}
      | for Move Moves
        | XYZ = Move.xyz
        | less Ts.any{?xyz><XYZ}
          | marked_order U Move
          | leave
| less Pentagram: when Leader:
  | case Leader.acts.keep{?act >< pentagram} [Act@_]
    | Leader.order_act{Act}
    | leave
| when Pentagram: //FIXME: should be once every odd turn
  | Blocker = $world.block_at{Pentagram.xyz}
  | when got Blocker:
    | EnemyBlocker = Blocker.owner.id <> $player.id
    | when EnemyBlocker
      | when Leader: case Leader.acts.keep{?act >< pentagram} [Act@_]
        | Leader.order_act{Act} // recreate pentagram near the leader
        | leave
    | less EnemyBlocker
      | Ms = Blocker.list_moves{Blocker.xyz}.keep{?type><move}
      | Ms = Ms.skip{HarmMap.(?.xyz.0).(?.xyz.1)}
      | when Ms.size
        | marked_order Blocker Ms.(Turn%Ms.size) //move out of the way
        | leave
  | Summons = if got Blocker then [] else Pentagram.acts.keep{?act >< summon}
  | when Summons.size
    | S = Summons.find{?effect >< unit_ratman}
    | when got S
      | if $player.research_remain{S} > 0
        then | $player.researching <= S.type
             | $end_turn
             | leave
        else | Pentagram.order_act{S}
             | leave
| for Xs Map: for I Xs.size: Xs.I <= #FFFFFFFFFFFF
| for N,U Units.keep{?attack}.i.flip:
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
        | Ms = Ms.skip{HarmMap.(?.xyz.0).(?.xyz.1)}
        | XYZ = X,Y,Z
        | case Ms.keep{?xyz >< XYZ} [M@_]
          | marked_order U M
          | leave
        | Loop <= 0
      | XYZ <= Ms{[Map.(?xyz.0).(?xyz.1) ?xyz]}.sort{?0 < ??0}.0.1.copy
/*| for U Units:
  | Ms = U.list_moves{U.xyz}
  | case Ms [M@_]:
    | marked_order U M
    | leave*/
| $end_turn


export