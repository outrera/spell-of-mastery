use queue util

land_can_move Me Src Dst =
| H = Dst.z-Src.z
| when H > 1 or H < -1: leave 0
| Dst.tile.empty and not (Dst-1).tile.liquid

amphibian_can_move Me Src Dst =
| H = Dst.z-Src.z
| when H > 1 or H < -1: leave 0
| Dst.tile.empty

swimmer_can_move Me Src Dst =
| H = Dst.z-Src.z
| when H > 1 or H < -1: leave 0
| Dst.tile.empty and (Dst-1).tile.type><water

flyer_can_move Me Src Dst =
| less Dst.tile.empty: leave 0
| SZ = Src.z
| DZ = Dst.z
| if SZ<DZ
  then | when DZ > $world.d-3: leave 0
       | times I DZ-SZ: less (Src+I).tile.empty: leave 0
  else times I SZ-DZ: less (Dst+I).tile.empty: leave 0
| 1

climber_can_move Me Src Dst =
| less Dst.tile.empty: leave 0
| when (Dst-1).tile.liquid: leave 0
| SZ = Src.z
| DZ = Dst.z
| if SZ<DZ
  then | when DZ-SZ > 3: leave 0
       | when DZ > $world.d-3: leave 0
       | times I DZ-SZ: less (Src+I).tile.empty: leave 0
  else | when SZ-DZ > 3: leave 0
       | times I SZ-DZ: less (Dst+I).tile.empty: leave 0
| 1

unit.update_move_method =
| $can_move <= if $flyer then &flyer_can_move
               else if $amphibian then &amphibian_can_move
               else if $swimmer then &swimmer_can_move
               else if $climber then &climber_can_move
               else &land_can_move

//note: here order is important, or path will go zig-zag
//Dirs = [[-1 -1] [1 1] [1 -1] [-1 1] [0 -1] [1 0] [0 1] [-1 0]]

unit.list_moves Src Cost =
| Ms = []
| CanMove = $can_move
| for Dst Src.neibs
  | Dst <= Dst.floor
  | when Cost < Dst.cost and CanMove{Me Src Dst}:
    | B = Dst.block
    | if B then
        | if $owner.id <> B.owner.id
          then if B.alive and $combat and (Src.z-Dst.z).abs<<1
               then push Dst Ms //attack
               else
          else when B.speed and B.can_move{}{B Dst Src}:
               | push Dst Ms //FIXME: consider moving B back
      else push Dst Ms
| Ms

PFQueue = queue 256*256

world.pathfind MaxCost U StartCell Check =
| less U.speed: leave 0
| X,Y,Z = StartCell.xyz
| StartCost = $new_cost
| MaxCost+=StartCost
| StartCell.cost <= StartCost
| StartCell.prev <= 0
| PFQueue.reset
| PFQueue.push{StartCell}
| R = 0
//| StartTime = clock
| till PFQueue.end
  | Src = PFQueue.pop
  | Cost = Src.cost
  | NextCost = Cost+1
  | Ms = U.list_moves{Src NextCost}
  | when Src.gate:
    | when Src.prev and (Src.prev.xyz-Src.xyz).take{2}{?abs}.sum><1:
      | Ms <= [Src.gate.cell]
  | for Dst Ms:
    | Dst.prev <= Src
    | C = Check Dst
    | when C:
      | if C><block then _goto skip //NextCost <= Dst.cost
        else | Dst.prev <= Src
             | R <= Dst
             | _goto end
    | Dst.cost <= NextCost
    | when NextCost<MaxCost: PFQueue.push{Dst}
    | _label skip
| _label end
//| EndTime = clock
//| say EndTime-StartTime
| R

world.closest_reach MaxCost U StartCell TargetXYZ =
| less U.speed: leave 0
| X,Y,Z = StartCell.xyz
| TX,TY,TZ = TargetXYZ
| TCell = $cell{@TargetXYZ}
| BestL = [TX-X TY-Y].abs
| Best = 0
| check Dst =
  | R = 0
  | DX,DY,DZ = Dst.xyz
  | NewL = [TX-DX TY-DY].abs
  | when BestL>>NewL and (BestL>NewL or TZ><DZ):
    | BestL <= NewL
    | Best <= Dst
    | when BestL < 1.4:
      | when Best><TCell: | R <= 1; _goto end
      | less TCell.tile.empty: | R <= 1; _goto end
      | B = TCell.block
      | when B:
        | less B.speed: | R <= 1; _goto end
        | when not U.combat and U.owner.is_enemy{B.owner}: | R <= 1; _goto end
  | _label end
  | R
| $pathfind{MaxCost U StartCell &check}
| Best

world.find MaxCost U StartCell Check =
| Found = $pathfind{MaxCost U StartCell Check}
| if Found then Found else 0

unit.find MaxCost Check = $world.find{MaxCost Me $cell Check}

unit.pathfind MaxCost Check = $world.pathfind{MaxCost Me $cell Check}

unit.path_to XYZ =
| Found = $world.closest_reach{1000 Me $cell XYZ}
| if Found then Found.path else []

unit.path_around_to Range XYZ = //Me is unit
| Target = $world.cell{@XYZ}
| check Dst =
  | if Dst><Target then 1
    else if Dst.block then \block
    else 0
| Found = $pathfind{Range &check}
| if Found then Found.path else []

enemies_in_range Me =
| O = $owner
| check B =
  | when O.is_enemy{B.owner} and B.health and not B.invisible:
    | leave 1
  | 0
| $units_in_range{$range}.skip{?empty}.keep{&check}

path_len Cell =
| C = 0
| while Cell
  | C += 1
  | Cell <= Cell.prev
| C

unit.attack_cost = if $afraid then 9000 else 4

unit.reachable =
| Xs = []
| XYZ = $xyz
| less $engaged: when $steps>0: $find{$steps
  | Dst =>
    | R = \block
    | Type = \move
    | B = Dst.block
    | if not B then R <= 0
      else if $owner.id <> B.owner.id then Type <= 0
      else if B.steps<1 then Type <= 0
      else Type <= \swap
    | when Type: push [Type Dst] Xs
    | Es = $nearby_enemies_at{Dst.xyz}
    | when Es.size:
      | R <= \block //engage
      | when $range><1 and $steps >> Dst^path_len+$attack_cost:
        | for E Es: push [attack E.cell] Xs
    | R}
| when $range><1 and $steps>>$attack_cost:
  | for E Me^enemies_in_range:
    | when (E.xyz.2-$xyz.2).abs << 1: push [attack E.cell] Xs
| when $range>1 and $steps>>$attack_cost:
  | for E Me^enemies_in_range: push [attack E.cell] Xs
| Xs
