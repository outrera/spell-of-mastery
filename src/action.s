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
| A.unit.from_xyz.init{A.unit.xyz}
| A.unit.move{A.xyz}

act_move.update A =

act_move.finish A =
| A.unit.from_xyz.init{0,0,0}

ActionClasses = t still(act_still) move(act_move)

type action{unit}
   class
   class_name
   xyz/[0 0 0] // target x,y,z
   cycles // cooldown cycles remaining till the action safe-to-change state
   from // source cell of this action
   priority // used to check if action can be preempted
   data // data used by class

action.init ClassName XYZ =
| $xyz.init{XYZ}
| $priority <= 50
| $class <= ActionClasses.ClassName
| $class_name <= ClassName
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