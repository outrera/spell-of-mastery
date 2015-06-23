use ecs


type health.component{array}

type pos.component{array}
pos.init_value = [0 0 0]
pos.new Id Value = $array.Id.init{Value}

ecs_register &health &pos

ecs_init 1024

Health = ecs_array health
Pos = ecs_array pos

O = ecs_new health/31 pos/[1 2 3]

say [Health.O Pos.O]
