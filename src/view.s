use gui util widgets

type view.widget{M UI W H}
  main/M
  fb // frame buffer
  ui/UI
  w/W
  h/H
  frame
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
  d //cell edge size
  keymap
| $keymap <= $main.params.keymap
| $fpsGoal <= $main.params.ui.fps
| $fpsD <= $fpsGoal.float+8.0
| $param <= $main.params.ui
| Wr = $world
| Wr.view <= Me
| WParam = $main.params.world
| TS = WParam.tile_size
| $xunit <= TS.0
| $yunit <= TS.1
| $zunit <= TS.2
| $d <= WParam.cell_size
| $fpsT <= clock

view.key Name =
| K = $keymap.Name
| $keys.K >< 1

view.key_set Name Value =
| K = $keymap.Name
| $keys.K <= Value

view.paused = $world.paused
view.`=paused` V = $world.paused <= V

view.player = $world.human //view deals with human player

view.picked = $player.picked
view.`=picked` Us = $player.picked <= Us

view.clear =
| $zlock <= 0
| $zfix <= 1
| $center_at{[0 0 0]}
| $blit_origin.init{[$w/2 $h/2-170]-[32 $view_size/4*$zunit]}
| $mice_xy.init{[0 0]}
| $mice_xy_anchor.init{[0 0]}
| $cursor.init{[1 1 1]}
| $anchor.init{[1 1 1]}
| $mice_click <= 0
| $pick_count <= 0
| Leader = $player.units.find{?leader}
| when got Leader: $center_at{Leader.xyz}
| $zlock <= $world.params.view_zlock
| when no $zlock: $zlock <= $world.d-2

view.center_at XYZ cursor/0 =
| X,Y,Z = XYZ
| X = X.clip{1 $world.w}
| Y = Y.clip{1 $world.h}
| Z = Z.clip{1 $world.d}
| $center.init{X,Y,Z}
| when Cursor: $zlock <= Z
| when Cursor: $cursor.init{X,Y,Z}
| VO = -[$h/$yunit $h/$yunit]+[X Y]-[Z/$zunit Z/$zunit]+[6 6]
| when Z > 31: VO += [2 2] //hack to improve high altitude centering
| $view_origin.init{VO-[6 6]}

view.set_brush NewBrush = $brush.init{NewBrush}

view.world = $main.world

view.infoline =
| X,Y,Z = $cursor
| Indoor = if $world.up{$cursor} then 'Indoor; ' else "Outdoor; "
| Cave = if $world.down{$cursor} then "Cave Roof; " else ""
| Text = "[Indoor][Cave][X],[Y],[Z]:[$world.at{X Y Z-1}.type]"
| Us = $world.units_get{X,Y,Z}.skip{?empty}
| less Us.end:
  | U = Us.0
  | S = U.title
  | when U.goal:
    | S <= "[S] ([U.goal_act.name] at [U.goal.xyz])"
  | Text <= "[Text]; [S]"
| Text

export view
