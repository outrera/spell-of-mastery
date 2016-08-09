use widgets gfx


/*
type icon_popup.widget info enabled resources text/txt{small ''}
| $info <= layV: map X [$text]: tabs 0: t 1(X) 0(spacer 0 0)
icon_popup.render =
| for X $info.items: X.pick{$enabled}
| $info.render*/

type minimap.widget{Main CenterAt}
     main/Main w/128 h/128 pressed center/CenterAt
minimap.draw G PX PY =
| MM = $main.world.minimap
| G.blit{PX PY MM}

minimap.center_at P = ($center){P.0*$main.world.w/$w P.1*$main.world.h/$h}

minimap.input In = case In
  [mice_move _ XY] | when $pressed: $center_at{XY}
  [mice left 1 XY] | $pressed <= 1; $center_at{XY}
  [mice left 0 XY] | $pressed <= 0


DisabledIconOverlay = 0

type icon.widget{fg data/0 click/(Icon=>)}
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
   data/Data
   unit/0
   hotkey
   on_click/Click
   group //use for exclusive widgets, like radio buttons or tabs
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
| G.blit{X Y | if $picked and $picked_fg then $picked_fg else $fg}
| when $picked:
  | if $picked_overlay
    then | XX,YY,Overlay = $picked_overlay
         | G.blit{X+XX Y+YY Overlay}
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
         | $on_click{}{Me}
       | $pressed <= 0

icon.infoline =
| ActName = $data
| Unit = $unit
| less Unit: leave ''
| Act = Unit.main.params.acts.ActName
| when no Act: leave ''
| Info = Act.title
| Number = $text.2
| Cool = Unit.cooldown_of{ActName}
| ResearchRemain = Unit.owner.research_remain{Act}
| Cost = Act.cost
| if Cool then
    | Info <= "[Info] ([Cool.0/24] SECONDS TO RECHARGE)"
  else if ResearchRemain then
    | Info <= "research [Info] ([Act.lore] LORE)"
  else when got Cost and Cost:
    | Info <= "cast [Info] ([Cost] MANA)"
| Info.upcase

export minimap icon
