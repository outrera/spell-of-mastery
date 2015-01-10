use common sprite class tile macros world util heap octree gui widgets view

Main = main: main_root
World = world Main 16

set_skin "[Main.data]ui"

View = view Main 600 600-5

TileNames = Main.tiles{}{?0}.skip{Main.aux_tiles.?^got}.sort
TileList = litems lines/32 TileNames f/(N => View.set_brush{[tile N]})
TileList.pick{TileNames.locate{plain}}


//View.set_brush{[obj N]}


BankName =

ClassList = litems lines/31 [] f/(N => say "[BankName]_[N]")
BankNames = Main.classes{}{?1}{?bank}.uniq.sort


BankList = droplist BankNames
  f/| N => | BankName <= N
           | Xs = Main.classes{}{?1}.keep{?bank >< BankName}{?name}.sort
           | ClassList.data <= Xs
           | ClassList.pick{0}


ObjList = layV [BankList ClassList]

Tabs = tabs tile: t tile(TileList) obj(ObjList)
TabsHeader = layH: list
  button{'Terrain' w_size/medium h_size/small (=> Tabs.pick{tile})}
  button{'Object' w_size/medium h_size/small (=> Tabs.pick{obj})}

Panel = layV [TabsHeader Tabs]

GUI = layH [Panel View]

View.init

gui GUI cursor/skin_cursor{point}

//T = octree 128
//T.set{3,3,3 123}
//say T.get{3,3,3}
//say T.neibs{3,3,3}

say 'Succeed!'
