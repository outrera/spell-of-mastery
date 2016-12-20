use macros

Dirs4 = [[0 -1] [1 0] [0 1] [-1 0]]

// take up to N elements
list.upto N = $take{|min $size N}

points X Y W H = dup I W*H [X+I%W Y+I/W]

list.overlaps [BX BY BW BH] =
| AX,AY,AW,AH = Me
| AX<BX+BW and AY<BY+BH and BX<AX+AW and BY<AY+AH

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

normalize_curly E =
| case E
  [`{}` Name Args @Rest]
    | if Rest.size then Args <= [Args @Rest]
      else case Args [`,` @_]: Args <= Args^|@r [`,` X Y]=>[@(r X) Y]; X => [X]
    | [Name Args]
  Else | E


export points Dirs Dirs4 dirN add_border_to_matrix
       points_in_square points_in_circle
       points_in_matrix normalize_curly
