// unit controlling related stuff
use action_ util

Acts = t


dact idle.start
| U = $unit
| less U.anim >< idle: U.animate{idle}
| when $cycles >< -1: $cycles <= 4

Dirs = list [0 -1] [1 -1] [1 0] [1 1] [0 1] [-1 1] [-1 0] [-1 -1]

move_start Me =
| U = $unit
| X,Y,Z = $xyz - U.xyz
| $fromXY.init{U.xy}
| $fromXYZ.init{U.xyz}
| U.move{$xyz}
| U.facing <= Dirs.locate{X,Y}
| when U.anim<>move: U.animate{move}
| when $cycles >< -1: $cycles <= U.speed
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
| move_start Me

dact move.update | move_update Me
dact move.finish | move_finish Me

dact attack.valid
| T = $target
| when T.is_list or T.removed or T.empty or not T.alive: leave 0
| 1

dact attack.init | $data <= 0

dact attack.start
| U = $unit
| U.face{$target.xyz}
| $cycles <= max 1 U.sprite.anim_speed{attack}
| U.animate{attack}
| U.sound{attack}
dact attack.update
| U = $unit
| when U.anim_hit:
  | U.anim_hit <= 0
  | Target = $target
  | when U.impact: U.effect{U.impact Target Target.xyz}
  | when Target.harm{U U.damage}
  | $cycles <= 0
  | less U.range: Target.run_effects{?><counter U U.xyz}
  | leave

dact attack.finish | move_finish Me

dact die.start
| U = $unit
| U.animate{death}
| less not (U.class.hp-U.hp)>0 or got U.sprite.anims.death:
  | U.free
  | $cycles <= 1000

dact die.finish | $unit.free


dact swap.valid
| T = $target
| less $target and not $target.removed: leave 0
| U = $unit
| Turn = U.world.turn
| U.owner.id >< T.owner.id and T.idle

dact swap.start
| U = $unit
| move_start Me
| T = $target
| O = T.order
| O.init{type/move at/$fromXYZ}
| O.priority <= 100
| less T.has{btrack}:
  | less U.goal and U.goal.xyz >< T.xyz:
    | T.backtrack <= T.xyz

dact swap.update | move_update Me

dact swap.finish | move_finish Me


dact teleport.start | $unit.move{$xyz}

dact custom.valid
| Affects = $affects
| As = if Affects.is_list then Affects
       else | when Affects >< any: leave 1
            | [Affects]
| for A As:
  | if A >< unit then
     | when $target: leave 1
    else if A >< ally then
     | when $target and not $unit.owner.is_enemy{$target.owner}: leave 1
    else if A >< empty then
     | when no $unit.world.block_at{$xyz}: leave 1
    else if A >< ally_block then
     | Block = $unit.world.block_at{$xyz}
     | when got Block and not $unit.owner.is_enemy{Block.owner}: leave 1
    else $unit.owner.notify{"custom.valid: bad affects specifier - [A]"}
| 0

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
default_start Me = $cycles <= $unit.speed
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
   act_init/&default_init
   act_valid/&default_valid
   act_start/&default_start
   act_update/&default_update
   act_finish/&default_finish

action.as_text = "#action{[$type] [$priority] [$target]}"

action.init type/idle name/0 at/0 affects/0 target/0
            cost/0 before/0 after/0 speed/-1 range/No =
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
| Points = points_in_circle R
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

export action action_list_moves