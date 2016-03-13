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

effect add_effect Name Duration Params: Target.add_effect{Name Duration Params}

effect strip Name: Target.strip_effect{Name}

effect add_item Name Amount: Target.add_item{Amount Name}

effect mod Arg: Target.mod <= Arg

effect tenant_mark Type:
| Block = $world.block_at{TargetXYZ}
| S = $world.units_at{TargetXYZ}.find{?type><Type}
| less got Block:
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

effect btrack XYZ:
| when not $idle or $goal:
  | less $goal: leave
  | LA = metric $goal.xyz XYZ
  | less LA>16.0: leave
  | LB = metric $xyz XYZ
  | less LA>10.0: leave
| when $xyz><XYZ:
  | $backtrack <= 0
  | leave
| B = $world.block_at{XYZ}
| when got B and not B.idle: leave
| $order_at{XYZ}

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

effect cool Time: $add_effect{cool Time [[cool [$action.type Time]]]}

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
| E = $world.units_at{TargetXYZ}.find{?type><Type}
| when got E: leave
| $world.effect{TargetXYZ Effect}

effect sound Sound:
| when not $id or (not $removed and $world.human.explored{$xyz}>1):
  | $main.sound{Sound}

effect harm As:
| Damage = 1
| Whom = \target
| case As
  [D W] | Damage <= D
        | Whom <= W
  D | Damage <= D
| when Damage><user: Damage <= Me.damage
| when Damage.is_int
  | $run_effects{?><attack Me $xyz}
  | Mod = $mod
  | $mod <= 0
  | case Mod [`.` boost [N M]]: !Damage + | max 1 | Damage*N/M
| T = case Whom target(Target) self(Me) Else(bad "harm recipient `[Whom]`")
| T.harm{Me Damage}

effect area As:
| [Whom [W H D] @Args] = As
| Es = Args{?^normalize_curly}
| Range = W/$world.c-1
| Ts = $world.targets_in_range{TargetXYZ Range}.skip{?empty}
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
  | when got B: $effect{Es B B.xyz}

effect counter Arg:
| when $range><cross or not $range:
  | Target.run_effects{?><counter Me Me.xyz}

effect lifedrain Amount:
| when Target and Target.has{organic}: Me.harm{Me -Amount}

effect suicide Multiplier:
| Target.harm{Me Target.damage*Multiplier}

effect spawn_field Args:
| [TTL Freq R Param @As] = Args
| S = $owner.alloc_unit{unit_dummy}
| S.move{TargetXYZ}
| Es = As{?^normalize_curly}
| S.add_effect{field TTL [[effect [on [`.` cycle Freq]] [field [Param R Es]]]]}


range_points World XYZ R FixTop =
| Ps = points_in_circle{R}{P=>[P.0 P.1 0]+XYZ}
| WW = World.w 
| WH = World.h
| Ps = Ps.keep{(?0>0 and ?1>0 and ?0<<WW and ?1<<WH)}
| if FixTop then for P Ps: P.2 <= World.height{P.0 P.1}
  else for P Ps: P.2 <= World.fix_z{P}
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
    | Count <= (WH*WW+63)/64*Count
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

effect mana Amount: !Target.owner.mana+Amount

type unit_setter{unit}

unit_setter.`!` K V =
| Setter = $unit.main.params.unit_setters_.K
| when no Setter: bad "unknown unit field [K]"
| Setter $unit V

// sets world param
effect set @Args:
| What = \world
| Name = No
| Value = 1
| Players = 0
| Inc = 0
| case Args [inc @As]:
  | Inc <= 1
  | Args <= As
| case Args
  [A B C] | What <= A
          | Name <= B
          | Value <= C
  [A B] | Name <= A
        | Value <= B
  [A] | Name <= A
  Else | bad "invalid arglist [Args]"
| Ps = if What >< world then [0,$world.params]
       else if What.is_int then Players <= [$world.players.What]
       else if What >< owner then Players <= [$owner]
       else if What >< towner then Players <= [Target.owner]
       else if What >< all then Players <= $world.players
       else if What >< target then [0,(unit_setter Target)]
       else if What >< self then [0,(unit_setter Me)]
       else
| when Players: Ps <= Players{?,?.params}
| when Value >< `?owner`: Value <= $owner.id
| when Value >< `?self`: Value <= $id
| when Value >< `?self_type`: Value <= $type
| for Player,Params Ps
  | if Value.is_list
    then | when no Params.Name: Params.Name <= dup Value.size
         | Params.Name.init{Value}
    else | if Inc then !Params.Name + Value
           else Params.Name <= Value
  | when Player and Name >< mana:
    | if Inc then !Player.mana + Value
      else Player.mana <= Value

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
   //a faster solution would be keeping the linked list of all targeters
| for U $world.active: when U.goal and U.goal.id><Target.id:
  | U.reset_goal

effect remove Whom: case Whom
  target | Target.free
  self | Me.free
  X,Y,Z | U = $world.block_at{X,Y,Z}
        | when got U: U.free
  neib,Type | for U $world.units_at{$xyz}: when U.type><Type: U.free
  Serial | U = $world.units.find{?serial><Serial}
         | when got U and U.xyz.2<>-1: U.free

effect die Whom:
| T = if Whom >< self then Me else Target
| when T.action.type <> die: T.die

effect clear What:
| X,Y,Z = case What
  target | TargetXYZ.deep_copy
  X,Y,Z | X,Y,Z
  Else | bad "effect clear: invalid target ([What])"
| $world.clear_tile{X,Y,Z $main.tiles.filler.id}

effect clear_passage What:
| X,Y,Z = case What
  target | TargetXYZ.deep_copy
  X,Y,Z | X,Y,Z
  Else | bad "effect clear: invalid target ([What])"
| $world.clear_passage{X Y Z}

effect set_tile [X Y Z] Type:
| Tile = $main.tiles.Type
| when no Tile:
  | say "set_tile: missing tile `[Type]`"
  | leave
| $world.set{X Y Z Tile}

effect retile [X Y Z] Type:
| B = $world.block_at{[X Y Z]}
| when got B:
  | if B.owner.pentagram
    then B.order_act{recall target/B}
    else B.die // crushed!
| Tile = $main.tiles.Type
| $world.set{X Y Z Tile}
| $die

effect spawn What:
| S = $owner.alloc_unit{What}
| S.nonguard <= 1
| less S.alpha:
  | S.alpha <= 255
  | S.delta <= -50
| S.move{TargetXYZ}

effect morph ClassName:
| Class = $main.classes.ClassName
| less got Class: bad "morph: Missing class `[ClassName]`"
| $morph{Class}

effect child What Effects:
| S = $owner.alloc_unit{What}
| S.alpha <= 255
| S.delta <= -50
| S.move{TargetXYZ}
| S.host <= Target
| S.host_serial <= Target.serial
| for Name,Duration,Params Effects: S.add_effect{Name Duration Params}

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
| Needs = O.lore-Act.lore.0
| when Needs < 0:
  | O.notify{"Not enough lore for `[Act.title]` (collect [-Needs])"}
  | leave
| Needs = O.mana-Act.lore.1
| when Needs < 0:
  | O.notify{"Not enough mana for `[Act.title]` (collect [-Needs])"}
  | leave
| !O.lore - Act.lore.0
| !O.mana - Act.lore.1
| O.research_item{What}

effect lore Amount:
| !Target.owner.lore + Amount

effect victory Player Reason:
| WP = $world.params
| when Player >< owner: Player <= $owner.id
| WP.winner <= Player
| WP.victory_type <= Reason

effect align How:
| less How><door: bad "effect align: cant [How]-align"
| XYZ = $xyz
| less $world.get{XYZ-[0 1 0]}.empty or $world.get{XYZ+[0 1 0]}.empty:
  | $face{$xyz+[1 0 0]}
  | leave
| $face{$xyz+[0 1 0]}

check_when Me Target C =
| case C
  ally | when $owner.is_enemy{Target.owner}: leave 0
  enemy | less $owner.is_enemy{Target.owner}: leave 0
  confirmed | less $main.dialog_result><yes: leave 0
  harmed | less Target.health<>Target.class.hp: leave 0
  idle | when Target.goal: leave 0
  [`.` has_health A] | less Target.health>>A: leave 0
  [`.` has_mana A] | less $owner.mana>>A: leave 0
  [`.` has Effect] | less Target.has{Effect}: leave 0
  [`.` hasnt Effect] | less Target.has{Effect}: leave 0
  [`.` got_child Type] | leave: got Target.child{Type}
  [`.` no_child Type] | leave: no Target.child{Type}
  [`.` kills N] | less Target.kills>>N: leave 0
| 1

unit.effect Effect Target XYZ =
| when XYZ.2 >< -1: leave
| case Effect [on,When @Es]: Effect <= Es
| T = Target
| when T.is_unit and T.id<>$id and $invisible: $strip_effect{invisible}
| Es = Effect.list
| till Es.end
  | E = pop Es
  | less E.is_list: E <= [E []]
  | Name,Args = E
  | F = Effects.Name
  | if got F then F{Me T XYZ Args}
    else if Name >< when then
      | When = Args
      | Cs = if When.is_list and not When.end and When.0<>`.`
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
      | HDiv = 0
      | case Args
         [T S O]
           | Type <= T
           | if S><height_div then
               | Speed <= 1
               | HDiv <= 1
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
      | H = ($xyz.2-XYZ.2).abs
      | C = Speed.float*(XYZ-$xyz).abs*1.5
      | when HDiv: C <= C/(max 1 H/4).float
      | Or.cycles <= @int C
      | Es <= []
    else if Name >< target then T <= Target
    else if Name >< host then T <= $host
    else if Name >< self then T <= Me
    else if Name >< same_z then | XYZ <= XYZ.deep_copy; XYZ.2 <= Me.xyz.2
    else if Name >< pentagram then
     | P = $owner.pentagram
     | less P: leave
     | XYZ.init{P.xyz}
     | Target <= P
    else if Name >< all_alive then
      | for U $world.active: when U.alive:
        | when U.ai><unit: $effect{Es U U.xyz}
      | leave
    else if Name >< owner_units then
      | OID = $owner.id
      | for U $world.active: when U.owner.id><OID:
        | when U.ai><unit: $effect{Es U U.xyz}
      | leave
    else bad "no effect handler for [Name]{[Args]} of [Me]"
