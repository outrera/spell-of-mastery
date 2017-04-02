rle_encode Xs =
| Ys = []
| Last = No
| times I Xs.size
  | X = Xs.I
  | if X><Last
    then | Y = Ys.0
         | less Y.is_list
           | Y <= [1 Y]
           | Ys <= [Y @Ys.tail]
         | Y.0++
    else
      | push X Ys
      | Last <= X
| Ys.flip

rle_decode Xs =
| L = 0
| for X Xs: if X.is_list then L+=X.0 else L++
| Ys = dup L 0
| J = 0
| for X Xs: if X.is_list
  then | V = X.1
       | times K X.0: Ys.(J++) <= V
  else Ys.(J++) <= X
| Ys

export rle_encode rle_decode
