use util macros unit_flags

type cell_goal xyz/[0 0 0] serial

CellSize =

init_unit_module CS =
| CellSize <= CS

cell_goal.id = -1
cell_goal.type = \goal
cell_goal.fxyz = [$xyz.0*CellSize $xyz.1*CellSize $xyz.2*CellSize]
cell_goal.combat = 0
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
  hp // hit points
  kills //how many enemies this unit has killed
  flags //various flags (mostly genes)
  genes/[] //active genes
  mod //set by various genes to modify some contextual behavior
  steps //movement points remained this turn
  can_move //movement function
  aistate //how AI processes this unit
| $action <= $world.action{Me}
| $next_action <= $world.action{Me}
| $ordered <= $world.action{Me}

unit.enheap = Me
unit.unheap = Me

unit.as_text = "#unit{[$type] [$id]}"

unit.main = $world.main

unit.picked = $flags^get_bit{1}
unit.`=picked` State = $flags <= $flags^set_bit{1 State}

unit.hasted = $flags^get_bit{3}

unit.flyer = $flags^get_bit{5}
unit.`=flyer` State = $flags <= $flags^set_bit{5 State}

unit.swimmer = $flags^get_bit{10}
unit.amphibian = $flags^get_bit{11}
unit.invisible = $flags^get_bit{12}
unit.slowed = $flags^get_bit{14}

// this unit is a temporary mark (i.e. cursor); dont save it
unit.mark = $flags^get_bit{16}
unit.`=mark` State = $flags <= $flags^set_bit{16 State}

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
unit.health =
| CHP = $class.hp
| less CHP: leave 0
| UHP = $hp
| when UHP << 0: leave 0 
| R = UHP%CHP
| less R: R <= CHP
| R

land_can_move Me Src Dst =
| H = Dst.z-Src.z
| when H > 1 or H < -1: leave 0
| Dst.tile.empty and not (Dst-1).tile.liquid

amphibian_can_move Me Src Dst =
| H = Dst.z-Src.z
| when H > 1 or H < -1: leave 0
| Dst.tile.empty

swimmer_can_move Me Src Dst =
| H = Dst.z-Src.z
| when H > 1 or H < -1: leave 0
| Dst.tile.empty and (Dst-1).tile.type><water

flyer_can_move Me Src Dst =
| less Dst.tile.empty: leave 0
| SZ = Src.z
| DZ = Dst.z
| if SZ<DZ
  then | when DZ > $world.d-3: leave 0
       | times I DZ-SZ: less (Src+I).tile.empty: leave 0
  else times I SZ-DZ: less (Dst+I).tile.empty: leave 0
| 1

unit.update_move_method =
| $can_move <= if $flyer then &flyer_can_move
               else if $amphibian then &amphibian_can_move
               else if $swimmer then &swimmer_can_move
               else &land_can_move

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
| $flags <= 0
| $alpha <= 0
| $delta <= 0
| $kills <= 0
| $cooldown <= 0
| $from.init{0,0,-1}
| when $class.active
  | less $active
    | $world.active.push{Me}
  | $active <= 1
  | $steps <= $class.steps
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

unit.add_item Name Amount =
| less Amount: leave
| for E $genes: when E.name><Name:
  | E.amount-=Amount
  | when E.amount >> 0:
    | $strip_gene{Name}
    | leave
  | leave
| $add_gene{Name -Amount []}

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

unit.run_effect Name Params Target TargetXYZ =
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
| bad "[$type] is missing frame `[Index]` of `[$anim]` at angle [$facing]"

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

unit.order_at XYZ act/0 goal/0 =
| when XYZ >< self:
  | Goal <= Me
  | XYZ <= Me.xyz
| OAct = Act
| less Goal: Goal <= $world.block_at{XYZ}
| Act <= if Act.is_text then $main.params.acts.Act
         else if Act then Act
         else if Goal and $owner.is_enemy{Goal.owner} then
          $main.params.acts.attack
         else $main.params.acts.move
| when Act.ap><full and $steps<$class.steps:
  | $owner.notify{'The unit has already moved this turn.'}
  | leave
| when Act.ap.is_int and $steps < Act.ap:
  | $owner.notify{"Not enough action points ([Act.ap] required)"}
  | leave
| when Act.title><move: Goal <= 0 //otherwise it will hung in swap-loop
| when $owner.human and (Act.title><move or Act.title><attack):
  | Mark = "mark_[Act.title]"
  | Move = $world.cell{@XYZ}.units.keep{U=>U.type^~{mark_swap mark_move}><Mark}
  | less Move.size
    | $owner.notify{'Cant move there'}
    | leave
| when $owner.human and Act.tab><spell and Act.range>1 and Act.range<9000:
  | Move = $world.cell{@XYZ}.units.keep{?type><mark_cast}
  | less Move.size
    | $owner.notify{'Cant cast there'}
    | leave
| $unit_goal.xyz.init{XYZ}
| $goal <= if Goal then Goal else $unit_goal
| $goal_act <= Act
| $goal_serial <= $goal.serial
| $world.actors.set{[Me @$world.actors.get]}
| $set_path{$path_around_to{1000 $goal.xyz}}

in_range Me XYZ =
| less (XYZ.take{2}-$xyz.take{2}).abs<<$range.float: leave 0
| $world.seen_from{$xyz $goal.xyz}

unit.units_in_range Range = $world.units_in_range{Me.xyz Range}

retaliate Me Enemy Range =

heal_unit Me Amount =
| less $class.hp: leave
| $hp += min Amount $class.hp-$health

knockback Me Target =
| Dir = Target.xyz-$xyz
| less Dir.all{?abs<<1}: leave
| Dir.2 <= 0
| DXYZ = Target.xyz+Dir
| DC = $world.cell{@DXYZ}
| when DC.tile.empty and not DC.block: Target.move{DXYZ}

unit.assault Combat Target =
| Hit = 0
| Unavoid = 0
| Magic = 0
| Boost = 0
| Lifedrain = 0
| Mods = []
| case Combat
  [`.` Ms C]
    | Mods <= Combat^| @r [_ Ms M]=>[M @(case Ms [_ _ _] Ms^r Else [Ms])]
    | Combat <= Mods.head
    | Mods <= Mods.tail
  Else
    | when Combat.is_list: bad "Unknown combat modifier [Combat]"
| Damage = if Combat><user then $combat else Combat
| till Mods.end:
  | Mod = Mods^pop
  | case Mod
    unavoid
      | Unavoid <= 1
    magic
      | Unavoid <= 1
      | Magic <= 1
    lifedrain
      | Lifedrain <= 1
    Else
      | bad "Unknown combat modifier [Mod]"
| when $mod: | Damage += $mod; $mod <= 0
| less Magic:
  | $run_genes{attack}
  | when $mod: | Damage += $mod; $mod <= 0
| ImpactHit = $class.impact_hit
| when ImpactHit: $effect{ImpactHit Target Target.xyz}
| less Unavoid: Damage -= Target.armor
| Damage <= max 1 Damage
| when Lifedrain: heal_unit Me 1
| if Magic then Target.harm{Me Damage 1} else Target.harm{Me Damage}
//| when Knockback: knockback Me Target

unit.harm Attacker Damage @Magic =
| when $removed: leave
| less $alive: leave
| when Attacker and $leader><1 and $owner.id<>0:
  | when not $owner.human and Attacker.owner.id><0:
    | Attacker.harm{Me 1000}
    | leave //roaming neutral units wont harm AI leader
| when Damage << 0:
  | heal_unit Me -Damage
  | leave
| $run_genes{harm}
| when $mod><block: | $mod <= 0; leave
| Mg = not Magic.end //is magic harm?
| if Mg then $run_genes{magic_harm}
  else $run_genes{phys_harm}
| when $mod><block: | $mod <= 0; leave
| Damage <= max 1 Damage
| $hp -= Damage
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
