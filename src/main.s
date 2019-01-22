use enheap reader cfg sprite class tile sound site pathfind action update
    unit order turn view_render view_input view_editor
    ui ui_new_game ui_shop ui_world ui_site ui_editor ui_act ui_result
    gui widgets ui_widgets save generate ai effect main2 fxn test

type invnt_slot.widget{main type}
   item value on_click/0 state_/normal over drag w/44 h/38
   
invnt_slot.state = $state_
invnt_slot.`=state` V =
| when V><normal and $state><pressed: leave
| $state_ <= V
invnt_slot.render = Me
invnt_slot.item_class = 
| if $item.is_text then $main.classes.$item
  else $item.class
invnt_slot.item_gfx = $item_class.default_sprite.idle_frame
invnt_slot.draw G PX PY =
| less $item: leave 0
| when $drag: leave 0
| G.blit{PX+8 PY-4 $item_gfx}
invnt_slot.drag_start =
| less $item: leave
| C = $main.ui.drag_cursor
| C.saved_cursor <= get_gui{}.cursor
| C.slot <= Me
| $drag <= 1
| get_gui{}.cursor <= C
invnt_slot.find_slots Type = $main.ui.invntDlg.unitSlots.keep{?type><Type}
invnt_slot.transfer_item_to Dst =
| Dst.item <= $item
| $item <= 0
invnt_slot.notify Msg = $main.ui.notify{Msg}
invnt_slot.drag_end =
| less $drag: leave
| [Dst _ _] = get_gui{}.widget_under_cursor
| $drag <= 0
| C = $main.ui.drag_cursor
| get_gui{}.cursor <= C.saved_cursor
| ItemSlotType = $item_class.item.slot
| less Dst.is_invnt_slot:
  | less Dst.is_invnt_doll
    | leave
  | Slots = $find_slots{ItemSlotType}
  | FreeSlots = Slots.skip{?item}
  | when FreeSlots.end:
    | $notify{"First unquip the used item."}
    | leave
  | Dst <= Slots.0
| when Dst.type<>any and Dst.type<>ItemSlotType:
  | Slots = $find_slots{ItemSlotType}
  | FreeSlots = Slots.skip{?item}
  | when FreeSlots.end:
    | $notify{"First unquip the used item."}
    | leave
  | Dst <= Slots.0
| when Dst.item:
  | $notify{"This slot is already occupied."}
  | leave
| $transfer_item_to{Dst}
invnt_slot.input In = case In
  [mice over S P] | $over <= S
  [mice left 1 P] | case $state normal: $state_ <= \pressed
                  | $drag_start
  [mice left 0 P] | case $state pressed
                    | when $over and $on_click: $on_click{}{}
                    | $state_ <= \normal
                  | $drag_end

invnt_dlg.render =
| $base.render


type invnt_doll.widget{}  w/228 h/228
invnt_doll.render = Me
invnt_doll.draw G X Y =

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
| $groundSlots <= dup I 12: invnt_slot $main any
| Head  = invnt_slot $main head
| Neck  = invnt_slot $main neck
| Body  = invnt_slot $main body
| RArm  = invnt_slot $main rarm
| LArm  = invnt_slot $main larm
| Feet  = invnt_slot $main feet
| Cloak = invnt_slot $main cloak
| Trinkets = dup I 5: invnt_slot $main trinket
| Bag = dup I 10: invnt_slot $main any
| $unitSlots <= [Head Neck Body RArm LArm Feet Cloak @Trinkets @Bag].list
| BagLay1 = layV s/4 Bag.take{5}
| BagLay2 = layV s/4 Bag.drop{5}
| GroundSlotsLay1 = layH s/4 $groundSlots.take{6}
| GroundSlotsLay2 = layH s/4 $groundSlots.drop{6}
| TrinketsLay = layV s/4 Trinkets
| $base <= dlg: mtx
  |   0   0 | $main.img{ui_inventory}
  | 208  83 | invnt_doll
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
  | 327 109 | Head
  | 327 153 | Neck
  | 380 153 | Cloak
  | 327 197 | Body
  | 327 255 | Feet
  | 274 197 | RArm
  | 380 197 | LArm
  | 212 94 | TrinketsLay
  | 442 93 | BagLay1
  | 442+44+4 93 | BagLay2
  | GX GY | GroundSlotsLay1
  | GX GY+38+4 | GroundSlotsLay2
  |  15+MW 340+MH | InfoButton
  | 220+MW 340+MH | button 'Done' skin/medium_small: =>
                    | $set_unit{0}
                    | ($backCB){}

invnt_dlg.load_slots =
| for S $groundSlots: S.item <= 0
| for S $unitSlots: S.item <= 0
| when not $unit.alive or $unit.removed: leave
| for Type,I $unit.get{items}^~{[]}: $unitSlots.I.item <= Type
| Items = $unit.cell.units{}.keep{?ai><item}
| when Items.size>12: Items <= Items.take{12}
| for I,Item Items.i: $groundSlots.I.item <= Item

invnt_dlg.save_slots =
| for I,S $groundSlots.i:
| Items = map I,S $unitSlots.i.keep{?1.item}:
  | Item = S.item
  | Type = if Item.is_text then Item
           else | T = Item.type
                | Item.free
                | T
  | Type,I
| $unit.set{items Items}
| when $unit.removed: leave
| for S $groundSlots:
  | Item = S.item
  | when Item.is_text:
    | V = $unit.owner.alloc_unit{Item}
    | V.move{$unit.xyz}

invnt_dlg.set_unit U =
| when $unit: $save_slots
| less U: U <= $main.site.nil
| $unit <= U
| $load_slots

@run: main: main_root

say 'Goodbye!'
