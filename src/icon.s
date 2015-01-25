use widgets


type minimap.widget{Main CenterAt}
     main/Main w/128 h/128 pressed center/CenterAt
minimap.draw G P =
| MM = $main.world.minimap
| [X Y] = $main.world.player.view/32
| X = X*$w/$main.world.w
| Y = Y*$h/$main.world.h
| W = $main.view_w/32*$w/$main.world.w
| H = $main.view_h/32*$h/$main.world.h
| G.blit{P MM}
| G.rect{#A0A0A0 0 P.0+X P.1+Y W H}

minimap.center_at P = ($center){[P.0*$main.world.w/$w P.1*$main.world.h/$h]}

minimap.input In = case In
  [mice_move _ XY] | when $pressed: $center_at{XY}
  [mice left 1 XY] | $pressed <= 1; $center_at{XY}
  [mice left 0 XY] | $pressed <= 0

type icon_popup.widget info enabled resources text/txt{''}
| $info <= layV: map X [$text]: tabs 0: t 1(X) 0(spacer 0 0)
icon_popup.render =
| for X $info.items: X.pick{$enabled}
| $info.render

type icon.widget{data/0 click/(Icon=>)}
   w/50
   h/42
   pressed
   over
   fg
   tint
   g/skin{'icon-frame'}.copy
   data/Data
   on_click/Click
   popup/icon_popup{}
   last_fg
   last_tint
icon.draw G P =
| less $tint: leave 0
| when $fg^address <> $last_fg^address or $tint^address <> $last_tint^address:
  | $g.blit{[2 2] $fg map/$tint}
| when $pressed: !P + [1 1]
| G.blit{P $g}
| when $over: G.rect{#A0A0A0 0 P.0-2 P.1-2 54 46}
| $last_fg <= $fg
| $last_tint <= $tint
icon.input In = case In
  [mice over S P] | $over <= S
  [mice left 1 P] | less $pressed: $pressed <= 1
  [mice left 0 P] | when $pressed:
                    | when $over: $on_click{}{Me}
                    | $pressed <= 0

/*
type icon_hp.widget unit w/52 h/7 font/font{small}
icon_hp.draw G P =
| less $unit: leave 0
| G.rect{#000000 1 P.0 P.1 $w $h}
| N = $unit.hp_percent
| C = if N < 50 then #F00000
      else if N < 75 then #F0F000
      else #00A000
| G.rect{C 1 P.0 P.1 N*$w/100 $h}
| HP = "[$unit.hp-$unit.hits]/[$unit.hp]"
| FW = $font.width{HP}
| $font.draw{G P.0+($w-FW)/2+1 P.1 white HP}
*/

export minimap icon