use gfx util

type tile{As Main Type Role Id Lineup Base Middle Top Plain
          height/1 empty/0 filler/1 invisible/0 tiling/corner shadow/0
          match/same anim_wait/0 water/0 bank/0 unit/0 heavy/1 clear/0
          parts/0 box/[64 64 h]}
     id/Id
     main/Main
     bank/Bank
     type/Type
     role/Role
     lineup/Lineup
     base/Base // column base
     middle/Middle // column segment
     top/Top // column top
     plain/Plain
     height/Height
     empty/Empty
     filler/Filler //true if tile fills space, matching with other tiles
     invisible/Invisible
     tiling/Tiling
     shadow/Shadow
     match/Match
     anim_wait/Anim_wait
     water/Water
     unit/Unit //used for units that act as platforms
     heavy/Heavy
     clear/Clear
     parts/Parts
     box/Box
| when $box.2><h: $box.2 <= $height*8
| less $parts:
  | if $height>1
    then | $parts <= @flip: map I $height-1
           | tile As Main Type Role Id Lineup Base Middle Top Plain
                 @[parts -(I+1) @As]
    else $parts <= []

transparentize Base Alpha =
| Empty = 255
| as R Base.copy
  | for [X Y] points{0 0 64 64}: when X^^1 >< Y^^1: R.set{X Y Empty}

DummyGfx = gfx 1 1

tile.render X Y Z Below Above Seed =
| P = X,Y
| World = $main.world
| when $invisible
  | World.set_slope_at{X Y Z #@1111}
  | leave DummyGfx
| BE = Below.empty
| BR = Below.role
| AH = Above.heavy
| AR = Above.role
| AFiller = AR >< filler
| NeibElevs = #@0000
| T = Me
| when $water:
  | Neib,Water = $water
  | when got World.neibs{X Y Z-$height+1}.find{?type><Neib}:
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
| World.set_slope_at{X Y Z if $tiling >< side then #@1111 else NeibElevs}
| less $anim_wait: G <= G.(Seed%G.size)
| leave G

main.tile_names Bank =
| $tiles{}{?1}.keep{?bank><Bank}{?type}.skip{$aux_tiles.?^got}.sort

main.load_tiles =
| BankNames = case $params.world.tile_banks [@Xs](Xs) X[X]
| $params.world.tile_banks <= BankNames 
| Tiles = t
| $aux_tiles <= t
| Frames = No
| T = $params.tile
| HT = T.height_
| for I 15: // object height blockers
  | T."h[I+1]_" <=
    | R = HT.deep_copy
    | R.height <= I+1
    | R
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
| Plain = Tiles.dirt.gfxes.#@1111.0
| $tiles <= t size/1024
| for K,V Tiles
  | Base,Middle,Top = if got V.stack then V.stack{}{Tiles.?.gfxes}
                      else | T = V.gfxes; [T T T]
  | Lineup = V.no_lineup^~{0}^not
  | Id = if K >< void then 0
         else | !$last_tid + 1
              | $last_tid
  | As = V.list.join
  | $tiles.K <=
    | tile As Me K V.role^~{K} Id Lineup Base Middle Top Plain @As

export tile
