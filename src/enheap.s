use stack

_.enheap = Me
_.heapfree =

type sexp.list{head tail}
sexp.end = 0
sexp.as_text = "[$list]"
sexp.is_list = 1

MAXConses = 64000 //FIXME: should be dynamic or user-provided

SEXPConses = stack: dup MAXConses: sexp 0 []

sexp.cons Head =
| C = SEXPConses.pop
| C.head <= Head
| C.tail <= Me
| C

list.cons Head =
| C = SEXPConses.pop
| C.head <= Head
| C.tail <= Me
| C

sexp.heapfree =
| while Me.is_sexp
  | H = Me.head
  | Me.head <= 0
  | T = Me.tail.heapfree
  | SEXPConses.push{Me}
  | Me <= T
  | when H.is_sexp: H.heapfree

sexp.`!` K V =
| times I K: Me <= $tail
| $head <= V

list.enheap =
| Ys = []
| for X Me.flip: Ys <= Ys.cons{X.enheap}
| Ys

_.unheap = Me
sexp.unheap = map X Me: X.unheap

sexp.uncons =
| T = Me.tail
| Me.head <= 0 //just in case there is a dangling pointer to us
| Me.tail <= 0
| SEXPConses.push{Me}
| T

sexp.heapfree1 =
| H = Me.head
| T = Me.tail
| Me.head <= 0
| Me.tail <= 0
| H.heapfree
| SEXPConses.push{Me}
| T
