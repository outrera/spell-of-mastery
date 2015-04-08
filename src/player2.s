use stack

player.active =
| PID = $id
| Turn = $world.turn
| $world.active.list.keep{(?owner.id >< PID and ?moved <> Turn)}

Map = dup 256: dup 256: 0

ai.update =
| Turn = $world.turn
| Units = $player.active
| Moved = $player.moves << 0
| maked_order U Mark =
  | $player.picked.moved <= $world.turn
  | $world.update_pick{[U]}
  | U.guess_order_at_mark{Mark}
  | Moved <= 1
| less Moved: for U Units: 
  | Ms = U.mark_moves
  | As = Ms.keep{?type >< mark_attack}
  | case As [A@_]:
    | maked_order U A
  | for M Ms: M.free
  | when Moved: leave
| for U Units:
  | UID = U.id
  | X,Y,Z = U.xyz
  | for Xs Map: for I Xs.size: Xs.I <= #100000
  | Map.X.Y <= 0
  | Targets = []
  | Stack = [[0 U.xyz 0]]
  | till Stack.end
    | Node = pop Stack
    | [Prev XYZ Cost] = Node
    | X,Y,Z = XYZ
    | Ms = U.mark_moves{XYZ}
    | for M Ms:
      | when M.type >< mark_attack:
        | case $world.units_at{M.xyz}.skip{?empty} [T@_]:
          | less Targets.any{?id >< T.id}: push T Targets
      | NextCost = Cost+1
      | case M.xyz X,Y,Z: when NextCost < Map.X.Y:
        | Map.X.Y <= NextCost
        | push [Node M.xyz.copy NextCost] Stack
      | M.free
  | when Targets.size
    | Target = Targets{[Map.(?xyz.0).(?xyz.1) ?]}.sort{?0 < ??0}.0.1
    | Path = []
    | XYZ = Target.xyz
    | while 1
      | Ms = U.mark_moves{XYZ}
      | for M Ms: case M.xyz X,Y,Z: when Map.X.Y >< 1:
        | for M Ms: M.free
        | Ms = U.mark_moves
        | XYZ = X,Y,Z
        | case Ms.keep{?xyz >< XYZ} [M@_]: maked_order U M
        | for M Ms: M.free
        | less Moved:
          | bad "ai.update got pathfinding error"
        | leave
      | XYZ <= Ms{[Map.(?xyz.0).(?xyz.1) ?xyz]}.sort{?0 < ??0}.0.1.copy
      | for M Ms: M.free
/*| less Moved: for U Units:
  | Ms = U.mark_moves
  | case Ms [M@_]:
    | maked_order U M
  | for M Ms: M.free
  | when Moved: leave*/
| $world.update_pick{[]}
| $world.end_turn


export