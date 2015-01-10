type stack{Size} xs/dup{Size} used

stack.push X =
| $xs.$used <= X
| !$used+1

stack.pop X = as X $xs.$used: !$used-1

stack.size = $xs.size

stack.`.` Index = $xs.($used - Index)

export stack