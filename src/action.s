// unit controlling related stuff

type act_class

act_class.init A =
act_class.valid A = 1
act_class.start A = A.cycles <= A.unit.speed
act_class.update A =
act_class.finish A =

type act_still.act_class name/still anim/still

act_still.start A = A.cycles <= 4

type act_move.act_class name/move anim/move

act_move.valid A = 
| U = A.unit
| less (A.xyz-U.xyz).all{?abs<<1}: leave 0
| U.can_move_to{A.xyz}

Dirs = list [0 -1] [1 -1] [1 0] [1 1] [0 1] [-1 1] [-1 0] [-1 -1]

act_move.start A =
| U = A.unit
| A.cycles <= U.speed
| FromXYZ = U.xyz.copy
| X,Y,Z = A.xyz - FromXYZ
| From = U.world.alloc_unit{unit_nil}
| A.from <= From
| From.xy.init{U.xy}
| U.move{A.xyz}
| From.move{FromXYZ}
| U.animate{move}
| From.animate{still}

act_move.update A =
| U = A.unit
| From = A.from
| X,Y,Z = From.xyz-U.xyz
| XUnit = U.world.xunit
| YUnit = U.world.yunit
| when not (X and Y)
  | !XUnit/2
  | !YUnit/2
| X,Y = Dirs.((Dirs.locate{X,Y}+1)%Dirs.size)
| U.xy.init{From.xy + [X*XUnit Y*YUnit]*A.cycles/A.start_cycles}

act_move.finish A =
| U = A.unit
| From = A.from
| U.xy.init{From.xy}
| U.animate{still}
| From.free

type act_attack.act_class name/move anim/attack

act_attack.valid A = not: A.target.is_list or A.target.removed or A.target.empty

act_attack.start A =
| A.target.free


ActionClasses = t still(act_still) move(act_move) attack(act_attack)

type action{unit}
   class
   class_name
   target // when action targets a unit
   xyz/[0 0 0] // target x,y,z
   cycles // cooldown cycles remaining till the action safe-to-change state
   start_cycles
   priority // used to check if action can be preempted
   from // simulacrum related to previous position (aka came_from operator)
   data // data used by class

action.init ClassName XYZ =
| $xyz.init{XYZ}
| $from <= 0
| $priority <= 50
| $class <= ActionClasses.ClassName
| $class_name <= ClassName
| $cycles <= 0
| less got $class: bad "unknown action class [ClassName]"
| $class.init{Me}
| Me

action.valid = $class and $class.valid{Me}

action.start =
| $class.start{Me}
| $start_cycles <= $cycles

action.update =
| $class.update{Me}
| !$cycles - 1

action.finish = $class.finish{Me}

export action