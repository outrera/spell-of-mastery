type stack{Size} xs/dup{Size} used

stack.push X =
| $xs.$used <= X
| !$used+1

stack.pop =
| !$used-1
| $xs.$used

stack.size = $xs.size

stack.`.` Index = $xs.($used - Index)

export stack