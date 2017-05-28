use util effect_ macros

Effects = t

set_act_enabled Me State Players ActNames =
| when Players >< all: Players <= 16{(?)}
| when ActNames >< all: ActNames <= $params.acts{}{?0}
| when Players.is_int: Players <= [Players]
| when ActNames.is_text: ActNames <= [ActNames]
| Acts = $params.acts
| for ActName ActNames:
  | Act = Acts.ActName
  | less got Act: bad "missing act [ActName]"
  | Es = Act.enabled
  | for Id Players: Es <= Es^set_bit{Id State}
  | Act.enabled <= Es

effect enable State Players ActNames:
| when Players >< owner: Players <= [$owner.id] 
| when Players >< target_owner: Players <= [Target.owner.id]
| set_act_enabled $main State Players ActNames

effect on When: No

effect add Name: Target.add_effect{Name 0 []}

effect strip Name: Target.strip_effect{Name}

effect add_item Name Amount: Target.add_item{Name Amount}

effect mod Args: Target.mod <= [Args @(Target.mod or [])]

effect tenant_mark Type:
| Block = $world.block_at{TargetXYZ}
| S = $world.units_get{TargetXYZ}.find{?type><Type}
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

metric A B = (B-A).take{2}.abs

effect gain @Args:
| ActNames = []
| Player = 0
| case Args
   [ANs] | ActNames <= ANs
         | Player = Target.owner
   [PId ANs] | ActNames <= ANs
             | Player <= $world.players.PId
| when ActNames >< all: ActNames <= $main.params.acts{}{?0}
| for ActName ActNames:
  | when ActNames.size><1 and Target.owner.human:
    | Title = ActName.replace{'_' ' '}
    | $main.show_message{'Knowledge Gained'
       "The secret knowledge of [Title] has been revealed"}
  | set_act_enabled $main 1 Player.id ActName
  | Player.research_item{ActName}

effect cool Time:
| $add_effect{cool 0 [$action.type $world.turn Time]}

effect explore Player State: $world.explore{State}

effect confirm Title Text:
| $main.show_message{Title buttons/[yes,'Yes' no,'No'] Text}

effect animate Anim: $animate{Anim}

effect macro Name:
| M = $main.params.macro.Name
| when no M: bad "main/macro.txt doesnt define `[Name]`"
| $effect{M Target TargetXYZ}

effect impact Impact:
| E = $world.effect{TargetXYZ Impact}
| when Target: E.fxyz.init{Target.fxyz}

effect effect Effect:
| E = $world.effect{$xyz Effect}
| E.fxyz.init{$fxyz}

effect effect1 Effect:
| Type = "effect_[Effect]"
| E = $world.units_get{TargetXYZ}.find{?type><Type}
| when got E: leave
| $world.effect{TargetXYZ Effect}

effect sound Sound: $sound{Sound}

effect heal Damage: Target.harm{Me -Damage}

effect harm As:
| Combat = 1
| Whom = \target
| case As
  [A W] | Combat <= A
        | Whom <= W
  A | Combat <= A
| T = case Whom target(Target) self(Me) Else(bad "harm recipient `[Whom]`")
| $assault{Combat T}

effect reduce_health_to Health:
| when Target.health << Health: leave
| $assault{[`.` unavoid Target.health-Health] Target}

effect area As: //area{any,3,harm{magic.2}}
| [Whom Range @Args] = As
| Es = Args{?^normalize_curly}
| Ts = $world.units_in_range{TargetXYZ Range}.skip{?empty}
| case Whom [exclude_self W]:
  | Whom <= W
  | Ts <= Ts.skip{?id><$id}
| when Whom><ally: Ts <= Ts.skip{?is_enemy{Me}}
| when Whom><enemy: Ts <= Ts.keep{?is_enemy{Me}}
| for T Ts: $effect{Es T T.xyz}

effect neibs Args:
| Es = Args{|[_ N A]=>[N A];[_ N @As]=>[N As]}
| D = (TargetXYZ-$xyz){?sign}
| DD = D.1,D.0,D.2
| for XYZ [$xyz+DD $xyz-DD]
  | B = $world.block_at{XYZ}
  | when B: $effect{Es B B.xyz}

effect counter Arg:
| when $range<<1: Target.run_effects{counter target/Me xyz/Me.xyz}

effect spawn_field Args:
| [TTL Freq R Param @As] = Args
| S = $owner.alloc_unit{unit_dummy}
| S.move{TargetXYZ}
| Es = As{?^normalize_curly}
| S.add_effect{field TTL [[effect [on [`.` cycle Freq]] [field [Param R Es]]]]}
| S.add_effect{field TTL [[effect [on timeout] [remove self]]]}

range_points World XYZ R FixTop =
| Ps = points_in_circle{R}{P=>[P.0 P.1 0]+XYZ}
| WW = World.w 
| WH = World.h
| Ps = Ps.keep{(?0>0 and ?1>0 and ?0<<WW and ?1<<WH)}
| if FixTop then for P Ps: P.2 <= World.height{P.0 P.1}
  else for P Ps: P.2 <= World.floor{P}
| Ps

effect field Param R Es:
| Ts = 0
| Type,Count = Param
| if Type><cell then
    | Ps = range_points{$world $xyz R 0}
    | Ts <= dup Count Ps.rand
  else if Type><outdoors_cell and R><world then
    | WW = $world.w 
    | WH = $world.h
    | WD = $world.d
    | Count <= (WH*WW+WD-1)/WD*Count
    | Ts <= dup Count
      | X = WW.rand+1
      | Y = WH.rand+1
      | Z = $world.height{X Y}
      | [X Y Z]
  else if Type><outdoors_cell then
    | Ps = range_points{$world $xyz R 1}
    | Ts <= dup Count Ps.rand
  else if Type><world_outdoors_cell then
  else bad "field: invalid param `[Param]`"
| less Ts: leave
| for T Ts
  | if T.is_unit and T.alive then $effect{Es T T.xyz}
    else $effect{Es 0 T}

effect notify Text: Target.owner.notify{Text}

effect msg Title @Body: $main.show_message{Title Body.text{' '}}

effect mana Amount: Target.owner.mana+=Amount

type unit_getset{unit}

unit_getset.`.` K =
| Getter = $unit.main.params.unit_getters_.K
| when no Getter: bad "unit_getset: unknown unit field [K]"
| Getter $unit

unit_getset.`=` K V =
| Setter = $unit.main.params.unit_setters_.K
| when no Setter: bad "unit_getset: unknown unit field [K]"
| Setter $unit V

effect set Name Value: unit_getset{Target}.Name <= Value

effect inc Name Value: unit_getset{Target}.Name += Value

effect world_set Name Value: $world.params.Name <= Value

effect spell_of_mastery: say 'Casted Spell of Mastery'


effect swap Arg:
| XYZ = $xyz.copy
| Target.remove
| $move{TargetXYZ}
| Target.move{XYZ}

effect recall Where:
| XYZ = [0 0 0]
| if Where><pentagram then
   | P = $owner.pentagram
   | less P: leave
   | XYZ.init{P.xyz}
  else if Where><self then XYZ.init{$xyz}
  else leave
| Target.remove
| Target.move{XYZ}
| Target.backtrack <= 0
| Target.reset_goal
| Target.reset_followers

effect remove Whom: case Whom
  target | Target.free
  self | Me.free
  X,Y,Z | U = $world.block_at{X,Y,Z}
        | when U: U.free
  neib,Type | for U $world.units_get{$xyz}: when U.type><Type: U.free
  Serial | U = $world.units.find{?serial><Serial}
         | when got U and not U.removed: U.free

effect die Whom:
| T = if Whom >< self then Me else Target
| when T.action.type <> die: T.die

effect clear Where:
| X,Y,Z = case Where
  target | TargetXYZ
  X,Y,Z | X,Y,Z
  Else | bad "effect clear: invalid target ([Where])"
| $world.clear_tile{X Y Z}

effect set_tile [X Y Z] Type:
| Tile = $main.tiles.Type
| when no Tile:
  | say "set_tile: missing tile `[Type]`"
  | leave
| $world.set{X Y Z Tile}

effect retile [X Y Z] Type:
| B = $world.block_at{[X Y Z]}
| when B:
  | if B.owner.pentagram
    then B.order_act{recall target/B}
    else B.die // crushed!
| Tile = $main.tiles.Type
| $world.set{X Y Z Tile}
| $die

effect spawn What:
| when What><pentagram:
  | L = $owner.leader
  | What <= if L then L.pentagram else \special_pentagram
| S = $owner.alloc_unit{What}
| S.aistate <= \spawned
| less S.alpha:
  | S.alpha <= 255
  | S.delta <= -50
| S.move{TargetXYZ}

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

effect child What Effects:
| S = $owner.alloc_unit{What}
| S.alpha <= 255
| S.delta <= -50
| S.move{TargetXYZ}
| S.host <= Target
| S.host_serial <= Target.serial
| S.add_effects{Effects}

effect caster Who:
| Leader = $owner.leader
| less Who >< leader and Leader: leave
| Leader.animate{attack}
| Leader.face{TargetXYZ}

effect teleport Arg:
| $reset_goal
| $forced_order{teleport TargetXYZ}

effect research Arg:
| O = Target.owner
| What = O.researching
| Act = $main.params.acts.What
| Needs = O.lore-Act.lore
| when Needs < 0:
  | O.notify{"Not enough lore for `[Act.title]` (collect [-Needs])"}
  | leave
| O.lore -= Act.lore
| O.research_item{What}

effect upkeep Amount:
| $owner.mana -= Amount

effect lore Amount:
| Target.owner.lore += Amount

effect victory Player Reason:
| WP = $world.params
| when Player >< owner: Player <= $owner.id
| WP.winner <= Player
| WP.victory_type <= Reason

effect align How:
| less How><door: bad "effect align: cant [How]-align"
| X,Y,Z = $xyz
| less $world.at{X Y-1 Z}.empty or $world.at{X Y+1 Z}.empty:
  | $face{$xyz+[1 0 0]}
  | T = $world.at{X Y-1 Z}
  | when T.wallShift and not $world.at{X+1 Y Z}.type><T.around:
    | $fxyz.init{$fxyz+[T.wallShift 0 0]}
  | leave
| $face{$xyz+[0 1 0]}
| T = $world.at{X-1 Y Z}
| when T.wallShift and not $world.at{X Y+1 Z}.type><T.around:
  | $fxyz.init{$fxyz+[0 T.wallShift 0]}

check_when Me Target C =
| leave: case C
  ally | not $owner.is_enemy{Target.owner}
  enemy | $owner.is_enemy{Target.owner}
  confirmed | $main.dialog_result><yes
  harmed | Target.health<>Target.class.hp
  idle | not Target.goal
  rested | $steps><$class.steps
  safe | Dirs4.all{D=>|B=$world.block_at{$xyz+[D.0 D.1 0]}; not B or not $is_enemy{B}}
  [`+` not C] | not: check_when Me Target C
  [`.` below Type] | (Target.cell-1).type><Type
  [`.` has_health A] | Target.health>>A
  [`.` has_mana A] | $owner.mana>>A
  [`.` has Effect] | Target.has{Effect}
  [`.` hasnt Effect] | not Target.has{Effect}
  [`.` got_child Type] | got Target.child{Type}
  [`.` no_child Type] | no Target.child{Type}
  [`.` kills N] | Target.kills>>N
  Else | 0

unit.effect Effect Target TargetXYZ =
| XYZ = Target.xyz.deep_copy
| when XYZ.2 >< -1: leave
| case Effect [on,When @Es]: Effect <= Es
| T = Target
| when T.is_unit and T.id<>$id: $run_effects{act}
| Es = Effect.list
| till Es.end
  | E = pop Es
  | less E.is_list: E <= [E []]
  | Name,Args = E
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
    else if Name >< user_attack then $effect{$attack T T.xyz}
    else if Name >< user_impact then $effect{$impact T T.xyz}
    else if Name >< missile then
      | Type = 0
      | Offset = \user
      | Speed = 2
      | case Args
         [T S O]
           | Type <= T
           | if S><height_div then Speed <= 1
             else Speed <= S
           | Offset <= O
         T | Type <= T
      | S = $owner.alloc_unit{Type}
      | case Offset
        user | S.move{$xyz}
             | S.face{XYZ}
        [target @D] | S.move{$xyz}
                    | O = if Target then Target.fxyz
                          else $world.fxyz{XYZ}
                    | S.fxyz.init{O+D}
        Else | bad "invalid offset specifier [Offset]"
      | S.add_effect{missile 0 [[payload $id $serial Es]]}
      | Or = S.order
      | Or.init{missile |Target or XYZ}
      | Or.priority <= 1500
      | C = Speed.float*(XYZ-$xyz).abs*1.5
      | Or.cycles <= @int C
      | Es <= []
    else if Name >< target then T <= Target
    else if Name >< host then T <= $host
    else if Name >< self then T <= Me
    else if Name >< tenant then
      | Block = $world.block_at{XYZ}
      | less Block: _goto end
      | T <= Block
    else if Name >< same_z then | XYZ <= XYZ.deep_copy; XYZ.2 <= Me.xyz.2
    else if Name >< pentagram then
      | P = $owner.pentagram
      | less P: _goto end
      | XYZ.init{P.xyz}
      | Target <= P
    else if Name >< all_alive then
      | for U $world.active: when U.alive:
        | when U.ai><unit: $effect{Es U U.xyz}
      | _goto end
    else if Name >< owner_units then
      | OID = $owner.id
      | for U $world.active: when U.owner.id><OID:
        | when U.ai><unit: $effect{Es U U.xyz}
      | _goto end
    else if Name >< enemy_units then
      | OID = $owner.id
      | for U $world.active: when $is_enemy{U}:
        | when U.ai><unit: $effect{Es U U.xyz}
      | _goto end
    else bad "no effect handler for [Name]{[Args]} of [Me]"
| _label end
| $mod <= 0
