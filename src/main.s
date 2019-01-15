use enheap reader cfg sprite class tile sound site pathfind action update
    unit order turn view_render view_input view_editor
    ui ui_new_game ui_shop ui_world ui_site ui_editor ui_act ui_result
    gui widgets ui_widgets save generate ai effect main2 fxn test

invnt_dlg.startup_init =
| InfoButton = button 'Info' skin/medium_small: => ($infoCB){$unit}
//| InfoButton.state <= 'disabled'
| $title <= txt header 'Inventory'
| MW = 44
| MH = 86
| $base <= dlg: mtx
  |   0   0| $site.main.img{ui_box}
  | 200  12 | $title
  |  15+MW 305+MH | InfoButton
  | 220+MW 305+MH | button 'Cancel' skin/medium_small: => ($backCB){}

@run: main: main_root

say 'Goodbye!'
