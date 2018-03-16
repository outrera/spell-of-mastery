use util macros unit_flags

type cell_goal xyz/[0 0 0] serial

CellSize =

init_unit_module CS =
| CellSize <= CS

cell_goal.id = -1
cell_goal.type = \goal
cell_goal.fxyz = [$xyz.0*CellSize $xyz.1*CellSize $xyz.2*CellSize]
cell_goal.atk = 0
cell_goal.leader = 0
cell_goal.removed = 0
cell_goal.alive = 1
cell_goal.empty = 1
cell_goal.harm Attacker Damage =

type unit.$class{Id World}
  world/World //FIXME: get rid of it, we wont be using several world
  id/Id //id could be reused, when this unit is freed
  serial //seral cant be reused, when this unit is freed
  class //data shared between all units of that class
  owner // player controlling this unit
  fxyz/[0 0 0] // fine X,Y,Z
  xyz/[0 0 -1] // world cell X,Y,Z
  zhack // used to make unit appear standing on platform
  cell/0 //cell this unit resides in
  floor/0 // ground cell under this unit
  from/[0 0 0] //where this unit moved from
  facing // direction this unit faces
  velocity/[0.0 0.0 0.0] //when unit falls down or gets kicked
  sprite //sprite used by this unit
  colors //colors for the sprite
  alpha //how transparent is the sprite of this unit
  delta //change of transparency per cycle
  anim // animation id
  anim_step // frame index inside of current animation
  anim_seq // current animation sequence
  anim_wait // cycles till the next animation frame
  frame //gfx of current animation frame
  mirror // true, if drawing code should mirror the sprite
  action // currently executing action
  next_action // action to be taken after the current one
  ordered // what owner of this unit has ordered
  cooldown //cooldown before the unit can attack again
  handled //unit was already processed
  active // true if this unit resides in the list of active units
  path/[] // path to goal
  goal //target of this unit
  goal_serial //in case goal gets killed
  goal_act //what to do with the goal
  host //what unit hosts this sprite
  host_serial //when host dies, its serial changes
  unit_goal/cell_goal{}
  mov //movement points remained this turn
  hp // hit points
  def //defense points remained
  flags //various flags (mostly genes)
  genes/[] //active genes
  mod //set by various genes to modify some contextual behavior
  can_move //movement function
  aistate //how AI processes this unit
| $action <= $world.action{Me}
| $next_action <= $world.action{Me}
| $ordered <= $world.action{Me}

unit.enheap = Me
unit.unheap = Me

unit.as_text = "#unit{[$type] [$id]}"

unit.main = $world.main

Facings = [[-1 -1] [0 -1] [1 -1] [1 0] [1 1] [0 1] [-1 1] [-1 0]]
unit.direction = Facings.$facing

unit.picked = $flags^get_bit{1}
unit.`=picked` State = $flags <= $flags^set_bit{1 State}

unit.engaged = $flags^get_bit{2}
unit.`=engaged` State = $flags <= $flags^set_bit{2 State}

unit.shelled = $flags^get_bit{4}
unit.`=shelled` State = $flags <= $flags^set_bit{4 State}

unit.flyer = $flags^get_bit{5}
unit.`=flyer` State = $flags <= $flags^set_bit{5 State}

unit.climber = $flags^get_bit{9}
unit.swimmer = $flags^get_bit{10}
unit.amphibian = $flags^get_bit{11}
unit.invisible = $flags^get_bit{12}
unit.blessed = $flags^get_bit{13}
unit.cursed = $flags^get_bit{14}
unit.afraid = $flags^get_bit{15}

unit.can_stand_on_water = $flyer or $swimmer or $amphibian

// this unit is a temporary mark (i.e. cursor); dont save it
unit.mark = $flags^get_bit{16}
unit.`=mark` State = $flags <= $flags^set_bit{16 State}

unit.resting = $flags^get_bit{17}
unit.`=resting` State = $flags <= $flags^set_bit{17 State}

unit.resisting = $flags^get_bit{18}
unit.`=resisting` State = $flags <= $flags^set_bit{18 State}

//how many other units this unit has killed
unit.kills = $get{kills}^~{No 0}
unit.`=kills` Value = $set{kills Value}

//how much that unit harmed other units
unit.sinned = $get{sinned}^~{No 0}
unit.`=sinned` Value = $set{sinned Value}

unit.`=backtrack` XYZ =
| less XYZ:
  | $strip_gene{btrack}
  | leave
| when $has{btrack}: leave
| $add_gene{btrack 0 XYZ}

unit.child Type =
| $world.units_get{$xyz}
        .find{(?host and ?type><Type and ?host.serial><$serial)}

unit.is_enemy Target = $owner.is_enemy{Target.owner} and Target.health

unit.size =
| S = $sprite.size
| if $height then S else [S.0 S.1 0]

unit.alive = $hp > 0
unit.health = $hp

unit.placeable_at Dst =
| less Dst.empty: leave 0
| when $flyer: leave 1
| when $amphibian: leave 1
| when $swimmer: leave (Dst-1).tile.type><water
| leave: not (Dst-1).tile.liquid

//FIXME: when serials get exhausted, compress serial space
unit.init Class =
| $class <= Class
| $sprite <= if $show or $world.editor
             then $default_sprite
             else $world.nil.sprite
| $facing <= 3
| $mirror <= 0
| $serial <= $world.serial
| $world.serial++
| $animate{idle}
| $hp <= $class.hp
| $def <= $class.def
| $flags <= 0
| $alpha <= 0
| $delta <= 0
| $cooldown <= 0
| $from.init{0,0,-1}
| when $class.active
  | less $active
    | $world.active.push{Me}
  | $active <= 1
  | $mov <= $class.mov
  | $handled <= 0
  | $aistate <= \initial
  | $ordered.type <= 0
  | $next_action.type <= 0
  | $action.init{idle 0,0,0}
  | $velocity.init{[0.0 0.0 0.0]}
  | $action.cycles <= 0
  | $unit_goal.serial <= $serial
  | $add_genes{$inborn}
  | $update_move_method

unit.morph Class =
| $owner.lost_unit{Me}
| $hp <= Class.hp + $hp - $class.hp
| $class <= Class
| $sprite <= if $show or $world.editor
             then $default_sprite
             else $world.nil.sprite
| $animate{idle}
| $owner.got_unit{Me}

unit.find_dna Name = $main.params.gene.Name

unit.add_gene Name Duration Params =
| Effect = $find_dna{Name}
| when no Effect: Effect <= [[on static]]
| On = Effect.0
| when On.0 <> `on`:
  | $world.notify{"unit.add_gene: missing `on{When}` for effect [Name]"}
  | leave
| Flag = getUnitFlagsTable{}.Name
| when got Flag:
  | when $flags^get_bit{Flag}: leave //already got this gene
  | when Name><invisible: $alpha <= 127
  | $flags <= $flags^set_bit{Flag 1}
  | $update_move_method
| When = On.1
| $genes <= $genes.cons{$world.new_gene{When Name Duration Params}}

unit.add_genes Genes =
| for E Genes: case E
    [`{}` Head @Args]
      | case Head
         [`.` Name Life] | $add_gene{Name Life Args}
         Name | $add_gene{Name 0 Args}
    Else | $add_gene{E 0 []}

unit.has Name = got $genes.find{?name><Name}

unit.cooldown_of ActName =
| E = $genes.find{E => E.name><cool and E.params.0><ActName}
| if got E then [E.params.1 E.params.2] else 0

unit.gene_param Name =
| E = $genes.find{?name><Name}
| if got E then E.params.unheap else 0

unit.strip_gene What =
| Check = if What.is_fn then What else E => E.name><What
| FreeEs =
| Es =
| FreeEs <= $genes.keep{Check}
| when FreeEs.end: leave
| Es <= $genes.skip{Check}
| for E FreeEs:
  | Name = E.name
  | Flag = getUnitFlagsTable{}.Name
  | when got Flag:
    | when Name><invisible: $alpha <= 0
    | $flags <= $flags^set_bit{Flag 0}
    | $update_move_method
  | $world.free_gene{E}
| $genes.heapfree
| $genes <= Es.enheap

unit.set Name Value =
| for E $genes: when E.name><Name:
  | E.params <= Value
  | leave
| $add_gene{Name 0 Value}

unit.get Name =
| for E $genes: when E.name><Name: leave E.params
| No

unit.set_item Name Amount =
| for E $genes: when E.name><Name:
  | E.amount <= -Amount
  | when E.amount >> 0: $strip_gene{Name}
  | leave
| $add_gene{Name -Amount []}

unit.add_item Name Amount =  $set_item{Name $get_item{Name}+Amount}

unit.get_item Name =
| for E $genes: when E.name><Name: leave -E.amount
| 0

unit.items =
| Items = []
| for E $genes: when E.amount<0: push [E.name -E.amount] Items
| Items

unit.drop_item ItemType Amount =
| A = min $get_item{ItemType} Amount
| $add_item{ItemType -A}
| $cell.add_item{ItemType A}

unit.drop_all =
| for K,V $items: $drop_item{K V}

unit.acts =
| Param = $main.params
| ItemDefs = Param.iacts
| ItemActs = []
| for Name,Count $items:
  | Item = ItemDefs.Name
  | when got Item: for ActName Item: push Param.acts.ActName ItemActs
| [@$class.acts @ItemActs]

unit.run_genes Selector target/0 xyz/0 =
| less Target: Target <= Me
| less Xyz: Xyz <= Target.xyz
| Sel = if Selector.is_text then X => X.when><Selector else Selector
| Es = []
| for E $genes: when Sel E:
  | DNA = $find_dna{E.name}
  | push DNA Es //cuz invoking it right here may clobber $genes
| for Effect Es: $effect{Effect Target Xyz}

unit.run_gene Name Params Target TargetXYZ =
| $effect{$find_dna{Name} Target TargetXYZ}

unit.change_owner NewOwner =
| FXYZ = 0
| less $removed:
  | FXYZ <= $fxyz
  | $remove
| $owner.lost_unit{Me}
| $owner <= NewOwner
| when FXYZ: $fine_move{FXYZ}
| NewOwner.got_unit{Me}

unit.idle = not $ordered.type and
           [$action $next_action].all{?type^~{0 idle} >< idle}

//FIXME: move these into sprite loading code
AngleReplacements = [6,1 6,1 3,0 -1,0 3,1 3,1 3,1 6,0]

missing_frame Me =
| Index = $anim_seq.$anim_step.0
| S = $sprite
| bad "sprite [S.bank]_[S.name] is missing frame `[Index]` of `[$anim]` at angle [$facing]"

unit.pick_facing F =
| $facing <= F
| AS = $anim_seq
| FrameIndex = AS.($anim_step%AS.size).0
| Frame = $sprite.frames.FrameIndex
| less Frame.is_list
  | $frame <= Frame
  | when no $frame: missing_frame Me
  | when $facing <> 3: $mirror <= 1
  | leave
| $mirror <= 0
| Angle = $facing
| till Frame.Angle
  | $mirror <= AngleReplacements.Angle.1
  | Angle <= AngleReplacements.Angle.0
| $frame <= Frame.Angle
| when no $frame: missing_frame Me

unit.animate Anim =
| $anim <= Anim
| $anim_seq <= $sprite.anims.$anim
| when no $anim_seq:
  | $anim_seq <= $sprite.anims.idle
  | less got $anim_seq: bad "unit [$type] is missing `idle` anim"
| $anim_step <= 0
| $pick_facing{$facing}
| $anim_wait <= $anim_seq.$anim_step.1

unit.free =
| when $picked: $owner.picked <= $owner.picked.skip{?id><$id}
| when $owner: $owner.lost_unit{Me}
| when $leader><1:
  | $owner.leader <= 0
| when $active: $active <= 2 //request removal from active list
| less $path.end: $set_path{[]}
| $goal <= 0
| $host <= 0
| $colors <= 0
| for E $genes: $world.free_gene{E}
| $genes.heapfree
| $genes <= []
| $world.free_unit{Me}

unit.reset_goal =
| less $path.end: $set_path{[]}
| $goal <= 0

//a faster solution would be keeping the linked list of all targeters
unit.reset_followers =
| for U $world.active: when U.goal and U.goal.id><$id:
  | U.reset_goal

unit.removed = $xyz.2 >< -1

unit.set_path Path =
| P = Path.enheap
| $path.heapfree
| $path <= P

unit.order = $ordered

unit.order_act Act target/0 =
| less Target: Target <= Me
| $order.init{Act Target}
| $world.actors.set{[Me @$world.actors.get]}

// order taking over any other order
unit.forced_order Act Target =
| O = $order.init{Act Target}
| O.priority <= 1000
| O.cycles <= 0
| O

unit.die =
| Effect = $class.death
| when Effect: $effect{Effect Me $xyz}
| $forced_order{die 0}
| $order.priority <= 2000
| $cooldown <= 0

in_range Me XYZ =
| less XYZ.mdist{$xyz}<<$range: leave 0
| $world.seen_from{$xyz $goal.xyz}

unit.units_in_range Range = $world.units_in_range{Me.xyz Range}

unit.nearby_enemies_at XYZ =
| Es = []
| for D Dirs43:
  | Us = $world.cellp{XYZ+D}.floor.units
  | Us.skip{?empty}.keep{?is_enemy{Me}}.keep{?alive}{E=>push E Es} //.keep{E=>(E.xyz.2-XYZ.2)<<1}
| Es

unit.threatened_at XYZ =
| for E $nearby_enemies_at{XYZ}:
  | when not E.afraid and $can_attack{E.cell $world.cellp{XYZ}}: leave 1
| 0

unit.threatened = $threatened_at{$xyz}

retaliate Me Enemy Range =

heal_unit Me Amount =
| less $class.hp: leave
| $hp += min Amount $class.hp-$health

unit.counter_attack Attacker =
| less $owner.id <> $world.player and $mov>0 and $atk: leave
| when $afraid or no $enemies_in_range.find{?id><Attacker.id}: leave
| less $can_attack{$cell Attacker.cell}: leave
| $order_at{Attacker.xyz}

//action goes through target`s defense
unit.assault Target =
| Def = Target.def
| when $invisible: Def <= min{2 Def}
| Hit = min{Def $mov}
| $mov -= Hit
| Def -= Hit
| when Def > 0:
  | Target.def <= Def-1
  | Target.counter_attack{Me}
  | leave 0
| Target.def <= Target.class.def
| leave 1

unit.hit Damage Target =
| Damage = if Damage><user then $atk else Damage
| when Target.cursed and $blessed: Damage += (Damage*100)/100
| $run_genes{attack}
| ImpactHit = $class.impact_hit
| when ImpactHit: $effect{ImpactHit Target Target.xyz}
| Target.harm{Me Damage}

unit.harm Attacker Damage =
| when $removed or not $alive: leave //should never happen
| when Damage << 0:
  | heal_unit Me -Damage
  | leave
| $resting <= 0
| Damage <= max 1 Damage
| $hp -= Damage
| when Attacker: Attacker.sinned += Damage
| less $owner.human: $owner.ai.harm{Attacker Me}
| when $hp > 0:
  | Effect = $class.hit
  | when Effect: $effect{Effect Me $xyz}
  | when $anim><idle or $anim><move: $animate{hit}
  | when Attacker and $owner.is_enemy{Attacker.owner}:
    | retaliate Me Attacker 5
  | leave
| when Attacker:
  | AO = Attacker.owner
  | when $owner.id <> AO.id: AO.lore += $tier
  | $owner.params.lossage += $tier
  | Attacker.kills++
| $die
| $action.cycles <= 1

//called when unit enters cell ingame, not in editor or game-init
unit.on_entry =
| for U $cell.units: U.run_genes{entry}

unit_pickup_items Me =
| for U $cell.units: when U.item.is_list: U.effect{U.item Me $xyz}

unit.fine_move FXYZ =
| C = $world.c
| XYZ = [FXYZ.0/C FXYZ.1/C FXYZ.2/C]
| $from.init{$xyz}
| $remove
| $xyz.init{XYZ}
| C = $world.c
| $fxyz.init{FXYZ}
| $zhack <= 0
| when $ai >< unit:
  | Platform = $world.units_get{$xyz}.find{?platform}
  | when got Platform: $zhack <= -Platform.platform
| RUs = []
| when $platform:
  | RUs <= $world.units_get{$xyz}{[? ?fxyz]}
  | RUs{?0.remove}
| $world.place_unit{Me}
| RUs{U,F=>U.fine_move{F}}
| $floor <= $cell.floor
| $environment_updated
| when $ai >< unit: unit_pickup_items Me
| Me

unit.move XYZ =
| C = $world.c
| $fine_move{[XYZ.0*C XYZ.1*C XYZ.2*C]}
| when $class.active: $run_genes{move}
| Me

unit.remove =
| when $removed: leave
| $world.remove_unit{Me}
| $xyz.2 <= -1

unit.environment_updated =

unit.face XYZ =
| XY = (XYZ-$xyz).take{2}{?sign}
| less XY >< [0 0]: $facing <= Dirs.locate{(XYZ-$xyz).take{2}{?sign}}

unit.sound SoundName =
| when not $id or (not $removed and $world.human.explored{$xyz}>1):
  | CXYZ = $main.ui.view.center
  | V = 1.0 / | max 1.0 (CXYZ - $xyz).abs*0.5
  | when V>0.01: $main.sound{SoundName volume/V}

export unit init_unit_module
