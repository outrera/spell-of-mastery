use stack gui

player.active =
| PID = $id
| Turn = $world.turn
| $world.active.list.keep{(?owner.id >< PID and ?moved <> Turn
                           and not ?removed)}

Map = dup 32: dup 32: 0

unit.order_act Act = $order.init{@Act.list.join}

ai.update =
| Turn = $world.turn
| Units = $player.active
| when $player.moves << 0
  | $world.update_pick{[]}
  | $world.end_turn
  | leave
| marked_order U Move =
  | Ms = U.mark_moves
  | Mark = Ms.find{?xyz><Move.xyz}
  | $player.picked.moved <= $world.turn
  | $world.update_pick{[U]}
  | U.guess_order_at_mark{Mark}
  | for M Ms: M.free
| for U Units:
  | Ms = U.list_moves{U.xyz}
  | As = Ms.keep{?type >< attack}
  | case As [A@_]
    | marked_order U A
    | leave
| Pentagram = $player.pentagram
| Leader = $player.leader
| less Pentagram: when Leader:
  | case Leader.acts.keep{?act >< pentagram} [Act@_]
    | Leader.order_act{Act}
    | leave
| when Pentagram: //FIXME: should be only every odd turn
  | Blocker = case $world.units_at{Pentagram.xyz}.skip{?empty} [U@_] U
  | when Blocker
    | when Blocker.owner.id <> $player.id:
      | case Leader.acts.keep{?act >< pentagram} [Act@_]
        | Leader.order_act{Act} // recreate pentagram near the leader
        | leave
    | Ms = Blocker.list_moves{Blocker.xyz}
    | when Ms.size
      | marked_order Blocker Ms.(Turn%Ms.size) //move out of the way
      | leave
  | Summons = if Blocker then [] else Pentagram.acts.keep{?act >< summon}
  | when Summons.size
    | S = Summons.find{?effect >< unit_ratman}
    //| when got S
    //  | 
| for U Units:
  | UID = U.id
  | X,Y,Z = U.xyz
  | for Xs Map: for I Xs.size: Xs.I <= #100000
  | Map.X.Y <= 0
  | Targets = []
  | Stack = [[0 U.xyz 0]]
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
    | while 1
      | Ms = U.list_moves{XYZ}
      | for M Ms: case M.xyz X,Y,Z: when Map.X.Y >< 1:
        | Ms = U.list_moves{U.xyz}
        | XYZ = X,Y,Z
        | case Ms.keep{?xyz >< XYZ} [M@_]
          | marked_order U M
          | leave
        | bad "ai.update got pathfinding error"
      | XYZ <= Ms{[Map.(?xyz.0).(?xyz.1) ?xyz]}.sort{?0 < ??0}.0.1.copy
/*| for U Units:
  | Ms = U.list_moves{U.xyz}
  | case Ms [M@_]:
    | marked_order U M
    | leave*/
| $world.update_pick{[]}
| $world.end_turn


export