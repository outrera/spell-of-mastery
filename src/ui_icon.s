use widgets gfx

/*
type minimap.widget{Main CenterAt}
     main/Main w/128 h/128 pressed center/CenterAt
minimap.draw G PX PY =
| MM = $main.world.minimap
| X,Y = $main.world.player.view/32
| X = X*$w/$main.world.w
| Y = Y*$h/$main.world.h
| W = $main.view_w/32*$w/$main.world.w
| H = $main.view_h/32*$h/$main.world.h
| G.blit{PX PY MM}
| G.rectangle{#A0A0A0 0 PX+X PY+Y W H}

minimap.center_at P = ($center){[P.0*$main.world.w/$w P.1*$main.world.h/$h]}

minimap.input In = case In
  [mice_move _ XY] | when $pressed: $center_at{XY}
  [mice left 1 XY] | $pressed <= 1; $center_at{XY}
  [mice left 0 XY] | $pressed <= 0
*/


/*
type icon_popup.widget info enabled resources text/txt{small ''}
| $info <= layV: map X [$text]: tabs 0: t 1(X) 0(spacer 0 0)
icon_popup.render =
| for X $info.items: X.pick{$enabled}
| $info.render*/

IconFrame = 0
DisabledIconOverlay = 0
ResearchIconOverlay = 0

type icon.widget{fg data/0 click/(Icon=>)}
   w/50
   h/42
   pressed
   over
   picked
   disabled
   research
   number/No
   frame/1
   data/Data
   on_click/Click
   //popup/icon_popup{}
icon.draw G PX PY =
| less $fg: leave
| X = PX
| Y = PY
| when $pressed:
  | !X+1
  | !Y+1
| when $frame
  | less IconFrame: IconFrame <= skin{'icon_frame'}
  | G.blit{X Y IconFrame}
  | !X+2
  | !Y+2
| G.blit{X Y $fg}
| when $picked: G.rectangle{#0000FF 0 PX-2 PY-2 $w+4 $h+4}
| when $disabled:
  | less DisabledIconOverlay: DisabledIconOverlay <= skin{'icon_disabled'}
  | G.blit{X Y DisabledIconOverlay}
| when $research:
  | less ResearchIconOverlay: ResearchIconOverlay <= skin{'icon_research'}
  | G.blit{X+26 Y+18 ResearchIconOverlay}
| when got $number:
  | Font = font small
  | Font.draw{G X Y "[$number]"}
icon.input In =
| when $disabled: leave
| case In
  [mice over S P] | $over <= S
  [mice left 1 P] | less $pressed: $pressed <= 1
  [mice left 0 P] | when $pressed:
                    | when $over: $on_click{}{Me}
                    | $pressed <= 0

export /*minimap*/ icon