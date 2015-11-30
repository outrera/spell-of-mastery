use queue

PFMap = dup 134: dup 134: dup 64: #FFFFFFFFFFFF
PFQueue = queue 256*256
PFCount = #FFFFFF

pf_reset_count =
| for Ys PFMap: for Xs Ys: Xs.init{#FFFFFFFFFFFF}
| PFCount <= #FFFFFF

node_to_path Node =
| Path = []
| while Node
  | Prev,XYZ,Cost = Node
  | push XYZ Path
  | Node <= Prev
| Path.tail.list

world.pathfind Closest U Check =
| X,Y,Z = U.xyz
| Targets = []
| !PFCount-1
| less PFCount: pf_reset_count
| StartCost = PFCount*#1000000
| PFMap.X.Y.Z <= StartCost
| PFQueue.push{[0 U.xyz StartCost]}
//| StartTime = clock
| till PFQueue.end
  | Node = PFQueue.pop
  | Prev,XYZ,Cost = Node
  | X,Y,Z = XYZ
  | NextCost = Cost+1
  | for Dst U.list_moves{XYZ}:
    | when Check Dst:
      | case $units_at{Dst.xyz}/*.skip{?empty}*/ [T@_]:
        | less Targets.any{?1.xyz >< Dst.xyz}:
          | when got!it $block_at{Dst.xyz}: T <= it
          | push [Node Dst.xyz T] Targets
          | when Closest: _goto end
    | X,Y,Z = Dst.xyz
    | MXY = PFMap.X.Y
    | when NextCost < MXY.Z and Dst.type:
      | B = $block_at{Dst.xyz}
      | when Dst.type><move or (Dst.type >< swap and (not B.attacker or (U.xyz-B.xyz).any{?abs > 2})):
        | MXY.Z <= NextCost
        | PFQueue.push{[Node Dst.xyz NextCost]}
| _label end
//| EndTime = clock
//| say EndTime-StartTime
| less Targets.size: leave 0
| PFQueue.clear
| when Closest: leave Targets.0
| Targets

unit.pathfind Closest Check = $world.pathfind{Closest Me Check}

//FIXME: AI version should setup unit_block
unit.path_to XYZ =
| TargetNode = $pathfind{1 | Dst=>Dst.xyz><XYZ}
| less TargetNode: leave 0
| TargetNode^node_to_path

export node_to_path