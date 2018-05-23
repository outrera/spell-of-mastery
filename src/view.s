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
  wakeupTime/0.0
  fpsGoal/24 // goal frames per second
  fpsD/30.0
  cfg
  view_size/32  // render 32x32 site chunk
  center/[0 0 0]
  zfix/1
  zlock/0
  zbuffer/0
  xunit
  yunit
  zunit
  d //cell edge size
  keymap
| $keymap <= $main.cfg.keymap
| $fpsGoal <= $main.cfg.ui.fps
| $fpsD <= $fpsGoal.float+8.0
| $cfg <= $main.cfg.ui
| Wr = $site
| Wr.view <= Me
| SCfg = $main.cfg.site
| TS = SCfg.tile_size
| $xunit <= TS.0
| $yunit <= TS.1
| $zunit <= TS.2
| $d <= SCfg.cell_size
| $fpsT <= clock

view.key Name =
| K = $keymap.Name
| $keys.K >< 1

view.key_set Name Value =
| K = $keymap.Name
| $keys.K <= Value

view.paused = $site.paused
view.`=paused` V = $site.paused <= V

view.player = $site.human //view deals with human player

view.picked = $player.picked
view.`=picked` Us = $player.picked <= Us

view.clear =
| $wakeupTime <= 0.0
| $zlock <= 0
| $zfix <= 1
| $blit_origin.init{[$w/2 $h/2-170]-[32 $view_size/4*$zunit]}
| $mice_xy.init{[0 0]}
| $mice_xy_anchor.init{[0 0]}
| CurZ = $site.floor{1,1,1}
| $cursor.init{[1 1 CurZ]}
| $anchor.init{[1 1 CurZ]}
| $center_at{$cursor}
| $mice_click <= 0
| $pick_count <= 0
| Leader = $player.leader
| when not Leader.removed: $center_at{Leader.xyz}
| $zlock <= $site.cfg.view_zlock
| when no $zlock: $zlock <= $site.d-2

view.center_at XYZ cursor/0 =
| X,Y,Z = XYZ
| X = X.clip{1 $site.w}
| Y = Y.clip{1 $site.h}
| Z = Z.clip{1 $site.d}
| $center.init{X,Y,Z}
| when Cursor: $zlock <= Z
| when Cursor: $cursor.init{X,Y,Z}
| VO = -[$h/$yunit $h/$yunit]+[X Y]-[Z/$zunit Z/$zunit]+[6 6]
| when Z > 31: VO += [2 2] //hack to improve high altitude centering
| $view_origin.init{VO-[6 6]}

view.set_brush NewBrush = $brush.init{NewBrush}

view.site = $main.site

view.infoline =
| X,Y,Z = $cursor
| Indoor = if $site.up{$cursor} then ':indoor' else ':outdoor'
| Cave = if $site.down{$cursor} then ":roof" else ""
| Land = "[X],[Y],[Z]:[$site.at{X Y Z-1}.type][Indoor][Cave]"
| U = $site.block_at{X,Y,Z}
| Unit = ""
| when U and (not U.invisible or U.owner.id><$site.human.id):
  | P = $picked
  | Bonus = if P.id and P.id<>U.id then P.attack_bonus{U} else 0
  | DI = if Bonus > 0 then "-[Bonus]"
         else if Bonus < 0 then "[-Bonus]"
         else ""
  | Stats = "M:[U.moves]:[U.mov]/[U.class.mov] H:[U.health]/[U.class.hp]"
  | Stats <= "[Stats] A:[U.atk] D:[U.def]/[U.class.def][DI] F:[U.fatigue]-[U.stamina]"
  | Stats <= "[Stats] S:[U.sight] R:[U.range] W:[U.will]/[U.class.will]"
  | Id = if $site.editor then "[U.id]" else ""
  | Unit <= "[U.title][Id] [Stats]"
| "[Unit]\n[Land]"

export view
