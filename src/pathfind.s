use queue util

//note: here order is important, or path will go zig-zag
//Dirs = [[-1 -1] [1 1] [1 -1] [-1 1] [0 -1] [1 0] [0 1] [-1 0]]

list_moves Me Src =
| Ms = []
| SX,SY,SZ = Src
| CanMove = $can_move
| for DX,DY Dirs4
  | X = SX+DX
  | Y = SY+DY
  | Dst = 0
  | less $world.at{X Y SZ}.type >< border_:
    | Dst <= X,Y,SZ
    | Dst.2 <= $world.fix_z{Dst}
    | less CanMove{Me Src Dst}: Dst <= 0
  | when Dst:
    | B = $world.block_at{Dst} //FIXME: could be optimized
    | if got B then
        | if $owner.id <> B.owner.id
          then if B.alive and $damage and (SZ-Dst.2).abs<<1
               then push Dst Ms //attack
               else
          else when B.speed and B.can_move{}{B Dst Src}:
               | push Dst Ms //FIXME: consider moving B back
      else push Dst Ms
| Ms


node_to_path Node =
| Path = []
| while Node
  | Prev,XYZ,Cost = Node
  | push XYZ Path
  | Node <= Prev
| Path.tail.list

PFMap = dup 134: dup 134: dup 64: #FFFFFFFFFFFF
PFQueue = queue 256*256
PFCount = #FFFFFF

pf_reset_count =
| for Ys PFMap: for Xs Ys: Xs.init{#FFFFFFFFFFFF}
| PFCount <= #FFFFFF

world.pathfind MaxCost U XYZ Check =
| less U.speed: leave 0
| X,Y,Z = XYZ
| !PFCount-1
| less PFCount: pf_reset_count
| StartCost = PFCount*#1000000
| !MaxCost+StartCost
| PFMap.X.Y.Z <= StartCost
| PFQueue.push{[0 XYZ StartCost]}
| R = 0
//| StartTime = clock
| till PFQueue.end
  | Node = PFQueue.pop
  | Prev,XYZ,Cost = Node
  | when Cost<MaxCost:
    | NextCost = Cost+1
    | for Dst list_moves{U XYZ}:
      | X,Y,Z = Dst
      | MXY = PFMap.X.Y
      | C = Check Dst
      | when C:
        | if C><block then NextCost <= MXY.Z //high cost blocks it
          else | R <= [Node Dst $block_at{Dst}]
               | _goto end
      | when NextCost < MXY.Z:
        | MXY.Z <= NextCost
        | PFQueue.push{[Node Dst NextCost]}
| _label end
//| EndTime = clock
//| say EndTime-StartTime
| PFQueue.clear
| R

world.pathfind_closest MaxCost U XYZ TargetXYZ =
| less U.speed: leave 0
| X,Y,Z = XYZ
| !PFCount-1
| less PFCount: pf_reset_count
| StartCost = PFCount*#1000000
| !MaxCost+StartCost
| PFMap.X.Y.Z <= StartCost
| PFQueue.push{[0 XYZ StartCost]}
| BestXYZ = XYZ
| TargetXY = TargetXYZ.take{2}
| BestL = (TargetXY-BestXYZ.take{2}).abs
| R = 0
| till PFQueue.end
  | Node = PFQueue.pop
  | Prev,XYZ,Cost = Node
  | when Cost<MaxCost:
    | NextCost = Cost+1
    | for DXYZ list_moves{U XYZ}:
      | NewL = (TargetXY-DXYZ.take{2}).abs
      | when BestL>>NewL and (BestL>NewL or TargetXYZ.2><DXYZ.2):
        | BestL <= NewL
        | BestXYZ <= DXYZ
        | R <= [Node DXYZ]
        | when BestL < 2.0:
          | when BestXYZ><TargetXYZ: _goto end
          | less $at{@TargetXYZ}.empty: _goto end
          | B = $block_at{TargetXYZ}
          | when got B:
            | less B.speed: _goto end
            | when not U.damage and U.owner.is_enemy{B.owner}: _goto end
      | X,Y,Z = DXYZ
      | MXY = PFMap.X.Y
      | when NextCost < MXY.Z
        | MXY.Z <= NextCost
        | PFQueue.push{[Node DXYZ NextCost]}
| _label end
| PFQueue.clear
| if R then [R.0 R.1 0]^node_to_path else 0

unit.pathfind MaxCost Check = $world.pathfind{MaxCost Me $xyz Check}

unit.find MaxCost Check =
| Found = $world.pathfind{MaxCost Me $xyz Check}
| if Found then Found.1 else 0

//FIXME: AI version should setup unit_block
unit.path_to XYZ close/0 =
| Found = $world.pathfind_closest{1000 Me $xyz XYZ}
| if Found then Found else []


export node_to_path