use stack

type item{id} ctrls

item._ Method Args =
| Type = Method^_method_name
| Cs = $ctrls^uncons{next}
| if Args.size > 1
  then | Type = Type.tail
       | for C Cs: when C.type >< Type: C.value <= Args.1
       | leave 0
  else for C Cs: when C.type >< Type: leave C.value
| No

item.update =
| for D $ctrls^uncons{next}: D.update

ctrl TypeName @Args =
| form @| type TypeName active/1 next item $@Args

type ecs{max_items} cycle items ctrls active
| $items <= stack: dup Id $max_items: item Id
| $ctrls <= t
| $active <= stack $max_items*50

ecs.update =
| for A $active: A.update
| NextActive = []
| while $active.used
  | A = $active.pop
  | when A.active: push A NextActive
| for A NextActive: $active.push{A}
| !$cycle + 1

ecs.register Constructor =
| Xs = dup $max_items Constructor{}
| Type = Xs.0.type
| $ctrls.Type <= stack Xs

ecs.new @Components =
| Item = $items.pop
| Item.ctrls <= 0
| for Type Components:
  | TypeStack = $ctrls.Type
  | less got TypeStack: bad "ecs.new: missing type - [Type]"
  | C = TypeStack.pop
  | C.item <= Item
  | when C.active: $active.push{C}
  | C.next <= Item.ctrls
  | Item.ctrls <= C
| Item


export ecs 'ctrl'