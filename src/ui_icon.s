use widgets gfx main_data


/*
type icon_popup.widget info enabled resources text/txt{small ''}
| $info <= layV: map X [$text]: tabs 0: t 1(X) 0(spacer 0 0)
icon_popup.render =
| for X $info.items: X.pick{$enabled}
| $info.render*/

type minimap.widget{Main CenterAt}
     main/Main w/128 h/128 pressed center/CenterAt
minimap.draw G PX PY =
| MM = $main.site.minimap
| G.blit{PX PY MM}

minimap.center_at P = ($center){P.0*$main.site.w/$w P.1*$main.site.h/$h}

minimap.input In = case In
  [mice_move _ XY] | when $pressed: $center_at{XY}
  [mice left 1 XY] | $pressed <= 1; $center_at{XY}
  [mice left 0 XY] | $pressed <= 0


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
   grayed //percent of grayed area of the icon
   text/[0 0 No]
   frame/[2 2 icon_frame]
   data/0
   unit/0
   hotkey
   on_click/OnClick
   sound/ui_click
   group //use for exclusive widgets, like radio buttons or tabs
   //popup/icon_popup{}

ResearchIcon = 0

icon.draw G PX PY =
| less $fg: leave
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
| Unit = $unit
| ActName = $data
| when Unit and not Unit.owner.researched{Unit.main.cfg.acts.ActName}:
  | less ResearchIcon: ResearchIcon <= skin{'icon_research'}
  | RI = ResearchIcon
  | G.blit{X Y+$fg.h-RI.h RI}
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
| ActName = $data
| Unit = $unit
| less Unit: leave ''
| Act = Unit.main.cfg.acts.ActName
| when no Act: leave ''
| Info = Act.title
| Number = $text.2
| Cool = Unit.cooldown_of{ActName}
| Cost = Act.cost
| if Cool then
    | Info <= "[Info] ([Cool.0+Cool.1-Unit.site.turn] TURNS TO RECHARGE)"
  else if not Unit.owner.researched{Act} then
    | Info <= "research [Info] ([Act.lore] LORE)"
  else when got Cost and Cost:
    | Info <= "[Info] ([Cost] MANA)"
| Info.upcase

export minimap icon
