use stack

ECS =
Systems =
Registered = []

ecs_register @Systems = for System Systems: push System Registered

type ecs{max_entities}
     entities freed systems/(t) arrays/(t) cycle
| ECS <= Me
| Systems <= $systems
| $entities <= stack: @flip: dup Id $max_entities Id
| $freed <= stack $entities.size
| Size = $entities.size
| I = 0
| for Constructor Registered:
  | Array = dup Size 0
  | System = Constructor{Me I Array}
  | System.init
  | Name = typename System
  | $systems.Name <= System
  | $arrays.Name <= Array
  | !I+1

ecs.new @Components =
| Cs = Components
| Id = $entities.pop
| while Cs.size
  | Name = pop Cs
  | Value = pop Cs
  | System = $systems.Name
  | less got System: bad "ECS: unknown system - [Name]"
  | System.new{Id Value}
| Id

ecs.free Id = $freed.push{Id}
ecs.array Name = $arrays.Name
ecs.`.` Name = $systems.Name

ecs.update =
| Ss = $systems.list{}{?1}
| for S Ss: S.update
| while $freed.used:
  | Id = $freed.pop
  | for S Ss: S.free{Id}
  | $entities.push{Id}
| !$cycle+1


int.`.` System = Systems.System.Me
int.`!` System Value = Systems.System.Me <= Value

type component_
component_.init =
| IV = $init_value
| when IV: for I $array.size: $array.I <= IV.copy
component_.new Id Value = Me.Id <= Value
component_.free Id =
component_.update =
component_.init_value = 0
component_.`.` Id = $array.Id
component_.`!` Id Value = $array.Id <= Value


component Name @Fields =
| Fast = 0
| InitValue = 0
| case Name [`&` N]
  | Fast <= 1
  | Name <= N
| case Name [`/` N IV]
  | InitValue <= IV
  | Name <= N
| Component_ = "Component_[Name]_"
| Array_ = "Array_[Name]_"
| Me = \Me
| V = form ~V
| Xs = form
  | Array_ =
  | Component_ =
  | type Name.component_{ecs id array} $@Fields
    | Component_ <= Me
    | Array_ <= Me.array
  | Name.init_value = InitValue
  | ecs_register &Name
| Accessors = @tail: form
  | int.Name = $if Fast
                then form Array_.Me
                else form Component_.Me
  | int.$"![Name]" V = $@if Fast
                         then form: Array_.Me <= V
                         else form: Component_.Me <= V
| form @$[@Xs @Accessors]

export ecs ecs_register component_ 'component'