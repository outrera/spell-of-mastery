use stack

_.dynamize = Me
_.dynafree =

type sexp.list{head tail}
sexp.end = 0
sexp.as_text = "[$list]"

MAXConses = 4000

SEXPConses = stack: dup MAXConses: sexp 0 []

sexp_cons Head Tail =
| C = SEXPConses.pop
| C.head <= Head
| C.tail <= Tail
| C

sexp.dynafree =
| while Me.is_sexp
  | H = Me.head
  | Me.head <= 0
  | T = Me.tail.dynafree
  | SEXPConses.push{Me}
  | Me <= T
  | when H.is_sexp: H.dynafree

list.dynamize =
| Ys = []
| for X Me.flip: Ys <= sexp_cons X.dynamize Ys
| Ys