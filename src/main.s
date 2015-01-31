use util heap widgets param sprite class tile world update ui save generate

XUnit = No
YUnit = No
ZUnit = No
YDiv = No

draw_pick V Front FB X Y H =
| !H*ZUnit
| !Y - H
| !Y - 2
| !Y+YUnit/2
| A = [X Y]
| B = [X+XUnit/2 if Front then y+YUnit/2 else Y-YUnit/2]
| C = [X+XUnit Y]
| FB.line{V A B}
| FB.line{V B C}
| FB.line{V A+[0 H] B+[0 H]}
| FB.line{V B+[0 H] C+[0 H]}
| FB.line{V A A+[0 H]}
| FB.line{V B B+[0 H]}
| FB.line{V C C+[0 H]}

render_pilar Wr X Y BX BY FB CursorXY CursorZ =
| BY = BY + 32
| Gs = Wr.gfxes.X.Y
| CurX = CursorXY.0
| CurY = CursorXY.1
| CurH = (CurX+CurY)/2
| CurHH = CurH+2
| Cursor = same X CurX and Y >< CurY
| Z = 0
| UnitZ = 0
//| TileShadow = Wr.main.sprites.system_tile_shadow.frames.0
| for G Gs: if G.is_int
  then | when Cursor
         | draw_pick{#FF0000 0 FB BX BY-YUnit-Z*ZUnit G}
         | draw_pick{#00FF00 1 FB BX BY-YUnit-Z*ZUnit G}
       | !Z+G
  else | T = Wr.tid_map.(Wr.get{X Y Z})
       | TH = T.height
       | ZZ = Z*ZUnit
       | when Cursor | draw_pick{#FF0000 0 FB BX BY-YUnit-ZZ TH}
       | XY2 = (X+Y)/2
       | when CurH >> XY2 or Z << CursorZ or XY2-CurHH-Z/YDiv >> 0:
         | FB.blitRaw{BX BY-G.h-ZZ G}
       //| when T.shadow and Wr.slope_at{X+1,Y,Z+TH*2-1} >< #@1111:
       //  | FB.blit{[BX BY-G.h-ZZ] TileShadow}
       | UnitZ <= Z + TH
       //| for U Wr.units_at{X,Y,UnitZ}: U.render{FB BX BY-ZUnit*UnitZ}
       | when Cursor | draw_pick{#00FF00 1 FB BX BY-YUnit-ZZ TH}
       | Z <= UnitZ
| for U Wr.column_units_at{X Y}
  | Z = U.xyz.2
  | when Z > UnitZ
    | !Z+1
    | U.render{FB BX BY-ZUnit*Z+ZUnit}
    | S = Wr.shadows.(2-min{(Z-UnitZ)/2-2 2})
    | FB.blit{[BX-S.w/2+32 BY-S.h-UnitZ*ZUnit] S}


view.render_iso = 
| Wr = $world
| XUnit <= Wr.xunit
| YUnit <= Wr.yunit
| ZUnit <= Wr.zunit
| XUnit = XUnit
| YUnit = YUnit
| ZUnit = ZUnit
| YDiv <= YUnit/ZUnit
| FB = $fb
| Z = if $mice_left or $mice_right then $mice_z else $cell_z
| BlitOrigin = [$w/2 170]
| TX,TY = $blit_origin+[0 Z]%YDiv*ZUnit
| VX,VY = $view_origin-[Z Z]/YDiv
| Heap = heap
| Gfxes = Wr.gfxes
| WW = Wr.w
| WH = Wr.h
| VS = $view_size
| XUnit2 = XUnit/2
| YUnit2 = YUnit/2
| times YY VS
  | Y = YY + VY
  | when 0<<Y and Y<WH: times XX VS:
    | X = XX + VX
    | when 0<<X and X<WW: // FIXME: moved this out of the loop
      | Gs = Gfxes.X.Y
      | BX = XX*XUnit2 - YY*XUnit2
      | BY = XX*YUnit2 + YY*YUnit2
      | Key = (X+Y)*WW*WH+X
      | Heap.push{Key [BX BY Gs.0]}
| F = font small
| Order = 0
| while!it Heap.pop:
  | [BX BY G] = it.value
  | BX = TX + BX
  | BY = TY + BY-G.h
  | FB.blitRaw{BX BY G}
  //| F.draw{FB BX+18 BY+4 red "[Order]"}
  | !Order+1


/*
draw_pick V Front FB X Y H =
| !H*ZUnit
| !Y - H
| !Y - 2
| !Y+YUnit/2
| A = [X Y]
| B = [X+XUnit/2 if Front then Y+YUnit/2 else Y-YUnit/2]
| C = [X+XUnit Y]
| FB.line{V A B}
| FB.line{V B C}
| FB.line{V A+[0 H] B+[0 H]}
| FB.line{V B+[0 H] C+[0 H]}
| FB.line{V A A+[0 H]}
| FB.line{V B B+[0 H]}
| FB.line{V C C+[0 H]}

world.drawPilar X Y BX BY FB CursorXY CursorZ =
| when X < 0 or X >> $size: leave 0
| when Y < 0 or Y >> $size: leave 0
| !BY + 32
| Gs = $gfxes.X.Y
| CurX = CursorXY.0
| CurY = CursorXY.1
| CurH = (CurX+CurY)/2
| CurHH = CurH+2
| Cursor = same X CurX and Y >< CurY
| Z = 0
| UnitZ = 0
//| TileShadow = $main.sprites.system_tile_shadow.frames.0
| for G Gs: if G.is_int
  then | when Cursor
         | draw_pick #FF0000 0 FB BX BY-YUnit-Z*ZUnit G
         | draw_pick #00FF00 1 FB BX BY-YUnit-Z*ZUnit G
       | !Z+G
  else | T = $tid_map.($get{X Y Z})
       | TH = T.height
       | ZZ = Z*ZUnit
       | when Cursor | draw_pick #FF0000 0 FB BX BY-YUnit-ZZ TH
       | XY2 = (X+Y)/2
       | when CurH >> XY2 or Z << CursorZ or XY2-CurHH-Z/YZUnit >> 0:
         | FB.blitRaw{BX BY-G.h-ZZ G}
       //| when T.shadow and $slope_at{X+1,Y,Z+TH*2-1} >< #@1111:
       //  | FB.blit{[BX BY-G.h-ZZ] TileShadow}
       | UnitZ <= Z + TH
       | for U $units_at{X,Y,UnitZ}: U.render{FB BX BY-ZUnit*UnitZ}
       | when Cursor | draw_pick #00FF00 1 FB BX BY-YUnit-ZZ TH
       | Z <= UnitZ
| for U $column_units_at{X Y}
  | Z = U.xyz.2
  | when Z > UnitZ
    | !Z+1
    | U.render{FB BX BY-ZUnit*Z+ZUnit}
    | S = $shadows.(2-min{(Z-UnitZ)/2-2 2})
    | FB.blit{[BX-S.w/2+32 BY-S.h-UnitZ*ZUnit] S}
*/

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

say 'Goodbye!'
