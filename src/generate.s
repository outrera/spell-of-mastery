use util

Rooms = list
  '+ . . . +
   . _ _ _ .
   . _ _ _ .
   . _ _ _ .
   + . _ . +'

type room{w h lines}

room.draw W SX SY SZ = 
| Wall = W.main.tiles.wall
| Bricks = W.main.tiles.bricks
| Void = W.main.tiles.void
| for X,Y points{0 0 $w $h}:
  | C = $lines.Y.X
  | Tile = case C '+'(Bricks) '.'(Wall) Else(Void)
  | when Tile.id: W.dirty_set{SX+X SY+Y SZ Tile}

Rooms <= map R Rooms
         | Ls = R.skip{' '}.lines
         | W = Ls.0.size
         | H = Ls.size
         | less Ls.all{?size >< W}: bad 'room [R]'
         | room W H Ls

world.generate W H =
| $clear
| $w <= W
| $h <= H
| for P points{0 0 $w $h}: $push_{P $filler}
| Rooms.0.draw{Me 1 1 1}
| Rooms.0.draw{Me 1 1 5}
| for X,Y points{1 1 $w+1 $h+1}: $updPilarGfxes{X Y}
