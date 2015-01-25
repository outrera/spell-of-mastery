use gui widgets view

ScreenW = No
ScreenH = No

MessageBox = No
MessageBoxTitle = No
MessageBoxText = No
MessageBoxOk = No

init_message_box Main =
| MessageBoxTitle <= txt size/medium '' 
| MessageBoxText <= txt size/medium ''
| MessageBoxOk <= concealable: button 'Ok' w_size/small: =>
  | MessageBox.pick{hide}
| MessageBox <= concealable: dlg: mtx
  |   0   0 | spacer ScreenW ScreenH
  | 270 100 | Main.img{ui_panel2}
  | 400 110 | MessageBoxTitle
  | 285 140 | MessageBoxText
  | 360 320 | MessageBoxOk
show_message Title Text =
| MessageBoxTitle.value <= Title
| MessageBoxText.value <= Text
| MessageBoxOk.pick{show}
| MessageBox.pick{show}


/*
GameMenu <=
| Save = button 'Save' w_size/small state/disabled (=>)
| Load = button 'Load' w_size/small state/disabled (=>)
| concealable: dlg: mtx
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
*/

run_ui Main =
| ScreenW <= Main.params.ui.width
| ScreenH <= Main.params.ui.height
| set_skin Main
| init_message_box Main
| View = view Main ScreenW-200 ScreenH
| Tabs = No
| GameMenu = No
| PropertiesMenu = No
| Ingame = No
| ScenarioMenu = No
| MainMenu = No
| WorldNameInput = txt_input{''}
| PropFields = ['World Name:',WorldNameInput
               ]
| PropertiesMenu <= concealable: dlg: mtx
  |   0   0 | spacer ScreenW ScreenH
  | 270 100 | Main.img{ui_panel5}
  | 400 110 | txt size/medium 'Properties'
  | 285 140 | layV PropFields{?0^txt}
  | 370 136 | layV PropFields{?1}
  | 285 405 | button 'Done' w_size/small: =>
              | View.unpause
              | PropertiesMenu.pick{hide}

| BankName =
| TileNames = Main.tiles{}{?0}.skip{Main.aux_tiles.?^got}.sort
| BankNames = [terrain unit @Main.bank_names.skip{unit}]
| ItemList = litems w/120 lines/40 [] f: N =>
  | Brush = if BankName >< terrain
            then [tile N]
            else [obj BankName,N]
  | View.set_brush{Brush}
| BankList = litems w/80 lines/40 BankNames f: N =>
  | BankName <= N
  | if BankName >< terrain
    then | ItemList.data <= TileNames
         | ItemList.pick{TileNames.locate{plain}}
    else | ItemList.data <= Main.classes_banks.BankName
         | ItemList.pick{0}
| Panel = layH: list BankList ItemList
| PropsButton = button 'Properties' w_size/small h_size/medium: =>
               | View.pause
               | PropertiesMenu.pick{show}
| SaveButton = button 'Save' w_size/small: =>
               | show_message 'Hello' 'Hello, World!'
| LoadButton = button 'Load' w_size/small state/disabled: =>
| PlayButton = button 'Play' w_size/small state/disabled: =>
| QuitButton = button 'Quit' w_size/small h_size/medium: =>
               | View.pause
               | Tabs.pick{main_menu}
| TopButtons = layH s/8
    PropsButton,PlayButton,SaveButton,LoadButton,spacer{20 1},QuitButton
| Ingame <= dlg w/ScreenW h/ScreenH: mtx
  |  0  0 | spacer ScreenW ScreenH
  |  0  0 | layH Panel,View
  |202  2 | TopButtons
  |  0  0 | PropertiesMenu
  |  0  0 | MessageBox
| View.init
| MenuBG = Main.img{ui_menu_bg}
| X = ScreenW/2 - 112
| MainMenu <= dlg: mtx
  |   0   0 | MenuBG
  |  16 ScreenH-16 | txt 'SymtaEngine v0.1; Copyright (c) 2015 Nikita Sadkov'
  | X 240 | layV s/8: list
            button{'Campaign'       state/disabled (=>)}
            button{'Scenario'       state/disabled (=>Tabs.pick{scenario})}
            button{'Multi Player'   state/disabled (=>)}
            button{'Load Game'      state/disabled (=>)}
            button{'World Editor'   (=> | View.mode <= \editor
                                        | Tabs.pick{ingame})}
            button{'Exit Program'   (=>get_gui{}.exit)}

| Tabs <= tabs main_menu: t
          main_menu(MainMenu)
          ingame(Ingame)
          scenario(ScenarioMenu)
| BankList.pick{0}
| gui Tabs cursor/Main.img{mice_point}

export run_ui