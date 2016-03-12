use stack

_.enheap = Me
_.heapfree =

type sexp.list{head tail}
sexp.end = 0
sexp.as_text = "[$list]"
sexp.is_list = 1

MAXConses = 64000

SEXPConses = stack: dup MAXConses: sexp 0 []

sexp_cons Head Tail =
| C = SEXPConses.pop
| C.head <= Head
| C.tail <= Tail
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
| for X Me.flip: Ys <= sexp_cons X.enheap Ys
| Ys

_.unheap = Me
sexp.unheap = map X Me: X.unheap

sexp.heapfree1 =
| H = Me.head
| T = Me.tail
| Me.head <= 0
| Me.tail <= 0
| H.heapfree
| SEXPConses.push{Me}
| T
