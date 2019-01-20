use enheap reader cfg sprite class tile sound site pathfind action update
    unit order turn view_render view_input view_editor
    ui ui_new_game ui_shop ui_world ui_site ui_editor ui_act ui_result
    gui widgets ui_widgets save generate ai effect main2 fxn test

type invnt_slot.widget{main location index type}
   item value on_click/0 state_/normal over w/44 h/38
invnt_slot.state = $state_
invnt_slot.`=state` V =
| when V><normal and $state><pressed: leave
| $state_ <= V
invnt_slot.render = Me
invnt_slot.draw G PX PY =
| less $item: leave 0
| Class = if $item.is_text then $main.classes.$item
          else $item.class
| Img = Class.default_sprite.idle_frame
| G.blit{PX+8 PY-4 Img}
invnt_slot.input In = case In
  [mice over S P] | $over <= S
  [mice left 1 P] | case $state normal: $state_ <= \pressed
  [mice left 0 P] | case $state pressed
                    | when $over and $on_click: $on_click{}{}
                    | $state_ <= \normal

invnt_dlg.render =
| when not $unit or $unit.removed: leave $base.render
| Items = $unit.cell.units{}.keep{?ai><item}
| when Items.size>12: Items <= Items.take{12}
| for I,Item Items.i: $groundSlots.I.item <= Item
| $base.render

invnt_dlg.startup_init =
| InfoButton = button 'Info' skin/medium_small: => ($infoCB){$unit}
//| InfoButton.state <= 'disabled'
| UnitTitle = txt medium |=>$unit.title
| Laurels = pic | State => $main.img{ui_laurels}
| UnitIcon = pic
  | State =>
    | Icon = $unit.icon
    | less Icon: Icon <= "icons_[$unit.type]"
    | $main.img{Icon}
| GX,GY = 252,342 //ground XY
| MW,MH = 44,86
| SY,SD = 162,26
| $groundSlots <= dup I 10: invnt_slot $main ground I any
| $bagSlots <= dup I 10: invnt_slot $main bag I any
| $wearSlots <= list
              (invnt_slot $main body  0 head)
              (invnt_slot $main body  1 neck)
              (invnt_slot $main body  2 body)
              (invnt_slot $main body  3 r_arm)
              (invnt_slot $main body  4 l_arm)
              (invnt_slot $main body  5 feet)
              (invnt_slot $main body  6 cloak)
              (invnt_slot $main body  7 trinket)
              (invnt_slot $main body  8 trinket)
              (invnt_slot $main body  9 trinket)
              (invnt_slot $main body 10 trinket)
              (invnt_slot $main body 11 trinket)
| GroundSlotsLay1 = layH s/4 $groundSlots.take{5}
| GroundSlotsLay2 = layH s/4 $groundSlots.drop{5}
| $base <= dlg: mtx
  |   0   0| $main.img{ui_inventory}
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
  | GX GY | GroundSlotsLay1
  | GX GY+38+4 | GroundSlotsLay2
  |  15+MW 340+MH | InfoButton
  | 220+MW 340+MH | button 'Back' skin/medium_small: => ($backCB){}

invnt_dlg.set_unit U =
| $unit <= U

@run: main: main_root

say 'Goodbye!'
