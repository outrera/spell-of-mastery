use queue util

//note: here order is important, or path will go zig-zag
//Dirs = [[-1 -1] [1 1] [1 -1] [-1 1] [0 -1] [1 0] [0 1] [-1 0]]

unit.list_moves Src =
| Ms = []
| SX,SY,SZ = Src
| CanMove = $can_move
| for Cell $world.cell{SX SY SZ}.neibs
  | Dst = 0
  | less Cell.tile.type >< border_:
    | Cell <= Cell.fix_z
    | Dst <= Cell.xyz
    | less CanMove{Me Src Dst}: Dst <= 0
  | when Dst:
    | B = Cell.block
    | if B then
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

PFQueue = queue 256*256

world.pathfind MaxCost U XYZ Check =
| less U.speed: leave 0
| X,Y,Z = XYZ
| StartCost = $new_visit
| !MaxCost+StartCost
| StartCell = $cell{X Y Z}
| StartCell.visited <= StartCost
| PFQueue.push{[0 XYZ StartCost]}
| R = 0
//| StartTime = clock
| till PFQueue.end
  | Node = PFQueue.pop
  | Prev,XYZ,Cost = Node
  | when Cost<MaxCost:
    | NextCost = Cost+1
    | for DXYZ U.list_moves{XYZ}:
      | X,Y,Z = DXYZ
      | Cell = $cell{X Y Z}
      | C = Check DXYZ
      | when C:
        | if C><block then NextCost <= Cell.visited //high cost blocks it
          else | R <= [Node DXYZ $block_at{DXYZ}]
               | _goto end
      | when NextCost < Cell.visited:
        | Cell.visited <= NextCost
        | PFQueue.push{[Node DXYZ NextCost]}
| _label end
//| EndTime = clock
//| say EndTime-StartTime
| PFQueue.clear
| R

world.pathfind_closest MaxCost U XYZ TargetXYZ =
| less U.speed: leave 0
| X,Y,Z = XYZ
| StartCost = $new_visit
| !MaxCost+StartCost
| StartCell = $cell{X Y Z}
| StartCell.visited <= StartCost
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
    | for DXYZ U.list_moves{XYZ}:
      | NewL = (TargetXY-DXYZ.take{2}).abs
      | when BestL>>NewL and (BestL>NewL or TargetXYZ.2><DXYZ.2):
        | BestL <= NewL
        | BestXYZ <= DXYZ
        | R <= [Node DXYZ]
        | when BestL < 2.0:
          | when BestXYZ><TargetXYZ: _goto end
          | less $at{@TargetXYZ}.empty: _goto end
          | B = $block_at{TargetXYZ}
          | when B:
            | less B.speed: _goto end
            | when not U.damage and U.owner.is_enemy{B.owner}: _goto end
      | X,Y,Z = DXYZ
      | Cell = $cell{X Y Z}
      | when NextCost < Cell.visited:
        | Cell.visited <= NextCost
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
