use common sprite class tile macros world util heap octree gui widgets view

Main = main: main_root
World = world Main 16

set_skin "[Main.data]ui"

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

gui GUI cursor/skin_cursor{point}

//T = octree 128
//T.set{3,3,3 123}
//say T.get{3,3,3}
//say T.neibs{3,3,3}

say 'Succeed!'
