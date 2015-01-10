use macros

points X Y W H = dup I W*H [X+I%W Y+I/W]

list.overlaps [BX BY BW BH] =
| [AX AY AW AH] = Me
| AX<BX+BW and AY<BY+BH and BX<AX+AW and BY<AY+AH

Dirs = 8{(?.float-2.0)*PI/4.0}{[?.cos ?.sin].round.int}
dirN V = Dirs.locate{V.sign}

load_params Params File =
| less File.exists: bad "cant open [File]"
| for Key,Value File.get.utf8.parse{src File}.tail{}{?1.0,?2.0}
  | case Value [`,` A B]
    | Value <= Value^| @r [`,` A B] => [@A^r B]
                     | X => [X]
  | Params.Key <= Value


export points Dirs dirN load_params
