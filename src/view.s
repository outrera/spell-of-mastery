use gui util widgets

type view.widget{M UI W H}
  main/M
  fb // frame buffer
  ui/UI
  w/W
  h/H
  frame
  paused
  keys/(t)
  view_origin/[0 0]
  blit_origin/[W/2 -170]
  mice_click
  mice_xy/[0 0]
  mice_xy_anchor/[0 0]
  cursor/[1 1 1]
  anchor/[1 1 1]
  brush/[0 0]
  pick
  pick_count // used to pick different units from the same cell
  infoText/txt{small info}
  fps/1
  fpsT/0.0
  fpsGoal/24 // goal frames per second
  fpsD/30.0
  param
  view_size/32  // render 32x32 world chunk
  center/[0 0 0]
  zfix/1
  zlock/0
  zbuffer/0
  xunit
  yunit
  zunit
| $fpsGoal <= $main.params.ui.fps
| $fpsD <= $fpsGoal.float+8.0
| $param <= $main.params.ui
| Wr = $world
| Wr.view <= Me
| WParam = $main.params.world
| $xunit <= WParam.tile_w
| $yunit <= WParam.tile_h
| $zunit <= WParam.tile_d
| $fpsT <= clock

view.mode = $world.mode
view.`!mode` V = $world.mode <= V

view.player = $world.human

view.picked = $player.picked
view.`!picked` Us = $player.picked <= Us

view.clear =
| $zlock <= 0
| $zfix <= 1
| $center_at{[0 0 0]}
| $blit_origin.init{[$w/2 -170]}
| $mice_xy.init{[0 0]}
| $mice_xy_anchor.init{[0 0]}
| $cursor.init{[1 1 1]}
| $anchor.init{[1 1 1]}
| $mice_click <= 0
| $pick_count <= 0
| Leader = $player.units.find{?leader}
| when got Leader: $center_at{Leader.xyz}

view.center_at XYZ cursor/0 =
| X,Y,Z = XYZ
| X = X.clip{1 $world.w}
| Y = Y.clip{1 $world.h}
| Z = Z.clip{1 64}
| $center.init{X,Y,Z}
| when Cursor: $zlock <= Z
| when Cursor: $cursor.init{X,Y,Z}
| VO = -[$h/32 $h/32]+[X Y]-[Z/8 Z/8]+[6 6]
| when Z > 31: !VO+[2 2] //hack to improve high altitude centering
| $view_origin.init{VO}

view.set_brush NewBrush = $brush.init{NewBrush}

view.world = $main.world


export view
