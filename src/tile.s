use gfx util

type tile{Main Type Role Id Lineup Base Middle Top Trns Plain
          height/1 trn/0 empty/0 filler/1 invisible/0 tiling/corner shadow/0
          match/same stairs/0 anim_wait/0 water/0 bank/0}
     id/Id
     main/Main
     bank/Bank
     type/Type
     role/Role
     lineup/Lineup
     base/Base // column base
     middle/Middle // column segment
     top/Top // column top
     trns/Trns
     plain/Plain
     height/Height
     trn/Trn
     empty/Empty
     filler/Filler //true if tile fills space, matching with other tiles
     invisible/Invisible
     tiling/Tiling
     shadow/Shadow
     match/Match
     stairs/Stairs
     anim_wait/Anim_wait
     water/Water

TrnsCache = t


transparentize Base Alpha =
| Empty = 255
| as R Base.copy
  | for [X Y] points{0 0 64 64}: when X^^1 >< Y^^1: R.set{X Y Empty}

genTransition Mask From To =
| Empty = 255
| as R To.copy
  | for [X Y] points{0 0 64 32}
    | less Mask.get{X Y}^^#FF000000:
      | R.set{X Y From.get{X Y}}

DummyGfx = gfx 1 1

tile.render P Z Below Above Seed =
| World = $main.world
| when $invisible
  | World.set_slope_at{@P,Z #@1111}
  | leave DummyGfx
| BE = Below.empty
| BR = Below.role
| AH = Above.heavy
| AR = Above.role
| AFiller = AR >< filler
| NeibElevs = #@0000
| T = Me
| Water = $water
| when Water and got World.neibs{P.0 P.1 Z-$height+1}.find{?type><water}:
  | T <= $main.tiles.Water
| Gs = if BR <> $role then T.base
       else if AR <> $role and not AFiller then T.top
       else T.middle
| G = if $lineup and (AH or AFiller or AR >< $role)
      then | NeibElevs <= #@1111
           | Gs.NeibElevs
      else | Elev = if $match >< same
                    then if $tiling >< side
                         then World.getSidesSame{P Z $role}
                         else World.getCornersSame{P Z $role}
                    else if $tiling >< side
                         then World.getSides{P Z}
                         else World.getCorners{P Z}
           | NeibElevs <= Elev.digits{2}
           | R = Gs.NeibElevs
           | less got R
             | NeibElevs <= #@1111
             | R <= Gs.NeibElevs
           | R
| World.set_slope_at{@P,Z if $tiling >< side then #@1111 else NeibElevs}
| less $anim_wait: G <= G.(Seed%G.size)
| when when $anim_wait or not $trn or NeibElevs <> #@1111: leave G
| Cs = World.getCornersTrns{P Z $role}.digits{2}
| when Cs >< #@1111: leave G
| Index = [Cs G^address $plain^address]
| as R TrnsCache.Index: less got R
  | R <= genTransition $trns.Cs.0 G $plain
  | TrnsCache.Index <= R
  | leave R

// returns 1 if this tile compresses the shape of tile below of it
tile.heavy = not $empty

main.tile_names Bank =
| $tiles{}{?1}.keep{?bank><Bank}{?type}.skip{$aux_tiles.?^got}.sort

main.load_tiles =
| BankNames = case $params.world.tile_banks [@Xs](Xs) X[X]
| $params.world.tile_banks <= BankNames 
| Tiles = t
| $aux_tiles <= t
| Frames = No
| Es = [1111 1000 1100 1001 0100 0001 0110 0011
        0010 0111 1011 1101 1110 1010 0101 0000]
| for Bank BankNames: for Type,Tile $params.Bank
  | Tile.bank <= Bank
  | Tiles.Type <= Tile
  | when got Tile.aux: $aux_tiles.Type <= Tile.aux
  | SpriteName = Tile.sprite
  | Sprite = $sprites.SpriteName
  | less got Sprite: bad "Tile [Type] references missing sprite [SpriteName]"
  | Frames = Sprite.frames
  | NFrames = Frames.size
  | Tile.gfxes <= dup 16 No
  | for CornersElevation Es: when got!it Tile.CornersElevation:
    | E = CornersElevation.digits.digits{2}
    | Is = if it.is_list then it else [it]
    | Gs = map I Is
           | less I < NFrames:
             | bad "Tile `[Type]` wants missing frame [I] in `[SpriteName]`"
           | Frames.I
    | when got!a Tile.alpha: Gs <= Gs{(transparentize ? a)}
    | when Gs.size: Tile.gfxes.E <= Gs
| Trns = Tiles.trns.gfxes
| Plain = Tiles.dirt.gfxes.#@1111.0
| $tiles <= t size/1024
| for K,V Tiles
  | [Base Middle Top] = if got V.stack then V.stack{}{Tiles.?.gfxes}
                        else | T = V.gfxes; [T T T]
  | Lineup = V.no_lineup^~{0}^not
  | Id = if K >< void then 0
         else | !$last_tid + 1
              | $last_tid
  | $tiles.K <= tile Me K V.role^~{K} Id Lineup Base Middle Top Trns Plain
                     @V.list.join

export tile
