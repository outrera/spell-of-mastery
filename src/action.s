// unit controlling related stuff
use action_

Acts = t


dact idle.start | when $cycles >< -1: $cycles <= 4

// dirs requiring dummy to avoid overlapping unit with tiles
OverlapDirs = list [-1  1] [-1  0] [-1 -1] [ 0 -1]

Dirs = list [0 -1] [1 -1] [1 0] [1 1] [0 1] [-1 1] [-1 0] [-1 -1]

move_start Me =
| U = $unit
| X,Y,Z = $xyz - U.xyz
| U.movement_render_hack <= got OverlapDirs.locate{X,Y}
| $fromXY.init{U.xy}
| $fromXYZ.init{U.xyz}
| U.move{$xyz}
| U.facing <= Dirs.locate{X,Y}
| U.animate{move}
| $start_cycles <= $cycles
| when got!it U.sounds.move: U.main.sound{it.rand}

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
| U.movement_render_hack <= 0
| U.extort

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
| when got!it U.sounds.attack: U.main.sound{it.rand}
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
    | Damage = max 0 U.attack-Target.defense
    | Target.harm{U Damage}
    | U.animate{idle}
    | when Target.hits < Target.health:
      | $data <= 2
      | $cycles <= 0
      | leave
    | $data <= 1
    | $cycles <= 90000

dact attack.finish | move_finish Me

free_unit U = 
| when U.id >< U.world.waiting: U.world.waiting <= 0
| U.free

dact die.start
| U = $unit
| U.animate{death}
| less not U.hits or got U.sprite.anims.death:
  | free_unit U
  | $cycles <= 1000

dact die.finish | free_unit $unit


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
| !$target.owner.moves + 2
| $target.order.init{type/move at/$fromXYZ}

dact swap.update
| move_update Me

dact swap.finish
| move_finish Me
| !$target.owner.moves - 1

dact pentagram.valid
| T = $unit
| T.world.units_at{T.xyz}.all{?.empty >< 0}

dact pentagram.start
| $unit.animate{attack}
| $unit.main.sound{pentagram}

dact pentagram.finish
| U = $unit
| Pentagram = U.owner.pentagram
| when not Pentagram
  | Pentagram <= U.world.alloc_unit{$effect}
  | Pentagram.owner <= U.owner
  | U.owner.pentagram <= Pentagram
| Pentagram.move{$xyz}


dact disband.start
| $cycles <= 4
| $unit.main.show_message
  {'Disband Unit?' buttons/[yes,'Yes' no,'No']
   'Are you sure this unit should be disbanded?'}

dact disband.finish
| when $unit.main.dialog_result><yes
  | $unit.main.sound{cancel}
  | free_unit $unit

dact summon.valid
| $unit.world.units_at{$xyz}.all{?empty}

dact summon.start
| U = $unit
| U.animate{attack}
| U.main.sound{summon}
| Leader = U.owner.leader
| when Leader
  | Leader.animate{attack}
  | Leader.face{$xyz}
| U.world.effect{$xyz teleport}

dact summon.finish
| S = $unit.world.alloc_unit{$effect}
| S.owner <= $unit.owner
| S.attacker <= 1 // mark it available for attack
| S.move{$xyz}
| S.world.update_pick{[S]}
| !S.owner.power + S.income


apply_effect U Affects Effect Target TargetXYZ =
| Effect = Effect.group{2}
| case Effect.find{?0><impact} _,Impact: U.world.effect{TargetXYZ Impact}
| case Effect.find{?0><hit_sound} _,Sound: U.main.sound{Sound}
| when Affects >< unit: case Effect.find{?0><harm} _,Damage:
  | Target.harm{U Damage}

dact cast.valid | if $affects >< unit then $target else 1

dact cast.start
| U = $unit
| U.animate{attack}
| U.face{$xyz}
| apply_effect U $affects $effect $target $xyz


dact spell_of_mastery.start
| U = $unit
| U.animate{attack}
| U.main.sound{summon}
| U.world.effect{U.xyz teleport}

dact spell_of_mastery.finish
| U = $unit
| U.world.params.winner <= U.owner.id
| U.world.params.victory_type <= 'Victory by casting the Spell of Mastery'


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
   effect
   range
   path
   act_init/&default_init
   act_valid/&default_valid
   act_start/&default_start
   act_update/&default_update
   act_finish/&default_finish

action.as_text = "#action{[$type] [$priority] [$target]}"

action.init type/idle at/0 affects/0 target/0
            cost/0 effect/0 path/0 speed/-1 range/No =
| when Affects >< self: Target <= $unit
| when Affects >< pentagram: Target <= $unit.owner.pentagram
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
| $cycles <= -1
| $cost <= Cost
| $speed <= Speed
| $effect <= Effect
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


export action