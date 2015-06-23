use stack


Entities =
FreedEntities =
Systems = t
Arrays =  t
Registered = []
Cycle = 0

ecs_init MaxEntities =
| Entities <= stack: dup Id MaxEntities Id
| FreedEntities <= stack Entities.size
| Size = Entities.size
| for Constructor Registered:
  | Array = dup Size 0
  | System = Constructor{Array}
  | System.init
  | Name = typename System
  | Systems.Name <= System
  | Arrays.Name <= Array

ecs_new @Components =
| Cs = Components
| Id = Entities.pop
| while Cs.size
  | Name = pop Cs
  | Value = pop Cs
  | System = Systems.Name
  | System.new{Id Value}
| Id

ecs_free Id = FreedEntities.push{Id}

ecs_array Name = Arrays.Name

ecs_register @Systems = for System Systems: push System Registered

ecs_update =
| Ss = Systems.list{}{?1}
| for S Ss: S.update
| while FreedEntities.used:
  | Id = FreedEntities.pop
  | for S Ss: S.free{Id}
  | Entities.push{Id}
| !Cycle+1


type component
component.init =
| IV = $init_value
| for I $array.size: $array.I <= IV.copy
component.new Id Value = $array.Id <= Value
component.free Id =
component.update =
component.init_value = 0


export ecs_init ecs_register ecs_update ecs_new ecs_free ecs_array component