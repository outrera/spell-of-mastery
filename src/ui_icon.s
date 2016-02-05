use widgets gfx

/*
type minimap.widget{Main CenterAt}
     main/Main w/128 h/128 pressed center/CenterAt
minimap.draw G PX PY =
| MM = $main.world.minimap
| X,Y = $main.world.human.view/32
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

DisabledIconOverlay = 0

type icon.widget{fg data/0 click/(Icon=>)}
   w/50
   h/42
   pressed
   over
   picked
   disabled
   grayed
   text/[0 0 No]
   frame/[2 2 icon_frame]
   data/Data
   unit/0
   hotkey
   on_click/Click
   //popup/icon_popup{}
icon.draw G PX PY =
| less $fg: leave
| X = PX
| Y = PY
| when $pressed:
  | !X+1
  | !Y+1
| when $frame.2
  | IconFrame = skin{$frame.2}
  | G.blit{X-$frame.0 Y-$frame.1 IconFrame}
| G.blit{X Y $fg}
| when $picked: G.rectangle{#0000FF 0 PX-2 PY-2 $w+4 $h+4}
| when $grayed:
  | less DisabledIconOverlay: DisabledIconOverlay <= skin{'icon_disabled'}
  | Ov = DisabledIconOverlay
  | P = Ov.h*$grayed/100
  | G.blit{X Y+Ov.h-P Ov.rect{0 0 Ov.w P}}
| when got $text.2:
  | Font = font small
  | Font.draw{G X+$text.0 Y+$text.1 "[$text.2]"}
| when $hotkey
  | Font = font small
  | Font.draw{G X+$fg.w-8 Y+$fg.h-8 "[$hotkey]"}
icon.input In =
| when $disabled: leave
| case In
  [mice over S P] | $over <= S
  [mice left 1 P] | less $pressed: $pressed <= 1
  [mice left 0 P] | when $pressed:
                    | when $over: $on_click{}{Me}
                    | $pressed <= 0

export /*minimap*/ icon