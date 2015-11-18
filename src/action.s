// unit controlling related stuff
use action_ util

Acts = t


dact idle.start | when $cycles >< -1: $cycles <= 4

Dirs = list [0 -1] [1 -1] [1 0] [1 1] [0 1] [-1 1] [-1 0] [-1 -1]

move_start Me =
| U = $unit
| X,Y,Z = $xyz - U.xyz
| $fromXY.init{U.xy}
| $fromXYZ.init{U.xyz}
| U.move{$xyz}
| U.facing <= Dirs.locate{X,Y}
| U.animate{move}
| $start_cycles <= $cycles
| U.sound{move}

move_update Me =
| U = $unit
| X,Y,Z = $fromXYZ-U.xyz
| XUnit = U.world.xunit
| YUnit = U.world.yunit
| when not (X and Y)
  | !XUnit/2
  | !YUnit/2
| X,Y = Dirs.((Dirs.locate{X,Y}+1)%Dirs.size)
| U.xy.init{$fromXY + [X*XUnit Y*YUnit]*$cycles/$start_cycles}

move_finish Me =
| U = $unit
| U.xy.init{$fromXY}

dact move.valid
| U = $unit
| U.world.no_block_at{$xyz} and U.can_move{U.xyz $xyz}

dact move.start
| U = $unit
| when $cycles >< -1: $cycles <=  U.sprite.speed
| move_start Me
| X,Y,Z = U.xyz
| less U.seen
  | $cycles <= 0
  | move_finish Me

dact move.update | move_update Me
dact move.finish | move_finish Me

dact attack.valid
| T = $target
| when T.is_list or T.removed or T.empty or not T.health: leave 0
| U = $unit
//| when U.skirmisher: leave (T.xyz - U.xyz).all{?.abs<<1}
| if U.ranged then 1 else U.can_move{U.xyz T.xyz}

dact attack.init | $data <= 0

dact attack.start
| U = $unit
| U.face{$target.xyz}
| $cycles <= max 1 U.sprite.anim_speed{attack}
| U.animate{attack}
| U.sound{attack}
dact attack.update
| U = $unit
| when $cycles > 9000 // if target is dying, wait till it is dead
  | when U.world.waiting: leave
  | $target <= 0
  | when $unit.ranged:
    | $cycles <= 1
    | leave
  | less $unit.ranged: 
    | $cycles <= max 1 U.sprite.speed/2
    | move_start Me
  | leave
| when $data > 0: move_update Me
| when $cycles >< 1 and $data < 2:
  | when $data >< 1:
    | leave
    | less $unit.ranged: leave
    | move_finish Me
    | $xyz.init{$fromXYZ}
    | $cycles <= max 1 $unit.sprite.speed*2/3
    | move_start Me
    | $data <= 2
  | when $data >< 0:
    | Target = $target
    | U.world.effect{Target.xyz blood}
    | when U.impact: U.effect{U.impact Target Target.xyz}
    | when Target.harm{U U.attack}
    | U.animate{idle}
    | when Target.hits < Target.health:
      | $data <= 2
      | $cycles <= 0
      | less U.ranged:
        | for [When Name Duration Params] Target.effects: when When><counter:
          | Effect = Target.main.params.effect.Name
          | Target.effect{Effect U U.xyz}
      | leave
    | $data <= 1
    | $cycles <= 90000

dact attack.finish | move_finish Me

dact die.start
| U = $unit
| U.animate{death}
| less not U.hits or got U.sprite.anims.death:
  | U.free
  | $cycles <= 1000

dact die.finish | $unit.free


dact swap.valid
| T = $target
| less $target and not $target.removed: leave 0
| U = $unit
| Turn = U.world.turn
| U.owner.id >< T.owner.id and U.moved < Turn and T.moved < Turn

dact swap.start
| U = $unit
| $cycles <= max 1 U.sprite.speed
| move_start Me
| $target.order.init{type/move at/$fromXYZ}

dact swap.update | move_update Me

dact swap.finish | move_finish Me


can_push Me U =
| less U.movable: leave 0
| D = U.xyz-$xyz
| MoveXYZ = U.xyz+D
| B = $world.block_at{MoveXYZ}
| when got B and not B.empty: leave 0
| less $world.at{@MoveXYZ}.empty: leave 0
| MoveXYZ.2 <= $world.fix_z{MoveXYZ}
| B = $world.block_at{MoveXYZ}
| when got B and not B.empty: leave 0
| less $world.at{@MoveXYZ}.empty: leave 0
| 1

dact push.valid
| less can_push $unit $target: leave 0

dact push.start
| U = $unit
| Wr = U.world
| T = $target
| D = T.xyz-U.xyz
| TXYZ = T.xyz+D
| TXYZ.2 <= Wr.fix_z{TXYZ}
| D.2 <= TXYZ.2-T.xyz.2
| Bs = []
| X,Y,Z = T.xyz
| while Wr.units_at{X,Y,Z}.size
  | Ks = Wr.units_at{X,Y,Z}
  | for K Ks: push K Bs
  | !Z + (max 1 Ks{?height}.max)
| for B Bs.flip: B.move{B.xyz+D}
| $cycles <= max 1 U.sprite.speed
| move_start Me

dact push.update | move_update Me

dact push.finish | move_finish Me


dact teleport.start | $unit.move{$xyz}

dact custom.valid
| when $affects >< unit: leave $target
| U = $unit
| when $affects >< ally: leave: $target and not U.owner.is_enemy{$target.owner}
| when $affects >< empty: leave U.world.units_at{$xyz}.all{?empty}
| 1

dact custom.start
| U = $unit
| when $speed <> -1: $cycles <= $speed
| U.animate{attack}
| U.face{$xyz}
| when $before: U.effect{$before $target $xyz}

dact custom.finish
| U = $unit
| when $after: U.effect{$after $target $xyz}

default_init Me =
default_valid Me = 1
default_start Me = $cycles <= $unit.sprite.speed
default_update Me =
default_finish Me =

for Name,Act Acts
| have Act.init &default_init
| have Act.valid &default_valid
| have Act.start &default_start
| have Act.update &default_update
| have Act.finish &default_finish

type action{unit}
   type
   name
   affects
   target // when action targets a unit
   xyz/[0 0 0] // target x,y,z
   cycles // cooldown cycles remaining till the action safe-to-change state
   start_cycles
   priority // used to check if action can be preempted
   fromXYZ/[0 0 0]
   fromXY/[0 0]
   speed
   data // data used by action handlers
   cost
   before
   after
   range
   path
   act_init/&default_init
   act_valid/&default_valid
   act_start/&default_start
   act_update/&default_update
   act_finish/&default_finish

action.as_text = "#action{[$type] [$priority] [$target]}"

action.init type/idle name/0 at/0 affects/0 target/0
            cost/0 before/0 after/0 path/0 speed/-1 range/No =
| when Target: At <= Target.xyz
| less At: At <= $unit.xyz
| $xyz.init{At}
| $affects <= Affects
| $target <= Target
| $range <= Range
| $priority <= 50
| $type <= Type
| A = Acts.Type
| less got A: bad "unknown action type [Type]"
| $act_init <= A.init
| $act_valid <= A.valid
| $act_start <= A.start
| $act_update <= A.update
| $act_finish <= A.finish
| $name <= Name
| $cycles <= -1
| $cost <= Cost
| $speed <= Speed
| $before <= Before
| $after <= After
| $path <= Path
| $act_init{}{Me}
| Me

action.valid =
| $act_valid{}{Me}

action.start =
| $act_start{}{Me}

action.update =
| $act_update{}{Me}
| !$cycles - 1

action.finish =
| $act_finish{}{Me}
| when $path: $path^uncons{path}{?free}

action_list_moves Picked Act =
| Me = Picked.world
| A = action Picked
| A.init{@Act.list.join}
| Affects = Act.affects
| Path = []
| Moves = []
| R = Act.range
| less got R: leave Moves
| PXYZ = Picked.xyz
| Points = if R.is_int then points_in_circle R else points_in_matrix R.tail
| for X,Y Points
  | XYZ = PXYZ+[X Y 0]
  | X = XYZ.0
  | Y = XYZ.1
  | when X>0 and X<<$w and Y>0 and Y<<$h:
    | XYZ.2 <= $fix_z{XYZ}
    | Target = $block_at{XYZ}^~{No 0}
    | Valid = 1
    | when Target and Affects >< empty: Valid <= 0
    | when not Target and Affects >< unit: Valid <= 0
    | A.xyz.init{XYZ}
    | A.target <= Target
    | if Valid and A.valid
      then push XYZ Moves
      else push XYZ Path
| [Moves Path]

export action can_push action_list_moves