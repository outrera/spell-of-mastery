// unit controlling related stuff
use action_

Acts = t


dact idle.start
| U = $unit
| when U.anim >< move: U.animate{idle}

Dirs = list [0 -1] [1 -1] [1 0] [1 1] [0 1] [-1 1] [-1 0] [-1 -1]

// Following movement code handles movement between cells
move_start Me =
| U = $unit
| when $xyz><U.xyz:
  | $toXYZ.init{U.fxyz}
  | $cycles <= 0
  | leave
| X,Y,Z = $xyz - U.xyz
| $fromXYZ.init{U.fxyz}
| U.move{$xyz}
| $toXYZ.init{U.fxyz}
| U.fxyz.init{$fromXYZ}
| U.facing <= Dirs.locate{X,Y}
| when U.anim<>move: U.animate{move}
| $cycles <= U.speed
| when X >< -Y: $cycles <= max 1 $cycles*3/2
| $start_cycles <= $cycles
| Effect = U.class.onMove
| when Effect: U.effect{Effect U U.xyz}

move_update Me =
| U = $unit
| V = $toXYZ-$fromXYZ
| U.fxyz.init{$fromXYZ + V*($start_cycles-$cycles)/$start_cycles}

move_finish Me =
| U = $unit
| U.fxyz.init{$toXYZ}
| U.on_entry

dact move.valid
| U = $unit
| U.world.no_block_at{$xyz} and U.can_move{}{U U.cell $xyz.cell}

dact move.start
| move_start Me

dact move.update | move_update Me
dact move.finish | move_finish Me


dact missile.start
| U = $unit
| $fromXYZ.init{U.fxyz}
| U.move{$xyz}
| $toXYZ.init{U.fxyz}
| U.fxyz.init{$fromXYZ}
| less $cycles: $cycles <= 1
| $start_cycles <= $cycles

dact missile.update
| U = $unit
| V = $toXYZ-$fromXYZ
| U.fxyz.init{$fromXYZ + V*($start_cycles-$cycles)/$start_cycles}

dact missile.finish
| U = $unit
| _,UId,USerial,Es = U.get{missile}.0
| Source = U.world.units.UId
| less Source.serial >< USerial: Source <= $world.nil
| Source.effect{Es $target $xyz}
| U.free

player_lost_leader Me Leader =
| Leaders = []
| RemainingUnits = []
| for U $world.active.list: when U.id <> Leader.id:
  | when U.leader><1: push U Leaders
  | when U.owner.id >< $id: push U RemainingUnits
| case Leaders [L@Ls]: when Ls.all{?owner.id><L.owner.id}:
  | $world.params.winner <= L.owner.id
  | $world.params.victory_type <= 'Victory by defeating other leaders.'
| when Leader.owner.human: less Leaders.any{?owner.human}:
  | $world.params.winner <= 0
  | $world.params.victory_type <= 'Defeat by losing your leader.'
| $world.notify{"[$name] was defeated."}
| less RemainingUnits.any{?leader><1}: for U RemainingUnits: U.free

dact die.start
| U = $unit
| U.drop_all
| U.animate{death}
| less not (U.class.hp-U.hp)>0 or got U.sprite.anims.death:
  | U.free
  | $cycles <= 1000

dact die.finish
| U = $unit
| when U.leader><1 and U.hp << 0: player_lost_leader U.owner U
| U.free


dact swap.valid
| T = $target
| less $target and not $target.removed: leave 0
| U = $unit
| U.owner.id >< T.owner.id and T.idle

dact swap.start
| U = $unit
| move_start Me
| T = $target
| O = T.order
| less T.path.end: T.set_path{[T.cell @T.path.list]}
| O.init{move U.from}
| O.priority <= 100

dact swap.update | move_update Me

dact swap.finish | move_finish Me


dact ascend.start | when $unit.anim<>move: $unit.animate{move}

ascend_update Me GoalZ =
| FDst = $fxyz+[0 0 $ascendSpeed]
| when FDst.2 < (GoalZ*$world.c)
  | $fine_move{FDst}
  | leave 1
| $move{[$xyz.0 $xyz.1 GoalZ]}
| 0
dact ascend.update | $cycles <= ascend_update $unit $xyz.2

dact fastmove.start
| $unit.move{$xyz}
| $unit.on_entry

custom_init Me =
custom_valid Me =
| invalid Error =
  | $unit.owner.notify{Error}
  | $unit.main.sound{illegal}
| $act.validate{$unit $xyz $target &invalid}


custom_start Me =
| U = $unit
| U.animate{attack}
| U.face{$xyz}
| when $before: U.effect{$before $target $xyz}
custom_update Me =
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
   toXYZ/[0 0 0]
   fromXYZ/[0 0 0]
   start_cycles
   range
   act_init/&default_init
   act_valid/&default_valid
   act_start/&default_start
   act_update/&default_update
   act_finish/&default_finish

world.action Unit = action Unit

action.main = $unit.main

action.cost =
| Cost = $act.cost
| when $target and $act.check.will: Cost += $target.class.will
| Cost
action.check = $act.check
action.before = $act.before
action.impact =
| less $act: leave //in case it is just an animation
| Impact = $act.impact
| when got Impact:
  | Target = $target
  | if Target then $unit.effect{Impact Target Target.xyz}
    else $unit.effect{Impact 0 $xyz}

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
| $act <= if Act.is_text then $main.params.acts.$type else Act
| less got $act: bad "unknown action type [$type]"
| $range <= $act.range
| $cycles <= $act.speed
| $priority <= $act.priority
| if got A then
    | $act_init <= A.init
    | $act_valid <= A.valid
    | $act_start <= A.start
    | $act_update <= A.update
    | $act_finish <= A.finish
  else
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
| $cycles--

action.finish =
| $act_finish{}{Me}
