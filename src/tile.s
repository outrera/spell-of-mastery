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

type tile{Main Type Role Id Lineup Ds Ms Us Trns Plain
          height/1 trn/0 empty/0 invisible/0 tiling/corner shadow/0}
     id/Id
     main/Main
     type/Type
     role/Role
     lineup/Lineup
     ds/Ds
     ms/Ms
     us/Us
     trns/Trns
     plain/Plain
     height/Height
     trn/Trn
     empty/Empty
     invisible/Invisible
     tiling/Tiling
     shadow/Shadow

TrnsCache = t

tile.render P Z Below Above Seed =
| BE = Below.empty
| BR = Below.role
| AH = Above.heavy
| AR = Above.role
| AFiller = AR >< filler
| World = $main.world
| NeibElevs = #@0000
| Gs = if BR <> $role then $ds
       else if AR <> $role and not AFiller then $us
       else $ms
| G = if $lineup and (AH or AFiller or AR >< $role)
      then | NeibElevs <= #@1111
           | Gs.NeibElevs
      else | Elev = if $tiling >< side
                    then World.getSideElev{P Z}
                    else World.getCornerElev{P Z}
           | NeibElevs <= Elev{E => if E < $height then 0 else 1}.digits{2}
           | R = Gs.NeibElevs
           | less got R
             | NeibElevs <= #@1111
             | R <= Gs.NeibElevs
           | R
| World.set_slope_at{@P,Z if $tiling >< side then #@1111 else NeibElevs}
| G = G.(Seed%G.size)
| when not $trn or NeibElevs <> #@1111: leave G
| Cs = World.getCornerTrns{P Z $role}.digits{2}
| when Cs >< #@1111: leave G
| Index = [Cs G^address $plain^address]
| as R TrnsCache.Index: less got R
  | R <= genTransition $trns.Cs.0 G $plain
  | TrnsCache.Index <= R
  | leave R

// returns 1 if this tile compresses the shape of tile below of it
tile.heavy = not $empty


main.load_tiles =
| Tiles = t
| $aux_tiles <= t
| Frames = No
| Es = [1111 1000 1100 1001 0100 0001 0110 0011
        0010 0111 1011 1101 1110 1010 0101 0000]
| for Type,Tile $params.tile
  | Tiles.Type <= Tile
  | when got Tile.aux: $aux_tiles.Type <= Tile.aux
  | Frames = $sprites.(Tile.sprite).frames
  | Tile.gfxes <= dup 16 No
  | for CornersElevation Es: when got!it Tile.CornersElevation:
    | E = CornersElevation.digits.digits{2}
    | Is = if it.is_list then it else [it]
    | Gs = Is{Frames.?}
    | when got!a Tile.alpha: Gs <= Gs{(transparentize ? a)}
    | when Gs.size: Tile.gfxes.E <= Gs
| Trns = Tiles.trns.gfxes
| Plain = Tiles.dirt.gfxes.#@1111.0
| $tiles <= t size/1024
| for K,V Tiles
  | [Ds Ms Us] = if got V.stack then V.stack{}{Tiles.?.gfxes}
                 else | T = V.gfxes; [T T T]
  | Lineup = V.no_lineup^~{0}^not
  | Id = if K >< void then 0
         else | !$last_tid + 1
              | $last_tid
  | $tiles.K <= tile Me K V.role^~{K} Id Lineup Ds Ms Us Trns Plain
                     @V.list.join

export tile
