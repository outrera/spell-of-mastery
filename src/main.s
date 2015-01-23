use common sprite class tile macros world game util heap octree gui widgets view
    param

Main = main: main_root
World = world Main 16
Game = game Main World

ScreenW = 800
ScreenH = 600

set_skin Main

View = view Main 600 600

Tabs = No
GameMenu = No
EditorMenu = No
Ingame = No
ScenarioMenu = No
MainMenu = No
Editor = No

/*
GameMenu <=
| Save = button 'Save' w_size/small state/disabled (=>)
| Load = button 'Load' w_size/small state/disabled (=>)
| Show = dlg: mtx
  |   0   0 | spacer ScreenW ScreenH
  | 270 100 | Main.img{ui_panel1}
  | 346 110 | txt size/medium 'Game Menu'
  | 285 140 | layV s/8: list
              layH{s/12 [Save Load]}
              button{'Options' state/disabled (=>)}
              button{'Objectives' state/disabled (=>)}
              (button 'Abandon Game': =>
                | View.pause
                | GameMenu.pick{hide}
                | Tabs.pick{main_menu})
              spacer{1 20}
              (button 'Return to Game': =>
                 | View.unpause
                 | GameMenu.pick{hide})
| Hide = spacer 0 0
| tabs hide: t show(Show) hide(Hide)*/


EditorMenu <=
| Save = button 'Save' w_size/small state/disabled (=>)
| Load = button 'Load' w_size/small state/disabled (=>)
| Show = dlg: mtx
  |   0   0 | spacer ScreenW ScreenH
  | 270 100 | Main.img{ui_panel1}
  | 346 110 | txt size/medium 'Editor Menu'
  | 285 140 | layV s/8: list
              layH{s/12 [Save Load]}
              button{'Options' state/disabled (=>)}
              spacer{1 20}
              (button 'Leave Editor': =>
                | View.pause
                | EditorMenu.pick{hide}
                | Tabs.pick{main_menu})
              spacer{1 60}
              (button 'Return to Editor': =>
                 | View.unpause
                 | EditorMenu.pick{hide})
| Hide = spacer 0 0
| tabs hide: t show(Show) hide(Hide)


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

X = ScreenW - 110

Editor <= dlg w/ScreenW h/ScreenH: mtx
  |  0  0 | spacer ScreenW ScreenH
  |  0  0 | layH Panel,View
  |  X  2 | button 'Menu' w_size/small h_size/medium: =>
            | View.pause
            | EditorMenu.pick{show}
  |  0  0 | EditorMenu


View.init


MenuBG = Main.img{ui_menu_bg}

X = ScreenW/2 - 112

MainMenu <= dlg: mtx
  |   0   0 | MenuBG
  |  16 ScreenH-16 | txt 'SymtaEngine v0.1; Copyright (c) 2015 Nikita Sadkov'
  | X 240 | layV s/8: list
            button{'Campaign'       state/disabled (=>)}
            button{'Scenario'       state/disabled (=>Tabs.pick{scenario})}
            button{'Multi Player'   state/disabled (=>)}
            button{'Load Game'      state/disabled (=>)}
            button{'Map Editor'     (=>Tabs.pick{editor})}
            button{'Exit Program'   (=>get_gui{}.exit)}


Tabs <= tabs main_menu: t
          main_menu(MainMenu)
          editor(Editor)
          scenario(ScenarioMenu)
          ingame(Ingame)

gui Tabs cursor/Main.img{mice_point}


say 'Succeed!'
