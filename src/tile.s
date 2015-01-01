use gfx util

transparentize Base Alpha =
| Empty = rgba 0 0 0 255
| as R Base.copy
  | for [X Y] points{0 0 64 64}: when X^^1 >< Y^^1: R.set{X Y Empty}

GetSideElev =
GetCornerElev =
GetCornerTrns =
DummyGfx = gfx 1 1

genTransition M F T = //Mask From To
| Alpha = rgba 0 0 0 255
| as R T.copy
  | for [X Y] points{0 0 64 32}: less M.get{X Y} >< Alpha: R.put{X Y F.get{X Y}}

type tile{Type Role Id Elev Trn Empty Tiling Lineup Renderer Ds Ms Us Trns Base}
  type/Type role/Role id/Id elev/Elev trn/Trn empty/Empty tiling/Tiling neib_elevs/[0 0 0 0]
  lineup/Lineup renderer/Renderer ds/Ds ms/Ms us/Us trns/Trns base/Base

tile.slope = case $neib_elev
  []+[1 1 1 1]+[0 0 0 0] | 0
  _ | 16

tile.render P Z D U S = if $renderer >< none then DummyGfx else
| DE = D.empty
| DR = D.role
| UH = U.heavy
| UR = U.role
| UPad = UR >< pad
| Gs = if DR <> $role then $ds
       else if UR <> $role and not UPad then $us
       else $ms
| G = if $lineup and (UH or UPad or UR >< $role)
        then | $neib_elevs.init{[1 1 1 1]}
             | Gs.$neib_elevs
      else | World = $main.worl
           | Elev = if $tiling >< side then World.getSideElev{P Z} else World.getCornerElev{P Z}
           | $neib_elevs.init{Elev{E => if E < $elev then 0 else 1}}
           | R = Gs.$neib_elevs
           | less got R
             | Gs.$neib_elevs.init{[1 1 1 1]}
             | R <= Gs.$neib_elevs
           | R
| G = G.(S%G.len)
| when not $trn or $neib_elevs <> [1 1 1 1]: leave G
| Rs = GetCornerTrns{P Z $role}
| when Rs.all{1}: leave G
| genTransition $trns.Rs.0 G $base

tile.heavy = not $empty

main.load_tiles =
| G = gfx "[$data]/til/gfx.png"
| Tiles = t
| $aux_tiles <= t
| cutTile N = G.cut{N%20*64 N/20*64 64 64}
| for [Type CornersElevation @Rest] cfg."[$data]/til/map.txt"
  | [Is As] = Rest.div{is.['/'@_]}.xs{0,1}{?^~{[]}}
  | CE = CornersElevation.digits.pad{4 0}
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
| Base = Tiles.base.gfxes.[1 1 1 1].0
| $tiles <= t size/1024
| for [K V] Tiles
  | [Ds Ms Us] = case V.gfxes
                      T<1^got | [T T T]
                      Else | V.stack{}{Tiles.?.gfxes}
  | $tiles.K <= tile K V.role^~{K} V.id V.elev^~{1}
                     V.trn V.empty V.tiling V.no_lineup^~{0}^not V.renderer
                     Ds Ms Us Trns Base

export tile

