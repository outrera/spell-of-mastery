use queue util fxn

land_can_move1 Me Src Dst =
| H = fxn Dst.z-Src.z
| fxn: when H > 1 or H < -1: leave 0
| Dst.tile.empty and not (fxn Dst-1).tile.liquid

land_can_move2 Me Src Dst =
| H = fxn Dst.z-Src.z
| fxn: when H > 1 or H < -1: leave 0
| Dst.tile.empty and (fxn Dst+1).tile.empty
  and not (fxn Dst-1).tile.liquid

amphibian_can_move1 Me Src Dst =
| H = fxn Dst.z-Src.z
| fxn: when H > 1 or H < -1: leave 0
| Dst.tile.empty

amphibian_can_move2 Me Src Dst =
| H = fxn Dst.z-Src.z
| fxn: when H > 1 or H < -1: leave 0
| Dst.tile.empty and (fxn Dst+1).tile.empty

swimmer_can_move1 Me Src Dst =
| H = fxn Dst.z-Src.z
| fxn: when H > 1 or H < -1: leave 0
| Dst.tile.empty and (fxn Dst-1).tile.type><water

swimmer_can_move2 Me Src Dst =
| H = fxn Dst.z-Src.z
| fxn: when H > 1 or H < -1: leave 0
| Dst.tile.empty and (fxn Dst+1).tile.empty
  and (fxn Dst-1).tile.type><water

flyer_can_move1 Me Src Dst =
| less Dst.tile.empty: leave 0
| SZ = Src.z
| DZ = Dst.z
| fxn: if SZ<DZ
  then | fxn: when DZ > $site.d-3: leave 0
       | times I DZ-SZ: less (Src+I).tile.empty: leave 0
  else times I SZ-DZ: less (Dst+I).tile.empty: leave 0
| 1

flyer_can_move2 Me Src Dst =
| less Dst.tile.empty: leave 0
| SZ = Src.z
| DZ = Dst.z
| fxn: if SZ<DZ
  then | fxn: when DZ > $site.d-3: leave 0
       | times I DZ-SZ: less (Src+I).tile.empty: leave 0
  else times I SZ-DZ: less (Dst+I).tile.empty: leave 0
| (fxn Dst+1).tile.empty

climber_can_move1 Me Src Dst =
| less Dst.tile.empty: leave 0
| when (fxn Dst-1).tile.liquid: leave 0
| SZ = Src.z
| DZ = Dst.z
| fxn: if SZ<DZ
  then | when DZ-SZ > 3: leave 0
       | when DZ > $site.d-3: leave 0
       | times I DZ-SZ: less (Src+I).tile.empty: leave 0
  else | when SZ-DZ > 3: leave 0
       | times I SZ-DZ: less (Dst+I).tile.empty: leave 0
| 1

climber_can_move2 Me Src Dst =
| less Dst.tile.empty: leave 0
| when (fxn Dst-1).tile.liquid: leave 0
| SZ = Src.z
| DZ = Dst.z
| fxn: if SZ<DZ
  then | when DZ-SZ > 3: leave 0
       | when DZ > $site.d-3: leave 0
       | times I DZ-SZ: less (Src+I).tile.empty: leave 0
  else | when SZ-DZ > 3: leave 0
       | times I SZ-DZ: less (Dst+I).tile.empty: leave 0
| (fxn Dst+1).tile.empty

//FIXME: this can be optimized to a table lookup,
// if all movement bits are place near in the $flags
unit.update_move_method =
| $can_move <=
   if fxn $height><1 then
     if $flyer then &flyer_can_move1
     else if $amphibian then &amphibian_can_move1
     else if $swimmer then &swimmer_can_move1
     else if $climber then &climber_can_move1
     else &land_can_move1
   else
     if $flyer then &flyer_can_move2
     else if $amphibian then &amphibian_can_move2
     else if $swimmer then &swimmer_can_move2
     else if $climber then &climber_can_move2
     else &land_can_move2


//note: here order is important, or path will go zig-zag
//Dirs = [[-1 -1] [1 1] [1 -1] [-1 1] [0 -1] [1 0] [0 1] [-1 0]]

unit.list_moves Src Cost =
| Ms = []
| CanMove = $can_move
| Flying = $flying
| for Dst Src.neibs
  | Dst <= Dst.floor
  | when Cost < Dst.cost and CanMove{Me Src Dst}:
    | B = (fxn Dst+Flying).block
    | fxn: when B><0 or B.hp>0: push Dst Ms
| Ms

PFQueue = queue 256*256

site.pathfind MaxCost U StartCell Check =
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
  | NextCost = fxn Cost+1
  | Ms = U.list_moves{Src NextCost}
  | when Src.gate:
    | when Src.prev and fxn Src.prev.xyz.mdist{Src.xyz}><1:
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
    | when fxn NextCost<MaxCost: PFQueue.push{Dst}
    | _label skip
| _label end
//| EndTime = clock
//| say EndTime-StartTime
| R

site.closest_reach MaxCost U StartCell TargetXYZ =
| less U.speed: leave 0
| X,Y,Z = StartCell.xyz
| TX,TY,TZ = TargetXYZ
| TCell = $cell{@TargetXYZ}
| BestL = [TX-X TY-Y].abs
| Best = 0
| Flying = U.flying
| check Dst =
  | R = 0
  | DX,DY,DZ = Dst.xyz
  | NewL = [TX-DX TY-DY]^fxn.abs
  | when BestL>>NewL and (BestL>NewL or fxn TZ><DZ):
    | BestL <= NewL
    | Best <= Dst
    | when BestL < 1.4:
      | when fxn Best><TCell: | R <= 1; _goto end
      | less TCell.tile.empty: | R <= 1; _goto end
      | B = (fxn TCell+Flying).block
      | when B:
        | less B.speed: | R <= 1; _goto end
        | when not U.atk and U.is_enemy{B}: | R <= 1; _goto end
  | _label end
  | R
| $pathfind{MaxCost U StartCell &check}
| Best

site.seen_cells_search MaxCost StartCell Check =
| X,Y,Z = StartCell.xyz
| StartCost = $new_cost
| MaxCost+=StartCost
| StartCell.cost <= StartCost
| PFQueue.reset
| PFQueue.push{StartCell}
| R = 0
| till PFQueue.end
  | Src = PFQueue.pop
  | Cost = Src.cost
  | NextCost = fxn Cost+1
  | for Dst Src.neibs
    | Dst <= Dst.floor
    | when NextCost < Dst.cost:
      | when Check Dst:
        | Dst.cost <= NextCost
        | when fxn NextCost<MaxCost: PFQueue.push{Dst}

site.find MaxCost U StartCell Check =
| Found = $pathfind{MaxCost U StartCell Check}
| if Found then Found else 0

unit.find MaxCost Check = $site.find{MaxCost Me $cell Check}

unit.pathfind MaxCost Check = $site.pathfind{MaxCost Me $cell Check}

unit.path_to XYZ =
| Target = $site.cellp{XYZ}
| Found = $site.pathfind{1000 Me $cell ?><Target}
| if Found then Found.path else []

// returns path to closest reachable point near XYZ
unit.path_near XYZ =
| Found = $site.closest_reach{1000 Me $cell XYZ}
| if Found then Found.path else []

unit.path_around_to Range XYZ = //Me is unit
| Target = $site.cell{@XYZ}
| check Dst =
  | if Dst><Target then 1
    else if $block_at{Dst} then \block
    else if $threatened_at{Dst} and XYZ.mdist{Dst.xyz}<>1 then \block
    else 0
| Found = $pathfind{Range &check}
| if Found then Found.path else []

unit.enemies_in_range =
| O = $owner
| check B =
  | when O.is_enemy{B.owner} and not B.invisible:
    | when $flying><B.flying: leave 1
  | 0
| $units_in_range{$range}.keep{&check}

unit.enemies_in_sight =
| O = $owner
| check B =
  | when O.is_enemy{B.owner} and not B.invisible and O.seen_cell{B.cell}:
    | when $flying><B.flying: leave 1
  | 0
| $units_in_range{$sight}.keep{&check}

unit.nearby_enemies_at Cell =
| Es = []
| for C Cell.neibs: for U C.floor.units: when $is_enemy{U}: push U Es
| Es

unit.reachable_nearby_enemies_at Cell =
| $nearby_enemies_at{Cell}.skip{?invisible}.keep{?flying><$flying}

path_len Cell =
| C = 0
| while Cell
  | C += 1
  | Cell <= Cell.prev
| C

unit.attack_cost = if $afraid then 9000 else 1
unit.jump_cost = 1

can_jump Src Dst = Dst.empty and fxn Dst.floor-Dst>1

unit.can_attack Src Dst = $atk and (fxn (Dst.z-Src.z) << 1 or $can_move{}{Me Src Dst})

unit.reachable_at Cell Moves =
| Xs = []
| when fxn Moves<1: leave Xs
| Flying = $flying
| less $engaged: $site.find{$moves Me Cell
  | Dst =>
    | R = \block
    | Type = \move
    | D = Dst+Flying
    | B = D.block
    | if not B then R <= 0
      else if $owner.is_enemy{B.owner} then
        if B.invisible then R <= 0
        else Type <= 0
      else if B.moves<1 /*or B.engaged*/ then Type <= 0
      else Type <= \swap
    | when Type: push [Type Dst] Xs
    | less R or Type><swap:
      | when $threatened_at{Dst}:
        | R <= \block //engage
      | for E $reachable_nearby_enemies_at{Dst}:
        | when $range><1 and not $afraid and Moves >> Dst^path_len+1:
          | when $can_attack{Dst E.cell}: push [attack E.cell] Xs
    | R}
| less $flyer or $climber: for N Cell.neibs: when N.empty:
  | F = N.floor
  | less F.block:
    | when fxn N-F>1 and fxn Moves>>$jump_cost:
      | less got Xs.find{?1><F}: push [jump F] Xs
| when fxn Moves<1 or $afraid: leave Xs
| when fxn $range><1:
  | for E $enemies_in_range:
    | when $can_attack{$cell E.cell}: push [attack E.cell] Xs
| when fxn $range>1:
  | for E $enemies_in_range: push [attack E.cell] Xs
| Xs

unit.reachable = $reachable_at{$cell $moves}
