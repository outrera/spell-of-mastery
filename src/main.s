use enheap reader cfg sprite class tile sound site pathfind action update
    unit order turn view_render view_input view_editor
    ui ui_new_game ui_shop ui_world ui_site ui_editor ui_act ui_result
    gui widgets ui_widgets save generate ai effect main2 fxn test

invnt_dlg.startup_init =
| InfoButton = button 'Info' skin/medium_small: => ($infoCB){$unit}
//| InfoButton.state <= 'disabled'
| UnitTitle = txt medium |=>$unit.title
| Laurels = pic | State => $site.main.img{ui_laurels}
| UnitIcon = pic
  | State =>
    | Icon = $unit.icon
    | less Icon: Icon <= "icons_[$unit.type]"
    | $site.main.img{Icon}
| MW = 44
| MH = 86
| SY = 162
| SD = 26
| $base <= dlg: mtx
  |   0   0| $site.main.img{ui_inventory}
  | 200  12 | txt header 'Inventory'
  | 338 320 | txt medium 'Ground:'
  | 96  71  | UnitIcon
  | 80  64  | Laurels
  | 44  121 | UnitTitle
  | 68  SY+SD*0 | txt medium |=>$unit.atk
  | 68  SY+SD*1 | txt medium |=>$unit.def
  | 68  SY+SD*2 | txt medium |=>$unit.sight
  | 68  SY+SD*3 | txt medium |=>$unit.range
  | 144 SY+SD*0 | txt medium |=>"[$unit.health]/[$unit.class.hp]"
  | 144 SY+SD*1 | txt medium |=>"[$unit.moves/$unit.class.mov]"
  | 144 SY+SD*2 | txt medium |=>"[$unit.stamina] (-[$unit.stamina_fatigue])"
  |  15+MW 340+MH | InfoButton
  | 220+MW 340+MH | button 'Back' skin/medium_small: => ($backCB){}

invnt_dlg.set_unit U =
| $unit <= U

@run: main: main_root

say 'Goodbye!'
