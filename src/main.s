use util heap widgets param sprite class tile world update ui save generate

/*
view.viewToWorld P =
| [X Y] = P - $blit_origin - [0 $main.params.world.z_unit*4]
| !X - 32
| WH = TileW*TileH
| RX = (Y*TileW + X*TileH)/WH
| RY = (Y*TileW - X*TileH)/WH
| [RX RY] = [RX RY] + $view_origin
| S = $world.size
| [RX.clip{0 S-1} RY.clip{0 S-1}]
*/

view.render_iso = 
| Wr = $world
| TileW = Wr.xunit
| TileH = Wr.yunit
| FB = $fb
| WorldParams = $main.params.world
| ZUnit = WorldParams.z_unit
| YDiv = WorldParams.y_unit/ZUnit
| Z = if $mice_left or $mice_right then $mice_z else $cell_z
| BlitOrigin = [$w/2 170]
| TX,TY = $blit_origin+[0 Z]%YDiv*ZUnit
| VX,VY = $view_origin-[Z Z]/YDiv
| Heap = heap
| Gfxes = Wr.gfxes
| WW = Wr.w
| WH = Wr.h
| VS = $view_size
| times I VS*VS
  | XX = I%VS
  | YY = I/VS
  | X = XX + VX
  | Y = YY + VY
  | less X<0 or X>>WW or Y<0 or Y>>WH: // FIXME: moved these out of loop
    | Gs = Gfxes.X.Y
    | BX = (XX*TileW - YY*TileW)/2
    | BY = (XX*TileH + YY*TileH)/2
    | Heap.push{(X+Y)*WW*WH+X [X Y BX BY Gs.0]}
| F = font small
| Order = 0
| while!it Heap.pop:
  | [X Y BX BY G] = it.value
  //| say [X Y BX BY]
  | BX = TX + BX
  | BY = TY + BY-G.h
  | FB.blitRaw{BX BY G}
  //| F.draw{FB BX+18 BY+4 blue "[X],[Y]"}
  | F.draw{FB BX+18 BY+4 red "[Order]"}
  | !Order+1

type main{Data}
     world
     data/Data
     cache/(t)
     params
     sprites
     classes // object classes
     classes_banks
     bank_names
     tiles 
     acts
     editor_types
     last_tid
     tid_map
     aux_tiles
| $load_params
| for K,V $params.main: $params.K <= V
| $load_sprites
| $load_classes
| $load_tiles
| $tid_map <= dup $last_tid+1 0
| for [Type Tile] $tiles: $tid_map.(Tile.id) <= Tile
| $bank_names <= $classes{}{?1}{?bank}.uniq.sort
| $classes_banks <= @table: map N $bank_names
  | N,$classes{}{?1}.keep{(?bank >< N and not ?aux)}{?class_name}.sort
| world Me 16

main.img Name =
| S = $sprites."[Name]"
| less got S: bad "missing image `[Name]`"
| S.frames.0

main.spr Name =
| S = $sprites."[Name]"
| less got S: bad "missing sprite `[Name]`"
| S

@run: main: main_root

say 'Succeed!'
