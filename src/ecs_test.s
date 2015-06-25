use ecs

//FIXME: use linked lists to determine which entities belong to which systems

component &health
component &&xyz/[0 0 0]

//health.update = 

ECS = ecs 1024

new_unit = ECS.new{health/31 xyz/[1 2 3]}
B = new_unit
A = new_unit

A.xyz <= [123 456 789]



say [A.health A.xyz]
