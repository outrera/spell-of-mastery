use gfx util

transparentize Base Alpha =
| Empty = 255
| as R Base.copy
  | for [X Y] points{0 0 64 64}: when X^^1 >< Y^^1: R.set{X Y Empty}

DummyGfx = gfx 1 1

genTransition Mask From To =
| Empty = 255
| as R To.copy
  | for [X Y] points{0 0 64 32}
    | less Mask.get{X Y} >< Empty
      | R.set{X Y From.get{X Y}}

type tile{Main Type Role Id Elev Trn Empty Tiling Lineup Renderer
          Ds Ms Us Trns Plain}
     id/Id
     main/Main
     type/Type
     role/Role
     elev/Elev
     trn/Trn
     empty/Empty
     tiling/Tiling
     lineup/Lineup
     renderer/Renderer
     ds/Ds
     ms/Ms
     us/Us
     trns/Trns
     plain/Plain

TrnsCache = t

tile.render P Z Below Above Seed =
| when $renderer >< none: leave DummyGfx
| BE = Below.empty
| BR = Below.role
| AH = Above.heavy
| AR = Above.role
| APad = AR >< pad
| World = $main.world
| NeibElevs = [0 0 0 0]
| Gs = if BR <> $role then $ds
       else if AR <> $role and not APad then $us
       else $ms
| G = if $lineup and (AH or APad or AR >< $role)
        then | NeibElevs.init{[1 1 1 1]}
             | Gs.NeibElevs
      else | Elev = if $tiling >< side
                    then World.getSideElev{P Z}
                    else World.getCornerElev{P Z}
           | NeibElevs.init{Elev{E => if E < $elev then 0 else 1}}
           | R = Gs.NeibElevs
           | less got R
             | NeibElevs.init{[1 1 1 1]}
             | R <= Gs.NeibElevs
           | R
| World.slope_map.set{@P,Z NeibElevs^|$1 [0 0 0 0]+[1 1 1 1] => 0}
| G = G.(Seed%G.size)
| when not $trn or NeibElevs <> [1 1 1 1]: leave G
| Cs = World.getCornerTrns{P Z $role}
| when Cs.all{1}: leave G
| Index = [Cs G^address $plain^address]
| as R TrnsCache.Index: less got R
  | R <= genTransition $trns.Cs.0 G $plain
  | TrnsCache.Index <= R
  | leave R

tile.heavy = not $empty


main.load_tiles =
| Tiles = t
| $aux_tiles <= t
| Frames = No
| Es = [1111 1000 1100 1001 0100 0001 0110 0011
        0010 0111 1011 1101 1110 1010 0101 0000]
| for K,Tile $params: case K "tile_[Type]"
  | Tiles.Type <= Tile
  | when got Tile.aux: $aux_tiles.Type <= Tile.aux
  | Frames = $sprites.(Tile.sprite).frames
  | for CornersElevation Es: when got!it Tile.CornersElevation:
    | Is = if it.is_list then it else [it]
    | CE = CornersElevation.digits.pad{-4 0}
    | Gs = Is{Frames.?}
    | when got!a Tile.alpha: Gs <= Gs{(transparentize ? a)}
    | when Gs.size: Tile->gfxes.CE <= Gs
| Trns = Tiles.trns.gfxes
| Plain = Tiles.dirt.gfxes.[1 1 1 1].0
| $tiles <= t size/1024
| for K,V Tiles
  | [Ds Ms Us] = if got V.stack then V.stack{}{Tiles.?.gfxes}
                 else | T = V.gfxes; [T T T]
  | Lineup = V.no_lineup^~{0}^not
  | $tiles.K <= tile Me K V.role^~{K} V.id V.elev V.trn V.empty V.tiling
                     Lineup V.renderer Ds Ms Us Trns Plain

export tile
