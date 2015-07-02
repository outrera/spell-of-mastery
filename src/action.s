// unit controlling related stuff
use action_

Acts = t


dact idle.start | when A.cycles >< -1: A.cycles <= 4

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
| U.facing <= Dirs.locate{X,Y}
| U.animate{move}
| A.start_cycles <= A.cycles
| when got!it U.sounds.move: U.main.sound{it.rand}

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
| U.movement_render_hack <= 0
| U.extort

dact move.valid
| U = A.unit
| U.world.no_block_at{A.xyz} and U.can_move{U.xyz A.xyz}

dact move.start
| U = A.unit
| when A.cycles >< -1: A.cycles <=  U.sprite.speed
| move_start A
| X,Y,Z = U.xyz
| less U.seen
  | A.cycles <= 0
  | move_finish A

dact move.update | move_update A
dact move.finish | move_finish A

dact attack.valid
| T = A.target
| when T.is_list or T.removed or T.empty or not T.health: leave 0
| U = A.unit
//| when U.skirmisher: leave (T.xyz - U.xyz).all{?.abs<<1}
| if U.ranged then 1 else U.can_move{U.xyz T.xyz}

dact attack.init | A.data <= 0

dact attack.start
| U = A.unit
| U.face{A.target.xyz}
| A.cycles <= max 1 U.sprite.anim_speed{attack}
| U.animate{attack}
| when got!it U.sounds.attack: U.main.sound{it.rand}
dact attack.update
| U = A.unit
| when A.cycles > 9000 // if target is dying, wait till it is dead
  | when U.world.waiting: leave
  | A.target <= 0
  | when A.unit.ranged:
    | A.cycles <= 1
    | leave
  | less A.unit.ranged: 
    | A.cycles <= max 1 U.sprite.speed/2
    | move_start A
  | leave
| when A.data > 0: move_update A
| when A.cycles >< 1 and A.data < 2:
  | when A.data >< 1:
    | leave
    | less A.unit.ranged: leave
    | move_finish A
    | A.xyz.init{A.fromXYZ}
    | A.cycles <= max 1 A.unit.sprite.speed*2/3
    | move_start A
    | A.data <= 2
  | when A.data >< 0:
    | Target = A.target
    | U.world.effect{Target.xyz blood}
    | Damage = max 0 U.attack-Target.defense
    | when Target.harm{U Damage}
    | U.animate{idle}
    | when Target.hits < Target.health:
      | A.data <= 2
      | A.cycles <= 0
      | leave
    | A.data <= 1
    | A.cycles <= 90000

dact attack.finish | move_finish A

free_unit U = 
| when U.id >< U.world.waiting: U.world.waiting <= 0
| U.free

dact die.start
| U = A.unit
| U.animate{death}
| less not U.hits or got U.sprite.anims.death:
  | free_unit U
  | A.cycles <= 1000

dact die.finish | free_unit A.unit


dact swap.valid
| T = A.target
| less A.target and not A.target.removed: leave 0
| U = A.unit
| Turn = U.world.turn
| U.owner.id >< T.owner.id and U.moved < Turn and T.moved < Turn


dact swap.start
| U = A.unit
| A.cycles <= max 1 U.sprite.speed
| move_start A
| !A.target.owner.moves + 2
| A.target.order.init{type/move at/A.fromXYZ}

dact swap.update
| move_update A

dact swap.finish
| move_finish A
| !A.target.owner.moves - 1

dact pentagram.valid
| T = A.unit
| T.world.units_at{T.xyz}.all{?.empty >< 0}

dact pentagram.start
| A.unit.animate{attack}
| A.unit.main.sound{pentagram}

dact pentagram.finish
| U = A.unit
| Pentagram = U.owner.pentagram
| when not Pentagram
  | Pentagram <= U.world.alloc_unit{A.effect}
  | Pentagram.owner <= U.owner
  | U.owner.pentagram <= Pentagram
| Pentagram.move{A.xyz}


dact disband.start
| A.cycles <= 4
| A.unit.main.show_message
  {'Disband Unit?' buttons/[yes,'Yes' no,'No']
   'Are you sure this unit should be disbanded?'}

dact disband.finish
| when A.unit.main.dialog_result><yes
  | A.unit.main.sound{cancel}
  | free_unit A.unit

dact summon.valid
| T = A.target
| less A.target and not A.target.removed: leave 0
| T.world.units_at{T.xyz}.all{?empty}

dact summon.start
| U = A.unit
| U.animate{attack}
| U.main.sound{summon}
| Leader = U.owner.leader
| when Leader
  | Leader.animate{attack}
  | Leader.face{U.xyz}
| U.world.effect{A.target.xyz teleport}

dact summon.finish
| S = A.unit.world.alloc_unit{A.effect}
| S.owner <= A.unit.owner
| S.attacker <= 1 // mark it available for attack
| S.move{A.target.xyz}
| S.world.update_pick{[S]}
| !S.owner.power + S.income


dact spell_of_mastery.start
| U = A.unit
| U.animate{attack}
| U.main.sound{summon}
| U.world.effect{U.xyz teleport}

dact spell_of_mastery.finish
| U = A.unit
| U.world.params.winner <= U.owner.id
| U.world.params.victory_type <= 'Victory by casting the Spell of Mastery'


default_init A =
default_valid A = 1
default_start A = A.cycles <= A.unit.sprite.speed
default_update A =
default_finish A =

for Name,Act Acts
| have Act.init &default_init
| have Act.valid &default_valid
| have Act.start &default_start
| have Act.update &default_update
| have Act.finish &default_finish

type action{unit}
   type
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
   path
   act_init/&default_init
   act_valid/&default_valid
   act_start/&default_start
   act_update/&default_update
   act_finish/&default_finish

action.as_text = "#action{[$type] [$priority] [$target]}"

action.init type/idle at/self target/0 cost/0 effect/0 path/0 speed/-1 =
| when Target >< self: Target <= $unit
| when Target >< pentagram: Target <= $unit.owner.pentagram
| when Target: At <= Target.xyz
| $xyz.init{At}
| $target <= Target
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

action.valid = $act_valid{}{Me}

action.start =
| $act_start{}{Me}

action.update =
| $act_update{}{Me}
| !$cycles - 1

action.finish =
| $act_finish{}{Me}
| when $path: $path^uncons{path}{?free}


export action