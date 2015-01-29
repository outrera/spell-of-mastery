type act_class

act_class.forced = 0
act_class.valid = 1
act_class.update =


type act_still.act_class
   name/still anim/still

type act_move.act_class
   name/move anim/move

act_move.valid A = 
| U = A.unit
| when U.xyz >< A.xyz: leave 0
| when (A.xyz-U.xyz).all{?abs<<1} and not U.can_move_to{A.xyz}: leave 0
| 1

act_move.update A = 

ActionClasses = t

type action.$class
   class
   unit // unit doing this action
   xyz // target x,y,z
   cycles // cycles remaining till the action would be done
   from // source cell of this action
   data

action.init ClassName XYZ =
| $xyz.init{XYZ}
| $class <= case ClassName still(act_still) move(act_move)
            Else | bad "bad action class `[ClassName]`"
| Me

action.valid = $class.valid{Me}

action.update =
| $class.update{Me}
| !$action_cycles - 1
| less $action.cycles
  //| when $unit.ordered and not $forced
  | $unit.action <= 0
  | $unit.from_xyz.init{0,0,0}
  | leave $unit.update

action.run =
| $cycles <= $unit.speed


export action