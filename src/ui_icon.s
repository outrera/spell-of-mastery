use widgets gfx main_data


/*
type icon_popup.widget info enabled resources text/txt{small ''}
| $info <= layV: map X [$text]: tabs 0: t 1(X) 0(spacer 0 0)
icon_popup.render =
| for X $info.items: X.pick{$enabled}
| $info.render*/

DisabledIconOverlay = 0

type icon.widget{FG OnClick}
   fg/FG
   w/50
   h/42
   pressed
   over
   picked
   picked_fg
   picked_overlay
   disabled
   hidden
   grayed //percent of grayed area of the icon
   text/[0 0 No]
   frame/[2 2 icon_frame]
   data/0
   unit/0
   hotkey
   on_click/OnClick
   sound/ui_click
   group //use for exclusive widgets, like radio buttons or tabs
   infoline_handler
   //popup/icon_popup{}

ResearchIcon = 0

icon.draw G PX PY =
| less $fg: leave
| when $hidden: leave
| when $fg.is_text: $fg <= get_main{}.img{"icons_[$fg]"}
| X = PX
| Y = PY
| when $pressed:
  | X++
  | Y++
| when $frame.2
  | IconFrame = skin{$frame.2}
  | G.blit{X-$frame.0 Y-$frame.1 IconFrame}
| G.blit{X Y | if $picked and $picked_fg then $picked_fg else $fg}
| when $picked:
  | if $picked_overlay
    then G.blit{X Y $picked_overlay^skin}
    else G.rectangle{#0000FF 0 PX-2 PY-2 $w+4 $h+4}
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
| when $disabled or $hidden: leave
| case In
  [mice over S P] | $over <= S
  [mice left 1 P] | less $pressed: $pressed <= 1
  [mice left 0 P] 
     | when $pressed:
       | when $over:
         | when $group:
           | for Icon $group: Icon.picked <= 0
           | $picked <= 1
         | when $sound: get_main{}.sound{$sound}
         | $on_click{}{Me}
       | $pressed <= 0

icon.infoline =
| when $hidden: leave ""
| if $infoline_handler then ($infoline_handler){Me} else ""


export icon
