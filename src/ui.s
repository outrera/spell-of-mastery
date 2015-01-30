use gui widgets view icon

ScreenW = No
ScreenH = No

MessageBox = No
MessageBoxTitle = No
MessageBoxText = No
MessageBoxOk = No

init_message_box Main =
| MessageBoxTitle <= txt size/medium '' 
| MessageBoxText <= txt size/medium ''
| MessageBoxOk <= hidden: button 'Ok' w_size/small: =>
  | MessageBox.show <= 0
| MessageBox <= hidden: dlg: mtx
  |   0   0 | spacer ScreenW ScreenH
  | 270 100 | Main.img{ui_panel2}
  | 400 110 | MessageBoxTitle
  | 285 140 | MessageBoxText
  | 360 320 | MessageBoxOk
show_message Title Text =
| MessageBoxTitle.value <= Title
| MessageBoxText.value <= Text
| MessageBoxOk.show <= 1
| MessageBox.show <= 1


/*
GameMenu <=
| Save = button 'Save' w_size/small state/disabled (=>)
| Load = button 'Load' w_size/small state/disabled (=>)
| hidden: dlg: mtx
  |   0   0 | spacer ScreenW ScreenH
  | 270 100 | Main.img{ui_panel1}
  | 346 110 | txt size/medium 'Game Menu'
  | 285 140 | layV s/8: list
              layH{s/12 [Save Load]}
              button{'Options' state/disabled (=>)}
              button{'Objectives' state/disabled (=>)}
              (button 'Abandon Game': =>
                | View.pause
                | GameMenu.show <= 0
                | Tabs.pick{main_menu})
              spacer{1 20}
              (button 'Return to Game': =>
                 | View.unpause
                 | GameMenu.show <= 0)
*/


type panel_bg.widget{w h}
panel_bg.draw G P =
| G.rect{#AAAAAA 1 P.0 P.1 $w $h}
| G.line{#000000 P P+[0 $h]}

main.run =
| ScreenW <= $params.ui.width
| ScreenH <= $params.ui.height
| set_skin Me
| init_message_box Me
| PanelW = 200
| View = view Me ScreenW-PanelW ScreenH
| Tabs = No
| GameMenu = No
| WorldProperties = No
| Ingame = No
| ScenarioMenu = No
| MainMenu = No
| PauseSpacer = hidden: spacer ScreenW ScreenH
| pause = | PauseSpacer.show <= 1; View.pause
| unpause = | PauseSpacer.show <= 0; View.unpause
| WorldNameInput = txt_input{''}
| PropFields = ['World Name:',WorldNameInput
               ]
| WorldProperties <= hidden: dlg: mtx
  |   0   0 | $img{ui_panel5}
  | 130  10 | txt size/medium 'Properties'
  |  15  40 | layV PropFields{?0^txt}
  | 100  36 | layV PropFields{?1}
  |  15 305 | button 'Done' w_size/small: =>
              | unpause
              | WorldProperties.show <= 0
| BankName =
| TileNames = $tiles{}{?0}.skip{$aux_tiles.?^got}.sort
| BankNames = [terrain unit @$bank_names.skip{unit}]
| ItemList = litems w/(PanelW-80) lines/40 [] f: N =>
  | Brush = if BankName >< terrain
            then [tile N]
            else [obj BankName,N]
  | View.set_brush{Brush}
| BankList = litems w/80 lines/40 BankNames f: N =>
  | BankName <= N
  | if BankName >< terrain
    then | ItemList.data <= TileNames
         | ItemList.pick{TileNames.locate{plain}}
    else | ItemList.data <= $classes_banks.BankName
         | ItemList.pick{0}
| BrushPanel = hidden: layH: list BankList ItemList
| BrushPanel.show <= 1
| ArrowClick = Icon =>
| Arrows = 9{I=>icon data/I $img{"icons_arrow[I]"} click/ArrowClick}
| UnitPanelTitle = txt size/medium ''
| UnitPanelContents = hidden: dlg w/PanelW h/ScreenH: mtx
  | 2 2 | UnitPanelTitle
  |24 ScreenH-150 | layV s/2: map Xs Arrows.xs{7,0,1,6,8,2,5,4,3}.group{3}
                    | layH s/2 Xs
| UnitPanel = hidden: dlg: mtx
  | 0 0 | panel_bg PanelW ScreenH
  | 0 0 | UnitPanelContents
| Panel = dlg w/ScreenW h/ScreenH: mtx
  | 0 0 | BrushPanel
  | 0 0 | UnitPanel
| View.on_unit_pick <= Unit =>
  | UnitPanelContents.show <= Unit <> 0
  | when Unit
    | UnitPanelTitle.value <= Unit.class_name.title
| ModeIcon = No
| EditorModeIconClick = Icon =>
  | ModeIcon.picked <= 0
  | Icon.picked <= 1
  | ModeIcon <= Icon
  | View.editor_mode <= Icon.data
  | IsBrush = View.editor_mode >< brush
  | BrushPanel.show <= IsBrush
  | UnitPanel.show <= not IsBrush
| PickIcon = icon data/pick $img{icons_pick} click/EditorModeIconClick
| BrushIcon = icon data/brush $img{icons_brush} click/EditorModeIconClick
| WorldIcon = icon data/pick $img{icons_world} click: Icon =>
  | pause
  | WorldProperties.show <= 1
| PlayIcon = icon data/pick $img{icons_play} click: Icon =>
| SaveIcon = icon data/pick $img{icons_save} click: Icon =>
  | $save{"[$data]/work/worlds/test.txt"}
  //| show_message 'Saved' 'Your map is saved!'
| LoadIcon = icon data/pick $img{icons_load} click: Icon =>
  | $load{"[$data]/work/worlds/test.txt"}
| ExitIcon = icon data/pick $img{icons_exit} click: Icon =>
  | pause
  | Tabs.pick{main_menu}
| Icons = PickIcon,BrushIcon,spacer{8 0},WorldIcon,spacer{8 0},PlayIcon,
          spacer{8 0},SaveIcon,LoadIcon,spacer{8 0},ExitIcon
| ModeIcon <= BrushIcon
| BrushIcon.picked <= 1
| Ingame <= dlg w/ScreenW h/ScreenH: mtx
  |  0   0| spacer ScreenW ScreenH
  |  0   0| layH View,Panel
  |  2   2| layH s/8 Icons
  |  0   0| PauseSpacer
  |170 100| WorldProperties
  |  0   0| MessageBox
| View.init
| MenuBG = $img{ui_menu_bg}
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
                                        | unpause
                                        | Tabs.pick{ingame})}
            spacer{0 8}
            button{'Exit Program'   (=>get_gui{}.exit)}

| Tabs <= tabs ingame: t
          main_menu(MainMenu)
          ingame(Ingame)
          scenario(ScenarioMenu)
| BankList.pick{0}
| View.mode <= \editor
//| pause
| gui Tabs cursor/$img{ui_cursor_point}
