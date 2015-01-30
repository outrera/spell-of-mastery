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

act_move.start A =
| A.cycles <= A.unit.speed
| A.from_xy.init{A.unit.xy}
| A.unit.move{A.xyz}

Dirs = [[0 -1] [1 -1] [1 0] [1 1] [0 1] [-1 1] [-1 0] [-1 -1]]

act_move.update A =
| U = A.unit
| X,Y,Z = A.from-U.xyz
| XUnit = U.world.xunit
| YUnit = U.world.yunit
| when not (X and Y)
  | !XUnit/2
  | !YUnit/2
| X,Y = Dirs.((Dirs.locate{X,Y}+1)%Dirs.size)
| A.unit.xy.init{A.from_xy + [X*XUnit Y*YUnit]*A.cycles/U.speed}

act_move.finish A =
| A.unit.xy.init{A.from_xy}

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
   from/[0 0 0] // from x,y,z
   from_xy/[0 0]
   cycles // cooldown cycles remaining till the action safe-to-change state
   priority // used to check if action can be preempted
   data // data used by class

action.init ClassName XYZ =
| $xyz.init{XYZ}
| $from.init{$unit.xyz}
| $priority <= 50
| $class <= ActionClasses.ClassName
| $class_name <= ClassName
| $cycles <= 0
| less got $class: bad "unknown action class [ClassName]"
| $class.init{Me}
| Me

action.valid = $class and $class.valid{Me}

action.start = $class.start{Me}

action.update =
| $class.update{Me}
| !$cycles - 1

action.finish = $class.finish{Me}

export action