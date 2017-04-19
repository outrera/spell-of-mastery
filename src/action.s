// unit controlling related stuff
use action_

Acts = t


dact idle.start
| U = $unit
| less U.anim >< idle: U.animate{idle}

Dirs = list [0 -1] [1 -1] [1 0] [1 1] [0 1] [-1 1] [-1 0] [-1 -1]

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
| when U.slowed: $cycles <= U.speed*2
| when U.hasted: $cycles <= max 2 U.speed/2
| when X >< -Y: $cycles <= max 1 $cycles*3/2
| $start_cycles <= $cycles
| Effect = U.class.moves
| when Effect: U.effect{Effect U U.xyz}

move_update Me =
| U = $unit
| V = $toXYZ-$fromXYZ
| U.fxyz.init{$fromXYZ + V*($start_cycles-$cycles)/$start_cycles}

move_finish Me =
| U = $unit
| U.fxyz.init{$toXYZ}

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
| _,UId,USerial,Es = U.get_effect_value{missile}.0
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

respawn_leader Me XYZ =
| Block = $world.block_at{XYZ}
| when Block and $owner.is_enemy{Block.owner}: leave 0
| when $owner.mana << 0: leave 0
| Cost = $main.params.world.death_cost
| $owner.mana -= Cost
| $owner.notify{"death cost you [Cost] mana"}
| when got $owner.params.spell_of_mastery:
  | $owner.params.spell_of_mastery <= No
  | $owner.notify{"Your Spell of Mastery was broken!"}
| S = Me
| S.strip_effect{poison}
| S.strip_effect{flight}
| S.backtrack <= 0
| S.reset_goal
| S.reset_followers
| S.hp <= S.class.hp
| S.nonguard <= 0
| S.alpha <= 255
| S.delta <= -25
| $world.effect{$xyz teleport}
| S.move{XYZ}
| when $owner.human:
  | S.main.ui.view.center_at{XYZ}
| $world.effect{XYZ teleport}
| 1

dact die.start
| U = $unit
| U.drop_all
| U.animate{death}
| less not (U.class.hp-U.hp)>0 or got U.sprite.anims.death:
  | U.free
  | $cycles <= 1000

dact die.finish
| U = $unit
| when U.leader><1 and U.hp << 0:
  | P = U.owner.pentagram
  | when P and respawn_leader U P.xyz: leave
  | player_lost_leader U.owner U
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
//| less T.goal: less U.goal and U.goal.xyz >< T.xyz:
//  | less T.has{btrack}:
//    | T.backtrack <= T.xyz

dact swap.update | move_update Me

dact swap.finish | move_finish Me


dact teleport.start | $unit.move{$xyz}

custom_init Me =
custom_valid Me =
| Affects = $affects
| when Affects.is_list and Affects.0.is_list:
  | Ms = Affects.0
  | Affects <= Affects.1
  | for Mod Ms
    | if Mod >< outdoor then
        | less $unit.world.outdoor{$xyz}: leave 0
      else if Mod >< non_leader then
        | when $target and $target.leader><1: leave 0
      else
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
     | less $unit.world.block_at{$xyz}: leave 1
    else if A >< ally_block then
     | Block = $unit.world.block_at{$xyz}
     | when Block and not $unit.owner.is_enemy{Block.owner}: leave 1
    else if A >< area then leave 1
    else $unit.owner.notify{"custom.valid: bad affects specifier - [A]"}
| 0

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

action.cost = $act.cost
action.affects = $act.affects
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
