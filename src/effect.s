use util

set_act_enabled Me State Players ActNames =
| Acts = $params.acts
| for ActName ActNames:
  | Act = Acts.ActName
  | less got Act: bad "missing act [ActName]"
  | Es = Act.enabled
  | for Id Players: Es <= Es.set{Id State}
  | Act.enabled <= Es

unit.effect Effect Target TargetXYZ =
| case Effect [target,alive @Effect]
  | for U $world.active: when U.alive: $effect{Effect U U.xyz}
  | leave
| case Effect.find{?0><when} _,When:
  | when When><ally: when $owner.is_enemy{Target.owner}: leave
  | when When><enemy: less $owner.is_enemy{Target.owner}: leave
  | when When><confirmed: less $main.dialog_result><yes: leave
| case Effect.find{?0><enable} _,[State Players ActNames]:
  | when Players >< owner: Players <= [$owner.id] 
  | when Players >< target_owner: Players <= [Target.owner.id]
  | when Players >< all: Players <= 16{(?)}
  | when ActNames >< all: ActNames <= $main.params.acts{}{?0}
  | when Players.is_int: Players <= [Players]
  | when ActNames.is_text: ActNames <= [ActNames]
  | set_act_enabled $main State Players ActNames
| case Effect.find{?0><explore} _,[Player State]:
  | $world.explore{State}
| case Effect.find{?0><confirm} _,[Title Text]:
  | $main.show_message{Title buttons/[yes,'Yes' no,'No'] Text}
| case Effect.find{?0><animate} _,Anim: $animate{Anim}
| case Effect.find{?0><impact} _,Impact: $world.effect{TargetXYZ Impact}
| case Effect.find{?0><effect} _,Effect: $world.effect{$xyz Effect}
| case Effect.find{?0><sound} _,Sound: $main.sound{Sound}
| case Effect.find{?0><harm} _,Damage: Target.harm{Me Damage}
| case Effect.find{?0><notify} _,Text: Target.owner.notify{Text}
| case Effect.find{?0><msg} _,[Title @Body]:
  | $main.show_message{Title Body.text{' '}}
| case Effect.find{?0><mana} _,Amount: !Target.owner.mana+Amount
| case Effect.find{?0><set} _,Pairs
  | WP = $world.params
  | for Name,Value Pairs.group{2}
    | when Value >< `?owner`: Value <= $owner.id
    | when Value >< `?self`: Value <= $id
    | when Value >< `?self_type`: Value <= $type
    | if Value.is_list
      then | when no WP.Name:
             | WP.Name <= dup Value.size
           | WP.Name.init{Value}
      else WP.Name <= Value
| case Effect.find{?0><gain} _,Type:
  | when Target.owner.human:
    | Title = Type.replace{'_' ' '}
    | $main.show_message{'Knowledge Gained'
       "The secret knowledge of [Title] has been revealed"}
  | Target.owner.reasearch_boost{Type 99999999}
| case Effect.find{?0><swap} _,Arg:
  | XYZ = $xyz.copy
  | Target.remove
  | $move{TargetXYZ}
  | Target.move{XYZ}
| case Effect.find{?0><remove} _,Whom: case Whom
  target | Target.free
  self | Me.free
| case Effect.find{?0><summon} _,What:
  | NoPick = 0
  | case What nopick,W:
    | NoPick <= 1
    | What <= W
  | S = $world.alloc_unit{What owner/$owner}
  | S.attacker <= 1 // mark it available for attack
  | S.move{TargetXYZ}
  | less NoPick: S.world.update_pick{[S]}
| case Effect.find{?0><teleport} _,Arg:
  | $forced_order{type/teleport at/TargetXYZ}
| case Effect.find{?0><research} _,Amount:
  | !Target.owner.mana + Target.owner.reasearch_boost{0 Amount}
| case Effect.find{?0><victory} _,[Player Reason]:
  | WP = $world.params
  | when Player >< owner: Player <= $owner.id
  | WP.winner <= Player
  | WP.victory_type <= Reason
| case Effect.find{?0><guards_to_attackers} _,PlayerId:
  | for U $world.players.PlayerId.units: U.attacker <= 1
