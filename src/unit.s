use util macros unit_flags fxn

CellSize =

init_unit_module CS =
| CellSize <= CS

type unit.$class{Id Site}
  site/Site //FIXME: get rid of it, we wont be using several site
  id/Id //id could be reused, when this unit is freed
  serial //seral cant be reused, when this unit is freed
  class //data shared between all units of that class
  owner // player controlling this unit
  fxyz/[0 0 0] // fine X,Y,Z
  xyz/[0 0 -1] // site cell X,Y,Z
  zhack // accomotates for fheight of underlaying terrain
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
  delay //delay in cycles(!) before the unit can act again
  handled //unit was already processed
  active // true if this unit resides in the list of active units
  path/[] // path to goal
  goal //target of this unit
  goal_serial //in case goal gets killed
  goal_act //what to do with the goal
  host //what unit hosts this sprite
  host_serial //when host dies, its serial changes
  fatigue //fatigued unit will have less moves
  mov //movement points remained this turn
  hp // hit points
  def //defense points remained
  height
  flags //various flags (mostly genes)
  genes/[] //active genes
  can_move //movement function
  aistate //how AI processes this unit
  blitem //draw list structure associated with this unit.
| $action <= $site.action{Me}
| $next_action <= $site.action{Me}
| $ordered <= $site.action{Me}

unit.enheap = Me
unit.unheap = Me

unit.as_text = "#unit{[$type] [$id]}"

unit.main = $site.main

unit.ai = $class.ai

unit.picked = $flags.bit{1}
unit.`=picked` State = $flags <= $flags.bitSet{1 State}

unit.engaged = $flags.bit{2}
unit.`=engaged` State = $flags <= $flags.bitSet{2 State}

unit.leader = $flags.bit{3}

unit.shelled = $flags.bit{4}
unit.`=shelled` State = $flags <= $flags.bitSet{4 State}

unit.flyer = $flags.bit{5}
unit.`=flyer` State = $flags <= $flags.bitSet{5 State}

unit.heavy = $flags.bit{6}
unit.`=heavy` State = $flags <= $flags.bitSet{6 State}

unit.empty = fxn $height><0

unit.climber = $flags.bit{9}
unit.swimmer = $flags.bit{10}
unit.amphibian = $flags.bit{11}
unit.invisible = $flags.bit{12}
unit.blessed = $flags.bit{13}
unit.`=blessed` State = $flags <= $flags.bitSet{13 State}
unit.undead = $flags.bit{14}
unit.`=undead` State = $flags <= $flags.bitSet{14 State}
unit.afraid = $flags.bit{15}

unit.can_stand_on_water = $flyer or $swimmer or $amphibian

// this unit is a temporary mark (i.e. cursor); dont save it
unit.mark = $flags.bit{16}
unit.`=mark` State = $flags <= $flags.bitSet{16 State}

unit.resting = $flags.bit{17}
unit.`=resting` State = $flags <= $flags.bitSet{17 State}

unit.resisting = $flags.bit{18}
unit.`=resisting` State = $flags <= $flags.bitSet{18 State}

unit.hasted = $flags.bit{19}
unit.slowed = $flags.bit{20}

unit.disciplined = $flags.bit{21}
unit.nocorpse = $flags.bit{22}
unit.`=nocorpse` State = $flags <= $flags.bitSet{22 State}

unit.strong = $flags.bit{23}

unit.xrsight = $flags.bit{25}

//how many other units this unit has killed
unit.kills = $get{kills}^~{0}
unit.`=kills` Value = $set{kills Value}

//how much that unit harmed other units
unit.sinned = $get{sinned}^~{0}
unit.`=sinned` Value = $set{sinned Value}

unit.punish_hp = if $kills>>1 then $hp*2 else $sinned

unit.`=backtrack` XYZ =
| less XYZ:
  | $strip{btrack}
  | leave
| when $has{btrack}: leave
| $add_gene{btrack 0 XYZ}

unit.child Type =
| $site.units_get{$xyz}
        .find{(?host and ?type><Type and ?host.serial><$serial)}

unit.is_enemy Target = $owner.is_enemy{Target.owner} and Target.hp>0
unit.is_ally Target = not $owner.is_enemy{Target.owner} and Target.hp>0

unit.size =
| S = $sprite.size
| if $height then S else [S.0 S.1 0]

unit.moves = max 0 $mov-$fatigue

unit.alive = fxn $hp > 0
unit.harmed = fxn $hp < $class.hp

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
| $sprite <= if $show or $site.editor
             then $default_sprite
             else $site.nil.sprite
| $facing <= 3
| $mirror <= 0
| $serial <= $site.serial
| $site.serial++
| $animate{idle}
| $height <= $class.height
| $hp <= $class.hp
| $def <= $class.def
| $flags <= 0
| $alpha <= 0
| $delta <= 0
| $from.init{0,0,-1}
| when $class.active:
  | less $active: // at some point there was double active bug.
    | $site.active.push{Me}
  | $active <= 1
  | $mov <= $class.mov
  | $fatigue <= 0
  | $handled <= 0
  | $delay <= 0
  | $aistate <= \initial
  | $ordered.type <= 0
  | $next_action.type <= 0
  | $action.init{idle 0,0,0}
  | $velocity.init{[0.0 0.0 0.0]}
  | $add_genes{$inborn}
  | $update_move_method

unit.morph Class =
| when Class.is_text: Class <= $main.classes.Class
| $owner.lost_unit{Me}
| $hp <= max 1 | Class.hp + $hp - $class.hp
| $class <= Class
| $sprite <= if $show or $site.editor
             then $default_sprite
             else $site.nil.sprite
| $animate{idle}
| $owner.got_unit{Me}
| when $hp<0:
  | D = -$hp + 1
  | $hp <= 1
  | $harm{Me D}

unit.find_dna Name = $main.cfg.gene.Name

unit.add_gene Name Duration Data =
| Effect = $find_dna{Name}
| when no Effect: Effect <= [[on static]]
| On = Effect.0
| when On.0 <> `on`:
  | $site.notify{"unit.add_gene: missing `on{When}` for effect [Name]"}
  | leave
| Flag = getUnitFlagsTable{}.Name
| when got Flag:
  | when $flags.bit{Flag}: leave //already got this gene
  | when Name><invisible: $alpha <= 127
  | $flags <= $flags.bitSet{Flag 1}
  | $update_move_method
| When = On.1
| $genes <= $genes.cons{$site.new_gene{When Name Duration Data}}

unit.add_genes Genes =
| for E Genes: case E
    [`{}` Head @Args]
      | case Head
         [`.` Name Life] | $add_gene{Name Life Args}
         Name | $add_gene{Name 0 Args}
    Else | $add_gene{E 0 []}

unit.has Name = got $genes.find{?name><Name}

unit.cooldown_of ActName =
| E = $genes.find{E => E.name><cool and E.data.0><ActName}
| if got E then [E.data.1 E.data.2] else 0

unit.set Name Value =
| for E $genes: when E.name><Name:
  | E.data.heapfree
  | E.data <= Value.enheap
  | leave
| $add_gene{Name 0 Value}

unit.get Name =
| for E $genes: when E.name><Name: leave E.data.unheap
| No

unit.strip What =
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
    | $flags <= $flags.bitSet{Flag 0}
    | $update_move_method
  | $site.free_gene{E}
| $genes.heapfree
| $genes <= Es.enheap

unit.acts = $class.acts

unit.run_genes Selector target/0 xyz/0 =
| less Target: Target <= Me
| less Xyz: Xyz <= Target.xyz
| Sel = if Selector.is_text then X => X.when><Selector else Selector
| Es = []
| for E $genes: when Sel E:
  | DNA = $find_dna{E.name}
  | push DNA Es //cuz invoking it right here may clobber $genes
| for Effect Es: $effect{Effect Target Xyz}

unit.run_gene Name Data Target TargetXYZ =
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

unit.idle = not $ordered.type and not $delay and
           [$action $next_action].all{?type^~{0 idle} >< idle}

unit.pick_facing F =
| $facing <= F
| AS = $anim_seq
| FrameIndex = AS.($anim_step%AS.size).0
| Frame,Mirror = $sprite.get_frame_at_angle{FrameIndex $facing}
| $frame <= if Frame.w > 1 then Frame else 0
| $mirror <= Mirror

unit.animate Anim =
| $anim <= Anim
| $anim_seq <= $sprite.anims.$anim
| when no $anim_seq:
  | $anim_seq <= $sprite.anims.idle
  | less got $anim_seq: bad "unit [$type] is missing `idle` anim"
| $anim_step <= -1
| $anim_wait <= 0
| $update_anim

unit.update_anim =
| when $anim_wait-- > 1: leave
| when $anim_step+1 >< $anim_seq.size:
  | when $anim >< death: leave
  | when $anim >< attack or $anim><hit:
    | $animate{idle}
| $anim_step <= ($anim_step+1)%$anim_seq.size
| Step = $anim_seq.$anim_step
| less Step.1:
  | when Step.0><impact:
    | when $anim><attack: $action.onHit
    | $update_anim
    | leave
  | when Step.0><step:
    | when got@@it $class.onMoveStep: $effect{it Me $xyz}
    | $update_anim
    | leave
| $pick_facing{$facing}
| $anim_wait <= Step.1

unit.free =
| when $owner: $owner.lost_unit{Me}
| when $id >< $owner.leader.id: $owner.leader <= $site.nil
| when $active: $active <= 2 //request removal from active list
| less $path.end: $set_path{[]}
| $reset_goal
| $host <= 0
| $colors <= 0
| for E $genes: $site.free_gene{E}
| $genes.heapfree
| $genes <= []
| $site.free_unit{Me}

unit.removed = fxn $xyz.2 >< -1

in_range Me XYZ =
| less fxn XYZ.mdist{$xyz}<<$range: leave 0
| $site.seen_from{$xyz $goal.xyz}

unit.units_in_range Range = $site.units_in_range{Me.xyz Range}

unit.nearby_enemies_at XYZ =
| Es = []
| for D Dirs43:
  | Us = $site.cellp{XYZ+D}.floor.units
  | Us.skip{?empty}.keep{?is_enemy{Me}}.keep{?alive}{E=>push E Es} //.keep{E=>(E.xyz.2-XYZ.2)<<1}
| Es

unit.infov XYZ = //in field of view
| if (XYZ-$xyz).take{2}{?sign} <> -$direction then 1 else 0

site.xr_seen_cells Cell Sight F =
| UX,UY,UZ = Cell.xyz
| for DX,DY points_in_diamond{Sight}:
  | X = UX+DX
  | Y = UY+DY
  | when X>0 and Y>0:
    | Z = 0
    | H = $height{X Y}
    | C = $cell{X Y 0}
    | EC = C+H
    | while C < EC:
      | when not C.empty
        | F C
        | when (C+1).empty: F C+1
      | C += 1

unit.seen_cells =
| Cs = []
| when $xrsight:
  | $site.xr_seen_cells{$cell $sight | C => push C Cs}
  | leave Cs.list
| $site.seen_cells{$cell $sight | C => push C Cs}
| Cs.list

unit.explore =
| when no $sight: leave
| $owner.explore{$seen_cells}

unit.fow_hides = $class.fow_hides

unit.threatened_at XYZ =
| for E $nearby_enemies_at{XYZ}:
  | when not E.afraid and E.can_attack{E.cell $site.cellp{XYZ}}:
    | when E.infov{XYZ}: leave 1
| 0

unit.threatened = $threatened_at{$xyz}

unit.reveal_nearby_enemies =
| for E $nearby_enemies_at{$xyz}:
  | when E.invisible: E.strip{invisible}

heal_unit Me Amount =
| less $class.hp: leave
| $hp += min Amount $class.hp-$health

unit.counter_attack Attacker =
| less $owner.id <> $site.player and $moves>0 and $atk: leave
| when $afraid or no $enemies_in_range.find{?id><Attacker.id}: leave
| less $can_attack{$cell Attacker.cell}: leave
| $order_at{Attacker.xyz 0}

unit.attack_bonus Target =
| Bonus = 0
| case $sees_facing{Target}
  side | Bonus += 1
  back | Bonus += 3
| Bonus += max -2: min 2 $xyz.2-Target.xyz.2
| when $invisible: Bonus += 2
| Bonus

//action goes through target`s defense
unit.assault Target =
| Def = max 0 Target.def-$attack_bonus{Target}
| Hit = min{Def $mov}
| $mov -= Hit
| Def -= Hit
| when Def > 0: //miss?
  | Target.def <= Def-1
  | Target.counter_attack{Me}
  | when $owner.human:
    | $owner.notify{"Your [$title] missed [Target.title]."}
  | when Target.owner.human:
    | $owner.notify{"[$title] missed your [Target.title]."}
  | $sound{miss}
  | leave 0
| Target.def <= Target.class.def
| leave 1

unit.hit Damage Target =
| Damage = if Damage><user then $atk else Damage
| when Target.undead:
  | when $blessed: Damage += Damage
  | less $blessed: Damage <= max 1 (Damage+2)/3
| $run_genes{attack}
| Target.harm{Me Damage}

unit.harm Attacker Damage =
| when $ai <> unit: leave //likely collateral in explosion
| when $removed or not $alive: leave //entered building?
| when Damage << 0:
  | heal_unit Me -Damage
  | leave
| $resting <= 0
| Damage <= max 1 Damage
| $hp -= Damage
| when Attacker: Attacker.sinned += Damage
| less $owner.human: $owner.ai.harm{Attacker Me}
| when $owner.human:
  | Died = if $hp > 0 then "" else " and died"
  | $owner.notify{"Your [$title] sustained [Damage] points of damage[Died]."}
| when $hp > 0:
  | OnHarm = $class.onHarm
  | when OnHarm: $effect{OnHarm Me $xyz}
  | when $anim><idle or $anim><move: $animate{hit}
  | leave
| when Attacker:
  | when $gold:
    | when not $undead or $inborn.has{undead}:
    | $owner.data.lossage += $gold
  | Attacker.kills++
| $die
| $action.cycles <= 1

//called when unit enters cell ingame, not in editor or game-init
unit.on_entry =
| for U $cell.units: U.run_genes{entry}

unit_run_triggers Me =
| for U $cell.units: when U.trigger.is_list: U.effect{U.trigger Me $xyz}

unit.fine_move FXYZ =
| C = $site.c
| FXYZ = FXYZ.list //required for fxn
| XYZ = fxn [FXYZ.0/C FXYZ.1/C FXYZ.2/C]
| $from.init{$xyz}
| $remove
| $xyz.init{XYZ}
| $fxyz.init{FXYZ}
| $zhack <= 0
| when $ai >< unit:
  | Platform = $site.units_get{$xyz}.find{?fheight}
  | when got Platform: $zhack <= -Platform.fheight
| RUs = []
| when $fheight:
  | RUs <= $site.units_get{$xyz}{[? ?fxyz]}
  | RUs{?0.remove}
| $site.place_unit{Me}
| for U,F RUs: U.fine_move{F}
| $floor <= if $block then $xyz.2 else $cell.floor
| $environment_updated
| when $ai >< unit: unit_run_triggers Me
| Me

unit.move XYZ =
| C = $site.c
| XYZ = XYZ.list //required for fxn
| fxn $fine_move{[XYZ.0*C XYZ.1*C XYZ.2*C]}
| when $class.active: $run_genes{move}
| Me

unit.remove =
| when $removed: leave
| $site.remove_unit{Me}
| $xyz.2 <= -1

unit.environment_updated =

unit.face XYZ =
| XY = (XYZ-$xyz).take{2}{?sign}
| less XY >< [0 0]: $facing <= Dirs.locate{(XYZ-$xyz).take{2}{?sign}}

unit.direction = Dirs.($facing/2*2)

unit.sees_facing Target =
| D = (Target.xyz-$xyz).take{2}{?sign}
| TD = Target.direction
| if D >< TD then \back
  else if D >< -TD then \front
  else \side

unit.sound SoundName = $site.sound_at{$floor.xyz $id^not SoundName}

export unit init_unit_module
