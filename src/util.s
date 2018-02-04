use macros

Dirs4 = [[0 -1] [1 0] [0 1] [-1 0]]
Dirs43 = [[0 -1 0] [1 0 0] [0 1 0] [-1 0 0]]

list.has Item = got $find{Item}

// take up to N elements
list.upto N = $take{|min $size N}

points X Y W H = dup I W*H [X+I%W Y+I/W]

list.overlaps [BX BY BW BH] =
| AX,AY,AW,AH = Me
| AX<BX+BW and AY<BY+BH and BX<AX+AW and BY<AY+AH

//Dirs.(Unit.facing) would give direction Unit is facing
Dirs = 8{(?.float-2.0)*PI/4.0}{[?.cos ?.sin].round.int}
dirN V = Dirs.locate{V.sign}


add_border_to_matrix Ms Value =
| Pad = dup Ms.size Value
| [Pad @Ms Pad]{[Value @? Value]}

points_in_square R = points{-R -R R*2+1 R*2+1}

points_in_circle R = 
| RR = R*R
| points_in_square{R}.keep{X,Y=>(X*X+Y*Y)<<RR}

points_in_matrix Ms =
| R = Ms.size/2
| points_in_square{R}.keep{X,Y=>Ms.(R+Y).(R+X)}

points_in_diamond R =
| Ps = []
| RR = R*2+1
| for Y R:
  | C = Y*2+1
  | X = (RR-C)/2
  | for I C:
    | push [X+I-R Y-R] Ps
    | push [X+I-R R-Y] Ps
| for I RR: push [I-R 0] Ps
| Ps

export points Dirs Dirs4 Dirs43 dirN add_border_to_matrix
       points_in_square points_in_circle
       points_in_matrix points_in_diamond
