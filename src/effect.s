use util effect_ macros

Effects = t


effect on When: No

effect add @Args:
| Name = 0
| Duration = 0
| case Args
  [N] | Name <= N
  [N D] | Name <= N
        | Duration <= D
  Else | bad 'effect add: wrong number of arguments: [Args]'
| Target.add_gene{Name Duration []}

effect strip Name:
| when got Target.class.inborn.find{Name}: leave
| Target.strip{Name}

effect add_item Name Amount: Target.add_item{Name Amount}

effect tenant_mark Type:
| Block = $site.block_at{TargetXYZ}
| S = $site.units_get{TargetXYZ}.find{?type><Type}
| less Block:
  | when got S:
    | S.delta <= 50
    | when S.alpha><255
      | S.die
  | leave
| when got S: leave
| S = $owner.alloc_unit{Type}
| S.alpha <= 255
| S.delta <= -50
| S.move{TargetXYZ}

effect turn State Players ActNames:
| when Players >< owner: Players <= [$owner.id] 
| when Players >< target_owner: Players <= [Target.owner.id]
| $site.turn_act{State Players ActNames}

effect gain @Args:
| ActNames = []
| Player = 0
| case Args
   [ANs] | ActNames <= ANs
         | Player = Target.owner
   [PId ANs] | ActNames <= ANs
             | Player <= $site.players.PId
| when ActNames >< all: ActNames <= $main.acts{}{?0}
| for ActName ActNames:
  | when ActNames.size><1 and Target.owner.human:
    | Title = ActName.replace{'_' ' '}
    | Player.notify{"Gained knowledge of [Title]."}
  | $site.turn_act{1 Player.id ActName}

effect cool Time: $add_gene{cool Time [$action.type $site.turn Time]}

effect explore Player State: $site.explore{State}

effect confirm Title Text:
| $main.show_message{Title buttons/[yes,'Yes' no,'No'] Text}

effect animate Anim: $animate{Anim}

effect macro Name:
| M = $main.cfg.macro.Name
| when no M: bad "main/macro.txt doesnt define `[Name]`"
| $effect{M Target TargetXYZ}

effect visual Effect:
| E = $site.visual{TargetXYZ Effect}
| when Target: E.fxyz.init{Target.fxyz}

effect visual1 Effect: //this one guards against multiple instances
| Type = "effect_[Effect]"
| E = $site.units_get{TargetXYZ}.find{?type><Type}
| when got E: leave
| $site.visual{TargetXYZ Effect}

effect sound Sound: $sound{Sound}

effect heal Amount: Target.harm{Me -Amount}

effect harm Damage: Target.harm{Me Damage}

effect hit Damage: $hit{Damage Target}

effect punish MaxDamage:
| Damage = if Target.kills>>1 then Target.hp else Target.sinned
| Target.harm{Me min{MaxDamage Damage}}

effect lifedrain Amount:
| when Amount >< full: Amount <= $class.hp
| Amount <= min{Amount Target.hp $class.hp-$hp}
| Target.harm{Me Amount}
| $harm{Me -Amount}

unit.telepush Attract TargetXYZ R =
| B = Me
| SXYZ = B.xyz
| DXYZ = TargetXYZ
| Test = 0
| when R<0:
  | Test <= 1
  | R <= -R
| DX,DY,DZ = if Attract then DXYZ-SXYZ else SXYZ-DXYZ
| BP = B.xyz
| when DXYZ >< SXYZ:
  | DX <= B.direction.0
  | DY <= B.direction.1
| D = max 1 if DX.abs>DY.abs then DY.abs else DX.abs
| DX /= D
| DY /= D
| Trail = []
| P = BP.copy
| PrevP = P.copy
| when DY or DX: times I R: for YI max{1 DY.abs}:
  | P.1 += DY.sign
  | for XI max{1 DX.abs}:
    | P.0 += DX.sign
    | less $site.valid{@P}: _goto done
    | F = $site.cellp{P}.floor
    | less F.vacant:  _goto done
    | PrevZ = PrevP.2
    | PrevP.init{P}
    | push P Trail
    | less B.flyer:
      | when (F-1).tile.liquid:  _goto done //ensure water blocks non-flyers
      | when PrevZ - F.xyz.2 >> 2:  _goto done //cliff stops movement
| _label done
| when Test: leave $site.cellp{PrevP}
| when PrevP<>BP:
  | B.reset_goal
  | B.move{PrevP}
  | for T Trail:
    | less got $site.units_get{T}.find{?type><effect_dustend}:
      | $site.visual{T dustend}
| $site.visual{B.xyz dust}

effect telekinesis:
| when Target.ai><unit and Target.id:
  | less Target.flyer or Target.heavy:
    | when $xyz.mdist{Target.xyz}><1 and ($xyz.1-Target.xyz.1).abs<<1:
      | Target.telepush{0 $xyz 6}
      | $sound{blowaway}
      | leave
    | Target.telepush{1 $xyz 6}
    | $sound{blowaway}
    | leave
| $owner.spawn{TargetXYZ unit_telekinesis}

effect send_flying:
| when Target.flyer or Target.heavy: leave
| Target.move{Target.xyz+[0 0 2]}

effect superpose:
| XYZ = $xyz.copy
| $move{TargetXYZ}
| when Target: Target.move{XYZ}

effect shake_screen Cycles: $site.shake{Cycles}
effect color_overlay @List: $site.set_color_overlay{List}

effect area As: //area{any,3,harm{magic.2}}
| [Whom Range @Es] = As
| Ts = $site.units_in_range{TargetXYZ Range}.skip{?empty}
| case Whom [exclude_self W]:
  | Whom <= W
  | Ts <= Ts.skip{?id><$id}
| when Whom><ally: Ts <= Ts.skip{?is_enemy{Me}}
| when Whom><enemy: Ts <= Ts.keep{?is_enemy{Me}}
| for T Ts: $effect{Es T T.xyz}

effect spread What Harm
| when $hp < 2:
  | when $action.type <> die: $die
  | leave
| for C $site.cellp{TargetXYZ}.floor.neibs{}{?floor}:
  | XYZ = C.xyz
  | when C.empty and (XYZ.2-TargetXYZ.2).abs<<1 and no C.units.find{?type><What}:
    | S = $owner.alloc_unit{What}
    | less S.alpha:
      | S.alpha <= 255
      | S.delta <= -50
    | S.hp <= $hp-1
    | S.move{XYZ}
    | when Harm:
      | B = C.block
      | when B: B.harm{Me Harm}

effect detonate Damage MaxH:
| XYZ = Target.xyz.copy
| B = $site.block_at{XYZ}
| when Damage><health: Damage <= Target.class.hp
| Target.harm{Me Target.class.hp}
| for D Dirs43
  | C = $site.cellp{XYZ+D}
  | F = C.floor
  | B = F.block
  | when B and (C-F).abs<MaxH: B.harm{Me Damage}

effect explosion Size:
| for U $site.units_in_range{TargetXYZ Size}:
  | Damage = max 1 Size-TargetXYZ.mdist{U.xyz}
  | U.harm{Me Damage}

effect notify Text: Target.owner.notify{Text}

effect msg Title @Body: $main.show_message{Title Body.text{' '}}

type unit_getset{unit}

unit_getset.`.` K =
| Getter = $unit.main.cfg.unit_getters_.K
| when no Getter: bad "unit_getset: unknown unit field [K]"
| Getter $unit

unit_getset.`=` K V =
| Setter = $unit.main.cfg.unit_setters_.K
| when no Setter: bad "unit_getset: unknown unit field [K]"
| Setter $unit V

effect set Name Value: unit_getset{Target}.Name <= Value

effect inc Name Value: unit_getset{Target}.Name += Value

effect site_set Name Value: $site.data.Name <= Value

effect boost_defense Amount: $def <= min{$def+Amount $class.def+Amount}

effect victory Player Reason:
| SD = $site.data
| when Player >< owner: Player <= $owner.id
| SD.winner <= Player
| SD.victory_type <= Reason

effect spell_of_mastery_pre:
| Us = $cell.units
| Node = Us.find{?type><special_node}
| less got Node: $owner.notify{"node went missing!"}
| Node.blessed <= 1
| S = $site.units_get{TargetXYZ}.find{?type><effect_aura}
| when no S:
  | S <= $owner.alloc_unit{effect_aura}
  | S.alpha <= 255
  | S.delta <= -50
  | S.move{TargetXYZ}

site.all_nodes_activated =
| Nodes = $active.list.keep{(not ?removed and ?type><special_node)}
| Nodes.all{?blessed}

effect spell_of_mastery_end:
| when $site.all_nodes_activated:
  | $site.data.winner <= $owner.id
  | $site.data.victory_type <= 'Victory by casting the Spell of Mastery'

effect swap Arg:
| XYZ = $xyz.copy
| Target.remove
| $move{TargetXYZ}
| Target.move{XYZ}

effect gateway:
| B = $cell.block
| less B: leave
| T = $cell.gate
| less T: leave
| $site.visual{B.xyz teleport}
| A = T.cell.block
| B.move{T.xyz}
| B.reset_goal
| when A:
  | AH = A.health
  | BH = B.health
  | B.harm{0 AH}
  | A.harm{0 BH}
| $site.visual{T.xyz teleport}
| $sound{summon}

effect interrupt: Target.interrupt

effect gold Amount:
| Target.owner.data.gold += Amount

effect add_spell Name Amount:
| Act = $main.acts.Name
| when no Act:
  | bad "add_spell: missing act [Name]"
  | leave
| OId = Target.owner.id
| Act.picks.OId += Amount

effect remove:
| Target.free

effect die: when Target.action.type <> die: Target.die

effect fade_die:
| when Target.action.type >< die: leave
| Target.add_gene{fade_die 0 []}

effect fade_die_upd:
| $delta <= 25
| when $alpha<255: leave
| when $action.type >< die: leave
| $die

effect clear Where:
| X,Y,Z = case Where
  target | TargetXYZ
  X,Y,Z | X,Y,Z
  Else | bad "effect clear: invalid target ([Where])"
| $site.clear_tile{X Y Z}

effect set_tile [X Y Z] Type:
| Tile = $main.tiles.Type
| when no Tile:
  | say "set_tile: missing tile `[Type]`"
  | leave
| $site.set{X Y Z Tile}

player.spawn XYZ What =
| S = $alloc_unit{What}
| S.aistate <= \spawned
| less S.alpha:
  | S.alpha <= 255
  | S.delta <= -50
| S.move{XYZ}

effect spawn What:
| when What><auto: What <= $action.act.name
| $owner.spawn{TargetXYZ What}

effect resurrect:
| Cell = $site.cellp{TargetXYZ}
| less Cell.vacant: leave
| Cs = Cell.units.keep{?ai><corpse}
| when Cs.end: leave
| C = Cs.0
| U = $owner.spawn{TargetXYZ C.get{corpse}}
| U.add_gene{undead 0 []}
| U.nocorpse <= 1
| U.hp <= max 1 U.hp/2
| Cs{?free}
| 0

effect spawn_item ItemType Amount: $cell.add_item{ItemType Amount}

effect drop ItemType Amount:
| when ItemType><_: ItemType <= $action.type.drop{5}
| MaxAmount = $get_item{ItemType}
| when Amount><all: Amount <= MaxAmount
| Amount <= min{MaxAmount Amount}
| $drop_item{ItemType Amount}

effect take ItemType Amount:
| when ItemType><_: ItemType <= $action.type.drop{5}
| MaxAmount = $cell.get_item{ItemType}
| when Amount><all: Amount <= MaxAmount
| Amount <= min{MaxAmount Amount}
| $add_item{ItemType Amount}
| $cell.add_item{ItemType -Amount}

effect morph ClassName:
| Class = $main.classes.ClassName
| less got Class: bad "morph: Missing class `[ClassName]`"
| $morph{Class}

effect charm NewOwner:
| XYZ = Target.xyz.deep_copy
| Target.remove
| Target.owner <= $owner
| Target.colors <= $owner.colors
| Target.move{XYZ}

effect child ChildType Genes:
| S = $owner.alloc_unit{ChildType}
| S.alpha <= 255
| S.delta <= -50
| S.move{TargetXYZ}
| S.host <= Target
| S.host_serial <= Target.serial
| S.add_genes{Genes}

effect caster Who:
| Leader = $owner.leader
| less Who >< leader and Leader: leave
| Leader.animate{attack}
| Leader.face{TargetXYZ}

knockback Me Target =
| Dir = Target.xyz-$xyz
| less Dir.all{?abs<<1}: leave
| Dir.2 <= 0
| DXYZ = Target.xyz+Dir
| DC = $site.cell{@DXYZ}
| when DC.tile.empty and not DC.block: Target.move{DXYZ}

effect blowaway R BlowSelf:
| Handled = []
| for B $site.units_in_range{TargetXYZ R}: when B.ai >< unit:
  | when B and not Handled.has{B.id} and (BlowSelf or B.xyz<>TargetXYZ):
    | DX,DY,DZ = B.xyz-TargetXYZ
    | push B.id Handled
    | N = max 0 R-(DX.abs+DY.abs)
    | BP = B.xyz
    | when TargetXYZ >< BP:
      | DX <= B.direction.0
      | DY <= B.direction.1
    | D = if DX.abs>DY.abs then [DX.sign 0 0] else [0 DY.sign 0]
    | TP = BP
    | Trail = []
    | times I N:
      | T = BP + D*(I+1)
      | less $site.valid{@T}: done
      | F = $site.cellp{T}.floor
      | less F.vacant: done
      | Prev = TP
      | TP <= T
      | push T Trail
      | less B.flyer:
        | when (F-1).tile.liquid: done //ensure water blocks non-flyers
        | when Prev.2 - F.xyz.2 >> 2: done //cliff stops movement
    | when TP<>BP:
      | B.reset_goal
      | B.move{TP}
      | for T Trail:
        | less got $site.units_get{T}.find{?type><effect_dustend}:
          | $site.visual{T dustend}
    | $site.visual{B.xyz dust}

effect jumpdown:
| $reset_goal
| $animate{idle}
| $forced_order{move [@TargetXYZ.take{2} $xyz.2]}

effect teleport Arg:
| $reset_goal
| $forced_order{fastmove TargetXYZ}

effect face:
| $face{TargetXYZ}

effect align How:
| less How><door: bad "effect align: cant [How]-align"
| X,Y,Z = $xyz
| less $site.at{X Y-1 Z}.empty or $site.at{X Y+1 Z}.empty:
  | $face{$xyz+[1 0 0]}
  | T = $site.at{X Y-1 Z}
  | when T.wallShift and not $site.at{X+1 Y Z}.type><T.around:
    | $fxyz.init{$fxyz+[T.wallShift 0 0]}
  | leave
| $face{$xyz+[0 1 0]}
| T = $site.at{X-1 Y Z}
| when T.wallShift and not $site.at{X Y+1 Z}.type><T.around:
  | $fxyz.init{$fxyz+[0 T.wallShift 0]}

effect yes //confirmation
| MenuActName,XYZ,TargetSerial = $get{menuact}
| T = 0
| when got TargetSerial:
  | T <= $active.list.find{?serial><TargetSerial}
  | when no T or not T.alive:
    | $owner.notify{"Target is lost!"}
    | leave
| Act = $main.acts.MenuActName
| when no Act:
  | $owner.notify{"effect yes: missing act [MenuActName]"}
  | leave
| $order_at{(T or XYZ) Act}

effect no | No

check_when Me Target C =
| leave: case C
  target | Target<>0
  ally | not $owner.is_enemy{Target.owner}
  enemy | $owner.is_enemy{Target.owner}
  confirmed | $main.dialog_result><yes
  harmed | Target.health<>Target.class.hp
  idle | not Target.goal
  rested | $mov><$class.mov
  resting | Target.resting
  nodes_on | $site.all_nodes_activated
  [`+` not C] | not: check_when Me Target C
  [`.` below Type] | (Target.cell-1).type><Type
  [`.` has_health A] | Target.health>>A
  [`.` has Effect] | Target.has{Effect}
  [`.` hasnt Effect] | not Target.has{Effect}
  [`.` got_child Type] | got Target.child{Type}
  [`.` no_child Type] | no Target.child{Type}
  Else | 0

unit.effect Effect Target TargetXYZ =
| XYZ = Target.xyz.deep_copy
| when XYZ.2 >< -1: leave
| case Effect [on,When @Es]: Effect <= Es
| T = Target
| Es = Effect.list
| RunActEffects = 1
| when Es.size >< 0 or (T.is_unit and T.id><$id):
  | RunActEffects <= 0 // action doesnt affect outside site
| till Es.end
  | E = pop Es
  | less E.is_list: E <= [E []]
  | Name,@Args = E
  | F = Effects.Name
  | if got F then F{Me T XYZ Args}
    else if Name >< when then
      | When = Args
      | Cs = if When.is_list and not When.end and When.0<>`.` and When.0<>`+`
             then When
             else [When]
      | less Cs.all{C => check_when Me T C}:
        | while not Es.end and Es.0<>endwhen: pop Es
    else if Name >< endwhen then
    else if Name >< resist then
      | when T.resisting:
        | $site.visual{T.xyz resist}
        | T.sound{resist}
        | less got T.class.inborn.find{resist}: T.strip{resist}
        | leave
    else if Name >< shell then
      | less $assault{Target}: leave
      | when T.shelled:
        | $site.visual{T.xyz shell}
        | T.sound{shell}
        | less got T.class.inborn.find{shell}: T.strip{shell}
        | leave
      | when $range<<1: Target.run_genes{counter target/Me xyz/Me.xyz}
    else if Name >< insulate then RunActEffects<=0
    else if Name >< onAttack then when $onAttack: $effect{$onAttack T T.xyz}
    else if Name >< onHit then
      if $range><1 and $xyz.2-T.xyz.2>1 then
        | $shot_missile{Target [boulder]
                        [shell [hit user] [impact explosion] [sound explosion]]}
      else
        | $effect{$onHit T T.xyz}
    else if Name >< missile then
      | $shot_missile{(Target or XYZ) Args Es}
      | Es <= []
    else if Name >< target then T <= Target
    else if Name >< host then T <= $host
    else if Name >< self then T <= Me
    else if Name >< tenant then
      | Block = $site.block_at{XYZ}
      | less Block: _goto end
      | T <= Block
    else if Name >< same_z then | XYZ <= XYZ.deep_copy; XYZ.2 <= Me.xyz.2
    else if Name >< all_alive then
      | for U $site.active: when U.alive:
        | when U.ai><unit: $effect{Es U U.xyz}
      | _goto end
    else if Name >< hydra_targets then
      | D = (TargetXYZ-$xyz){?sign}
      | DD = D.1,D.0,D.2
      | for XYZ [$xyz+DD $xyz-DD]
        | B = $site.block_at{XYZ}
        | when B: $effect{Es B B.xyz}
      | $effect{Es T XYZ}
      | _goto end
    else if Name >< owner_units then
      | OID = $owner.id
      | for U $site.active: when U.owner.id><OID:
        | when U.ai><unit: $effect{Es U U.xyz}
      | _goto end
    else if Name >< enemy_units then
      | OID = $owner.id
      | for U $site.active: when $is_enemy{U}:
        | when U.ai><unit: $effect{Es U U.xyz}
      | _goto end
    else bad "no effect handler for [Name]{[Args]} of [Me]"
| _label end
| when RunActEffects: $run_genes{act}