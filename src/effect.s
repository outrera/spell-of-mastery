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

effect add_item Amount Name: Target.add_item{Amount Name}

effect mod Arg: Target.mod <= Arg

effect add_moves N: bad "effect.s: add_moves is obsolete"

metric A B = (B-A).take{2}.abs

effect btrack XYZ:
| less $idle:
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

effect cooldown Time:
| ActName = $action.name
| !$owner.research.ActName + Time

effect explore Player State: $world.explore{State}

effect confirm Title Text:
| $main.show_message{Title buttons/[yes,'Yes' no,'No'] Text}

effect animate Anim: $animate{Anim}

effect impact Impact: $world.effect{TargetXYZ Impact}

effect effect Effect: $world.effect{$xyz Effect}

SoundPlayedCycle = 0
SoundPlayedTurn = 0
effect sound Sound:
| when SoundPlayedCycle >< $world.cycle and SoundPlayedTurn >< $world.turn:
  | leave
| when not $id or (not $removed and $world.human.explored{$xyz}>1):
  | $main.sound{Sound}
  | SoundPlayedCycle <= $world.cycle
  | SoundPlayedTurn <= $world.turn

effect harm As:
| Damage = 1
| Whom = \target
| case As
  [D W] | Damage <= D
        | Whom <= W
  D | Damage <= D
| T = case Whom target(Target) self(Me) Else(bad "harm recipient `[Whom]`")
| T.harm{Me Damage}

effect suicide As:
| Target.harm{Me Target.attack}

effect paralyze Time: bad "effect.s: paralyze is obsolete"

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

effect call Arg:
| XYZ = $xyz.copy
| when got $world.block_at{XYZ}: leave
| Target.remove
| Target.move{XYZ}

effect remove Whom: case Whom
  target | Target.free
  self | Me.free
  X,Y,Z | U = $world.block_at{X,Y,Z}
        | when got U: U.free
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

effect summon What:
| NoPick = 0
| case What nopick,W:
  | NoPick <= 1
  | What <= W
| S = $owner.alloc_unit{What}
| S.summoned <= 1
| S.alpha <= 255
| S.delta <= -50
| S.move{TargetXYZ}

effect caster Who:
| Leader = $owner.leader
| less Who >< leader and Leader: leave
| Leader.animate{attack}
| Leader.face{TargetXYZ}

effect teleport Arg: $forced_order{type/teleport at/TargetXYZ}

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

unit.effect Effect Target TargetXYZ =
| case Effect [on,When @Es]: Effect <= Es
| case Effect [when,When @Es]
  | Cs = if When.is_list and not When.end and When.0<>`.` then When else [When]
  | for C Cs: case C
    ally | when $owner.is_enemy{Target.owner}: leave
    enemy | less $owner.is_enemy{Target.owner}: leave
    confirmed | less $main.dialog_result><yes: leave
    harmed | less $health<>$class.hp: leave
    [`.` has_health A] | less $health>>A: leave
    [`.` has_mana A] | less $owner.mana>>A: leave
    sinner | less Target.kills>0: leave
  | Effect <= Es
| case Effect [target,alive @Effect]
  | for U $world.active: when U.alive: $effect{Effect U U.xyz}
  | leave
| for Name,Args Effect
  | F = Effects.Name
  | when no F: bad "no effect handler for [Name]{[Args]}"
  | F{Me Target TargetXYZ Args}
