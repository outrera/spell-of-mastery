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

type tile{Main Type Role Id Elev Trn Empty Tiling Lineup Renderer Ds Ms Us Trns Plain}
  main/Main type/Type role/Role id/Id elev/Elev trn/Trn empty/Empty tiling/Tiling
  neib_elevs/[0 0 0 0] lineup/Lineup renderer/Renderer
  ds/Ds ms/Ms us/Us trns/Trns plain/Plain

tile.slope = case $neib_elev
  []+[1 1 1 1]+[0 0 0 0] | 0
  _ | 16

TrnsCache = t

tile.render P Z Below Above Seed =
| when $renderer >< none: leave DummyGfx
| BE = Below.empty
| BR = Below.role
| AH = Above.heavy
| AR = Above.role
| APad = AR >< pad
| World = $main.world
| Gs = if BR <> $role then $ds
       else if AR <> $role and not APad then $us
       else $ms
| G = if $lineup and (AH or APad or AR >< $role)
        then | $neib_elevs.init{[1 1 1 1]}
             | Gs.$neib_elevs
      else | Elev = if $tiling >< side
                    then World.getSideElev{P Z}
                    else World.getCornerElev{P Z}
           | $neib_elevs.init{Elev{E => if E < $elev then 0 else 1}}
           | R = Gs.$neib_elevs
           | less got R
             | $neib_elevs.init{[1 1 1 1]}
             | R <= Gs.$neib_elevs
           | R
| G = G.(Seed%G.size)
| when not $trn or $neib_elevs <> [1 1 1 1]: leave G
| Cs = World.getCornerTrns{P Z $role}
| when Cs.all{1}: leave G
| Index = [Cs G^address $plain^address]
| as R TrnsCache.Index: less got R
  | R <= genTransition $trns.Cs.0 G $plain
  | TrnsCache.Index <= R
  | leave R

tile.heavy = not $empty

main.load_tiles =
| G = gfx "[$data]/til/gfx.png"
| Tiles = t
| $aux_tiles <= t
| cutTile N = G.cut{N%20*64 N/20*64 64 64}
| for [Type CornersElevation @Rest] cfg."[$data]/til/map.txt"
  | [Is As] = Rest.div{is.['/'@_]}.xs{0,1}{?^~{[]}}
  | CE = CornersElevation.digits.pad{-4 0}
  | less Is.size: bad "one of [Type] tiles misses gfxes"
  | Tile = Tiles->Type
  | Gs = case Is [stack @Is] | Tile.stack <= Is
                             | []
              Else | Is{&cutTile}
  | for X As{?tail}: case X
    [alpha Alpha] | Gs <= Gs{(transparentize ? Alpha)}
    [aux Value] | $aux_tiles.Type <= Value
    [Arg Value] | Tile.Arg <= Value
  | when Gs.size: Tile->gfxes.CE <= Gs
| Trns = Tiles.trns.gfxes
| Plain = Tiles.dirt.gfxes.[1 1 1 1].0
| $tiles <= t size/1024
| for [K V] Tiles
  | [Ds Ms Us] = case V.gfxes
                      T<1^got | [T T T]
                      Else | V.stack{}{Tiles.?.gfxes}
  | Lineup = V.no_lineup^~{0}^not
  | $tiles.K <= tile Me K V.role^~{K} V.id V.elev^~{1.0}
                     V.trn^~{0} V.empty^~{0} V.tiling Lineup V.renderer
                     Ds Ms Us Trns Plain

export tile
