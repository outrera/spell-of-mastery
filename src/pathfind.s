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

world.pathfind MaxCost U Check =
| X,Y,Z = U.xyz
| !PFCount-1
| less PFCount: pf_reset_count
| StartCost = PFCount*#1000000
| !MaxCost+StartCost
| PFMap.X.Y.Z <= StartCost
| PFQueue.push{[0 U.xyz StartCost]}
| R = 0
//| StartTime = clock
| till PFQueue.end
  | Node = PFQueue.pop
  | Prev,XYZ,Cost = Node
  | when Cost<MaxCost:
    | X,Y,Z = XYZ
    | NextCost = Cost+1
    | for Dst U.list_moves{XYZ}:
      | when Check Dst:
        | R <= [Node Dst.xyz $block_at{Dst.xyz}]
        | _goto end
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
| PFQueue.clear
| R

unit.pathfind MaxCost Check = $world.pathfind{MaxCost Me Check}

//FIXME: AI version should setup unit_block
unit.path_to XYZ =
| Found = $pathfind{1000| Dst=>Dst.xyz><XYZ}
| if Found then Found^node_to_path else []

export node_to_path