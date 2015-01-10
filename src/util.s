use macros

points X Y W H = dup I W*H [X+I%W Y+I/W]

list.overlaps [BX BY BW BH] =
| [AX AY AW AH] = Me
| AX<BX+BW and AY<BY+BH and BX<AX+AW and BY<AY+AH

Dirs = 8{(?.float-2.0)*PI/4.0}{[?.cos ?.sin].round.int}
dirN V = Dirs.locate{V.sign}

export points Dirs dirN
