use util heap widgets param sprite class tile world update ui save generate

XUnit = No
YUnit = No
ZUnit = No
YDiv = No

draw_cursor V Front FB X Y H =
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

render_pilar Wr X Y BX BY Heap CursorXY CursorZ =
| BY = BY + 32
| Gs = Wr.gfxes.X.Y
| CurX = CursorXY.0
| CurY = CursorXY.1
| CurH = (CurX+CurY)/2
| XY2 = (X+Y)/2
| AboveCursor = CurH >> XY2
| CurHH = XY2-CurH-2
| Cursor = same X CurX and Y >< CurY
| Z = 0
| UnitZ = 0
| Key = ((X+Y)</20) + X
| for G Gs: if G.is_int
  then | when Cursor
         | BY = BY-YUnit-Z*ZUnit
         | Key = Key + (Z</10)
         | Heap.push{Key [G BX BY #4000+(G</16)]}
         | Heap.push{Key+1 [G BX BY #8000+(G</16)]}
       | !Z+G
  else | T = Wr.tid_map.(Wr.get{X Y Z})
       | TH = T.height
       | ZZ = Z*ZUnit
       | Key = Key + (Z</10)
       | when Cursor | Heap.push{Key-1 [G BX BY-YUnit-ZZ #4000+(TH</16)]}
       | UnitZ <= Z + TH
       | when AboveCursor or Z << CursorZ or CurHH-Z/YDiv >> 0:
         | Heap.push{Key [G BX BY-G.h-ZZ 0]}
         | for U Wr.units_at{X,Y,UnitZ}: U.render{Heap BX BY-ZUnit*UnitZ}
       | when Cursor | Heap.push{Key+1 [G BX BY-YUnit-ZZ #8000+(TH</16)]}
       | Z <= UnitZ
| for U Wr.column_units_at{X Y}
  | Z = U.xyz.2
  // FIXME: should we always display flying units? even underground?
  | when Z > UnitZ
    | !Z+1
    | U.render{Heap BX BY-ZUnit*Z-ZUnit}
    | S = Wr.shadows.(2-min{(@abs (Z-UnitZ)/2-2) 2})
    | Key = Key + (UnitZ</10) + 1
    | Heap.push{Key [S BX-S.w/2+32 BY-S.h-UnitZ*ZUnit 0]}

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
      | render_pilar Wr X Y BX BY Heap $cell_xy $cell_z
      //| Key = (X+Y)*WW*WH+X
      //| Heap.push{Key [Gs.0 BX BY 0]}
//| Font = font small
//| Order = 0
| while!it Heap.pop:
  | [G BX BY F] = it.value
  | BX = TX + BX
  | BY = TY + BY
  | if F then // check flags
     | when F ^^ #2
       | FB.rect{#00FF00 0 BX BY G.w G.h}
       | !F -- #2
     | if F ^^ #1 then FB.blit{BX,BY G flipX/1}
       else if F ^^ #4000 then draw_cursor{#FF0000 0 FB BX BY F/>16}
       else if F ^^ #8000 then draw_cursor{#00FF00 1 FB BX BY F/>16}
       else FB.blitRaw{BX BY G}
    else FB.blitRaw{BX BY G}
  //| Font.draw{FB BX+18 BY+4 red "[Order]"}
  //| !Order+1


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
