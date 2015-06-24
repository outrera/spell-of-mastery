use ecs

component &health
component xyz/[0 0 0]
xyz.`.` Id = $array.Id
xyz.`!` Id Value = $array.Id.init{Value}



ECS = ecs 1024

new_unit = ECS.new{health/31 xyz/[1 2 3]}
O = new_unit

O.xyz <= [123 456 789]

say [O.health O.xyz]
