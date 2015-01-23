use common sprite class tile macros world game util heap octree gui widgets view
    param

Main = main: main_root
World = world Main 16
Game = game Main World


set_skin Main

View = view Main 600 600

BankName =


TileNames = Main.tiles{}{?0}.skip{Main.aux_tiles.?^got}.sort

BankNames = [terrain unit @Main.bank_names.skip{unit}]

ItemList = litems w/120 lines/40 [] f: N =>
| Brush = if BankName >< terrain
          then [tile N]
          else [obj BankName,N]
| View.set_brush{Brush}

BankList = litems w/80 lines/40 BankNames f: N =>
| BankName <= N
| if BankName >< terrain
  then | ItemList.data <= TileNames
       | ItemList.pick{TileNames.locate{plain}}
  else | ItemList.data <= Main.classes_banks.BankName
       | ItemList.pick{0}


BankList.pick{0}

Panel = layH: list BankList ItemList


//GUI = layH.[Panel View]
GUI = dlg w/800 h/600: list [0 0 layH.[Panel View]]

View.init


GameMenu = No

GameMenu <=
| Save = button 'Save (F11)' w_size/small state/disabled (=>)
| Load = button 'Load (F12)' w_size/small state/disabled (=>)
| Show = dlg: mtx
  |   0   0 | spacer 640 480
  | 270 100 | Main.img{ui_panel1}
  | 346 110 | txt size/medium 'Game Menu'
  | 285 140 | layV s/8: list
              layH{s/12 [Save Load]}
              button{'Options (F5)' state/disabled (=>)}
              button{'Help (F1)' state/disabled (=>)}
              button{'Scenario Objectives' state/disabled (=>)}
              (button 'End Scenario': =>
                | View.pause
                | GameMenu.pick{hide}
                //| Tabs.pick{main}
                )
              spacer{1 20}
              (button 'Return to Game (Esc)': =>
                 | View.unpause
                 | GameMenu.pick{hide})
| Hide = spacer 0 0
| tabs show: t show(Show) hide(Hide)


gui GameMenu cursor/Main.img{mice_point}

say 'Succeed!'
