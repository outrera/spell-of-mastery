// unit controlling related stuff

type act_class

act_class.init A =
act_class.valid A = 1
act_class.start A = A.cycles <= A.unit.speed
act_class.update A =
act_class.finish A =

type act_still.act_class name/still anim/still

act_still.start A =  when A.cycles >< -1: A.cycles <= 4

type act_move.act_class name/move anim/move

act_move.valid A = 
| U = A.unit
| less (A.xyz-U.xyz).all{?abs<<1}: leave 0
| U.can_move_to{A.xyz}

// dirs requiring dummy to avoid overlapping unit with tiles
OverlapDirs = list [-1  1] [-1  0] [-1 -1] [ 0 -1]

Dirs = list [0 -1] [1 -1] [1 0] [1 1] [0 1] [-1 1] [-1 0] [-1 -1]


move_start A =
| U = A.unit
| X,Y,Z = A.xyz - U.xyz
| U.movement_render_hack <= got OverlapDirs.locate{X,Y}
| A.fromXY.init{U.xy}
| A.fromXYZ.init{U.xyz}
| U.move{A.xyz}
| U.animate{move}

move_update A =
| U = A.unit
| X,Y,Z = A.fromXYZ-U.xyz
| XUnit = U.world.xunit
| YUnit = U.world.yunit
| when not (X and Y)
  | !XUnit/2
  | !YUnit/2
| X,Y = Dirs.((Dirs.locate{X,Y}+1)%Dirs.size)
| U.xy.init{A.fromXY + [X*XUnit Y*YUnit]*A.cycles/A.start_cycles}

move_finish A =
| U = A.unit
| U.xy.init{A.fromXY}
| U.animate{still}
| U.movement_render_hack <= 0

act_move.start A =
| when A.cycles >< -1: A.cycles <=  A.unit.speed
| move_start A

act_move.update A = move_update A

act_move.finish A = move_finish A

type act_attack.act_class name/move anim/attack

act_attack.valid A = not: A.target.is_list or A.target.removed or A.target.empty

act_attack.init A =
| A.data <= 0

act_attack.start A =
| U = A.unit
| A.cycles <= max 1 U.speed/2
| move_start A

act_attack.update A =
| move_update A
| when A.cycles >< 1 and not A.data:
  | move_finish A
  | A.target.free
  | A.target <= 0
  | A.xyz.init{A.fromXYZ}
  | A.cycles <= max 1 A.unit.speed*2/3
  | move_start A
  | A.data <= 1

act_attack.finish A =
| move_finish A

ActionClasses = t still(act_still) move(act_move) attack(act_attack)

type action{unit}
   class
   class_name
   target // when action targets a unit
   xyz/[0 0 0] // target x,y,z
   cycles // cooldown cycles remaining till the action safe-to-change state
   start_cycles
   priority // used to check if action can be preempted
   fromXYZ/[0 0 0]
   fromXY/[0 0]
   data // data used by class

action.init ClassName XYZ =
| $xyz.init{XYZ}
| $priority <= 50
| $class <= ActionClasses.ClassName
| $class_name <= ClassName
| $cycles <= -1
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