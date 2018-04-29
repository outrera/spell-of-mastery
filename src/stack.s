use fxn

type stack{Init} xs used
| if Init.is_int then $xs <= dup{Init}
  else | $xs <= dup{Init.size}
       | $init{Init}

stack.init Xs =
| $clear
| for X Xs: $push{X}

stack.push X = fxn: $xs.($used++) <= X

stack.pop = fxn:
| $used--
| $xs.$used

stack.alloc @Xs =
| Item = $pop
| Item.init{@Xs}
| Item

stack.size = $xs^_size

stack.clear = $used <= 0

stack.remove Item =
| Xs = []
| while $used
  | X = $pop
  | less X >< Item: push X Xs
| till Xs.end: $push{Xs^pop}

stack.`.` Index =
| less _tag Index: bad "stack.`.`: Index isnt integer"
| fxn $xs.($used - Index)

stack.list = dup I $used: fxn $xs.I

stack.map F = $list.map{F}

export stack