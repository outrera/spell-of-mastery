use gui widgets

type minimap.widget{Main CenterAt}
     main/Main w/120 h/120 pressed center/CenterAt

minimap.draw G PX PY =
| MM = $main.site.minimap
| G.blit{PX PY MM}
| V = $main.ui.view
| CX,CY,CZ = V.center
| St = V.site
| for U $main.site.active: when U.ai><node:
  | VX = U.xyz.0*$w/St.w
  | VY = U.xyz.1*$h/St.h
  | G.circle{#00FF00 0 [PX+VX PY+VY] 8}
| VX = CX*$w/St.w
| VY = CY*$h/St.h
| G.circle{#FFFFFF 0 [PX+VX PY+VY] 16}


minimap.center_at P = ($center){P.0*$main.site.w/$w P.1*$main.site.h/$h}

minimap.input In = case In
  [mice_move _ XY] | when $pressed: $center_at{XY}
  [mice left 1 XY] | $pressed <= 1; $center_at{XY}
  [mice left 0 XY] | $pressed <= 0

export minimap
