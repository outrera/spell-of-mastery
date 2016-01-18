// unit controlling related stuff
use action_

Acts = t


dact idle.start
| U = $unit
| less U.anim >< idle: U.animate{idle}

Dirs = list [0 -1] [1 -1] [1 0] [1 1] [0 1] [-1 1] [-1 0] [-1 -1]

move_start Me =
| U = $unit
| X,Y,Z = $xyz - U.xyz
| $fromXY.init{U.xy}
| $fromXYZ.init{U.xyz}
| U.move{$xyz}
| U.facing <= Dirs.locate{X,Y}
| when U.anim<>move: U.animate{move}
| $cycles <= U.speed
| $start_cycles <= $cycles
| Effect = U.class.moves
| when Effect: U.effect{Effect U U.xyz}

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


dact missile.start
| U = $unit
| X,Y,Z = $xyz - U.xyz
| $fromXY.init{U.xy}
| $fromXYZ.init{U.xyz}
| U.facing <= Dirs.locate{X,Y}
| $cycles <= 24*5
| $start_cycles <= $cycles

dact missile.update
| U = $unit
| X,Y,Z = $xyz-U.xyz
| XUnit = U.world.xunit
| YUnit = U.world.yunit
//| when not (X and Y)
//  | !XUnit/2
//  | !YUnit/2
//| X,Y = Dirs.((Dirs.locate{X,Y}+1)%Dirs.size)
| U.xy.init{$fromXY + [X*XUnit Y*YUnit]*($start_cycles-$cycles)/$start_cycles}


//dact missile.finish | move_finish Me


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
| O.init{move $fromXYZ}
| O.priority <= 100
| less T.has{btrack}:
  | less U.goal and U.goal.xyz >< T.xyz:
    | T.backtrack <= T.xyz

dact swap.update | move_update Me

dact swap.finish | move_finish Me


dact teleport.start | $unit.move{$xyz}

custom_init Me =
custom_valid Me =
| Affects = $affects
| As = if Affects.is_list then Affects
       else | when Affects >< any: leave 1
            | [Affects]
| T = $target
| HasTarget = T and not T.removed
| for A As:
  | if A >< unit then
     | when HasTarget: leave: not T.empty
    else if A >< ally then
     | when HasTarget and not $unit.owner.is_enemy{T.owner}: leave 1
    else if A >< empty then
     | when no $unit.world.block_at{$xyz}: leave 1
    else if A >< ally_block then
     | Block = $unit.world.block_at{$xyz}
     | when got Block and not $unit.owner.is_enemy{Block.owner}: leave 1
    else $unit.owner.notify{"custom.valid: bad affects specifier - [A]"}
| 0

custom_start Me =
| U = $unit
| U.animate{attack}
| U.face{$xyz}
| when $before: U.effect{$before $target $xyz}
custom_update Me =
| U = $unit
| when U.anim_hit:
  | U.anim_hit <= 0
  | Target = $target
  | when $impact: U.effect{$impact Target Target.xyz}
  | leave
custom_finish Me =
| U = $unit
| when $after: U.effect{$after $target $xyz}


default_init Me =
default_valid Me = 1
default_start Me =
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
   act
   cycles // cooldown cycles remaining till the action safe-to-change state
   priority
   xyz/[0 0 0] // target x,y,z
   target // when action targets a unit
   fromXYZ/[0 0 0]
   fromXY/[0 0]
   start_cycles
   range
   act_init/&default_init
   act_valid/&default_valid
   act_start/&default_start
   act_update/&default_update
   act_finish/&default_finish

world.action Unit = action Unit

action.main = $unit.main

action.cost = if $act then $act.cost else 0
action.affects = $act.affects
action.before = $act.before
action.impact = $act.impact
action.after = $act.after

action.as_text = "#action{[$type] [$priority] [$target]}"
action.init Act Target =
| $type <= if Act.is_text then Act else Act.name
| XYZ = if Target.is_list then Target
        else if Target then Target.xyz
        else $unit.xyz
| $xyz.init{XYZ}
| $target <= if Target.is_list then 0 else Target
| A = Acts.$type
| if got A then
    | $act <= 0
    | $range <= 1
    | $cycles <= 4
    | $priority <= 50
    | $act_init <= A.init
    | $act_valid <= A.valid
    | $act_start <= A.start
    | $act_update <= A.update
    | $act_finish <= A.finish
  else
    | $act <= if Act.is_text then $main.params.acts.$type else Act
    | less got $act:
      | bad "unknown action type [$type]"
      | $init{idle 0}
      | leave
    | $range <= $act.range
    | $cycles <= $act.speed
    | $priority <= $act.priority
    | $act_init <= &custom_init
    | $act_valid <= &custom_valid
    | $act_start <= &custom_start
    | $act_update <= &custom_update
    | $act_finish <= &custom_finish
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
