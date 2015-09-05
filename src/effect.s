use util effect_

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
  | for Id Players: Es <= Es.set{Id State}
  | Act.enabled <= Es

effect enable State Players ActNames:
| when Players >< owner: Players <= [$owner.id] 
| when Players >< target_owner: Players <= [Target.owner.id]
| set_act_enabled $main State Players ActNames

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
  | Player.reasearch_boost{ActName 99999999}

effect latency Time:
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

effect harm Damage: Target.harm{Me Damage}

effect paralyze Time: Target.moved <= $world.turn+Time

effect haste Whom:
| if Target.moved>>$world.turn
  then Target.moved <= $world.turn-1
  else Target.haste <= 1

effect shell Whom: Target.shell <= 1

effect notify Text: Target.owner.notify{Text}

effect msg Title @Body: $main.show_message{Title Body.text{' '}}

effect mana Amount: !Target.owner.mana+Amount

effect flyer State: Target.flyer <= State

// sets world param
effect set @Pairs:
| Params = $world.params
| for Name,Value Pairs.group{2}
  | when Value >< `?owner`: Value <= $owner.id
  | when Value >< `?self`: Value <= $id
  | when Value >< `?self_type`: Value <= $type
  | if Value.is_list
    then | when no Params.Name:
           | Params.Name <= dup Value.size
         | Params.Name.init{Value}
    else Params.Name <= Value

// sets player param
effect pset PlayerId @Pairs:
| when PlayerId >< owner: PlayerId <= $owner.id
| Ps = if PlayerId >< all then $world.players{}{?id} else [PlayerId]
| for PlayerId Ps
  | P = $world.players.PlayerId
  | Params = P.params
  | for Name,Value Pairs.group{2}
    | when Value >< `?owner`: Value <= $owner.id
    | when Value >< `?self`: Value <= $id
    | when Value >< `?self_type`: Value <= $type
    | if Value.is_list
      then | when no Params.Name:
             | Params.Name <= dup Value.size
           | Params.Name.init{Value}
      else Params.Name <= Value
    | when Name >< mana: P.mana <= Value

effect guards_to_attackers PlayerId:
| for U $world.players.PlayerId.units: U.attacker <= 1

effect swap Arg:
| XYZ = $xyz.copy
| Target.remove
| $move{TargetXYZ}
| Target.move{XYZ}

effect remove Whom: case Whom
  target | Target.free
  self | Me.free
  X,Y,Z | U = $world.block_at{X,Y,Z}
        | when got U: U.free
  Serial | U = $world.units.find{?serial><Serial}
         | when got U and U.xyz.2<>-1: U.free

effect clear What:
| XYZ = case What
  target | TargetXYZ
  X,Y,Z | X,Y,Z
| when no XYZ: bad "effect clear: invalid target ([What])"
| $world.clear_tile{XYZ}

effect summon What:
| NoPick = 0
| case What nopick,W:
  | NoPick <= 1
  | What <= W
| S = $world.alloc_unit{What owner/$owner}
| S.summoned <= 1
| S.move{TargetXYZ}
| less NoPick: S.world.update_pick{[S]}

effect teleport Arg: $forced_order{type/teleport at/TargetXYZ}

effect research Amount:
| !Target.owner.mana + Target.owner.reasearch_boost{0 Amount}

effect victory Player Reason:
| WP = $world.params
| when Player >< owner: Player <= $owner.id
| WP.winner <= Player
| WP.victory_type <= Reason

unit.effect Effect Target TargetXYZ =
| case Effect [when,When @Es]
  | when When><ally: when $owner.is_enemy{Target.owner}: leave
  | when When><enemy: less $owner.is_enemy{Target.owner}: leave
  | when When><confirmed: less $main.dialog_result><yes: leave
  | Effect <= Es
| case Effect [target,alive @Effect]
  | for U $world.active: when U.alive: $effect{Effect U U.xyz}
  | leave
| for Name,Args Effect
  | F = Effects.Name
  | when no F: bad "no effect handler for [Name]{[Args]}"
  | F{Me Target TargetXYZ Args}
