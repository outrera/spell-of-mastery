use common sprite class tile macros world util heap octree gui widgets view

Main = main: main_root
World = world Main 16

set_skin "[Main.data]ui"

View = view Main 640 600

BankName =
TileBrush = 
ObjBrush = 


TileNames = Main.tiles{}{?0}.skip{Main.aux_tiles.?^got}.sort
TileList = litems lines/33 TileNames f/
| N => | TileBrush <= [tile N]
       | View.set_brush{TileBrush}


ClassList = litems lines/32 [] f/
| N => | ObjBrush <= [obj "[BankName]_[N]"]
       | View.set_brush{ObjBrush}

BankNames = Main.classes{}{?1}{?bank}.uniq.sort


BankList = droplist BankNames
  f/| N => | BankName <= N
           | Xs = Main.classes{}{?1}.keep{?bank >< BankName}{?class_name}.sort
           | ClassList.data <= Xs
           | ClassList.pick{0}


ObjList = layV [BankList ClassList]

Tabs = tabs tile: t tile(TileList) obj(ObjList)

pickTab Tab Brush =
| Tabs.pick{Tab}
| View.set_brush{Brush}

TabsHeader = layH: list
  (button 'Terrain' w_size/medium h_size/small: => pickTab tile TileBrush)
  (button 'Object' w_size/medium h_size/small: => pickTab obj ObjBrush)

TileList.pick{TileNames.locate{plain}}

Panel = layV [TabsHeader Tabs]

//GUI = layH.[Panel View]
GUI = dlg w/800 h/600: list [0 0 layH.[Panel View]]

View.init

gui GUI cursor/skin_cursor{point}

//T = octree 128
//T.set{3,3,3 123}
//say T.get{3,3,3}
//say T.neibs{3,3,3}

say 'Succeed!'
