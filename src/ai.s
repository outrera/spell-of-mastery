use macros unit_flags pathfind util

PerCycle = 0

unit.can_do Act =
| when $owner.research_remain{Act}: leave 0
| when $owner.mana < Act.cost: leave 0
| when $cooldown_of{Act.name}: leave 0
| 1

cast_spell_sub Me Spell =
| less Spell and got Spell: leave 0
| Act = Spell
| when Act.is_text:
  | Act <= $main.params.acts.Spell
  | when no Act: bad "AI: cant find spell `[Spell]`"
| Hint = Act.hint
| less Hint: leave 0
| when Act.name><attack: leave 0
| R = Act.range
| Targets =
    if R>>9000 then $world.active.list.skip{?removed}
    else if R><0 then [Me]
    else $world.targets_in_range{Me.xyz Act.range}
| Ts = Targets.skip{?empty}.keep{?alive} //.skip{?invisible}
| if Act.hint><harm
  then Ts <= Ts.keep{?owner.id<>$owner.id}
  else Ts <= Ts.keep{?owner.id><$owner.id}
| when Act.affects<>unit:
  | case Act.affects [[@As] _]
    | for A As: case A
      non_leader | Ts <= Ts.skip{?leader><1}
      outdoor | Ts <= Ts.keep{U => $world.outdoor{U.xyz}}
| for Flag Act.flags //avoid overriding
  | FlagN = getUnitFlagsTable{}.Flag
  | when got FlagN: Ts <= Ts.skip{T => T.flags^get_bit{FlagN}}
| less Ts.size: leave 0
| Target = Ts.0
| Cost = Act.cost
| !Me.owner.mana+Cost
| when $can_do{Act}
  | $order_act{Act target/Target}
  | leave 1
| !Me.owner.mana-Cost //havent casted the spell
| 0

cast_spell Me =
| Acts = $acts
| less Acts.size: leave 0
| when $ai >< pentagram
  | when $owner.mana>500: ai_update_build $owner.ai
  | leave 1
| PP = $owner.params
| when $leader:
  | Pentagram = $owner.pentagram
  | less Pentagram: // if enemies are near, attacking them could do better results
    | when cast_pentagram Me: leave 1
  | when PP.aiCastFlight:
    | when cast_spell_sub{Me cast_flight}:
      | PP.aiCastFlight <= 0 //wake up all units that previously could reach goal
      | leave 1
  | Cycle = $world.cycle
  | when PP.aiSpellWait>>Cycle /*and Cycle>10000*/: leave 0
  | for Act PP.ai_spells
    | when cast_spell_sub{Me Act}:
      | D = max 1 10-PP.difficulty
      | PP.aiSpellWait <= Cycle+D*24
      | leave 1
  | leave 0
| for Act Acts: when cast_spell_sub{Me Act}: leave 1
| 0

cast_pentagram Me =
| case $acts.keep{?hint >< pentagram} [Act@_]
  | less $can_do{Act}: leave 0
  | $order_act{Act}
  | leave 1
| leave 0

ai.update_research =
| P = $player
| Pentagram = P.pentagram
| less Pentagram: leave 0
| Spawns = Pentagram.acts.keep{?after_table.spawn^got}
| less Spawns.size: leave 0
| Missing = PerCycle.missing
| less got Missing: leave
| for Type Missing:
  | S = Spawns.find{?after_table.spawn >< Type}
  | less got S: $world.notify{"AI: missing spawn `[Type]`"}
  | when got S and P.research_remain{S} > 0:
    | when S.lore.0<<P.lore and S.lore.1 << P.mana:
      | !P.lore-S.lore.0
      | !P.mana-S.lore.1
      | P.research_item{S.name}
      | leave 1
| 0

ai_update_build Me =
| Pentagram = $player.pentagram
| less Pentagram: leave 0
| Spawns = Pentagram.acts.keep{?after_table.spawn^got}
| less Spawns.size: leave 0
| Missing = PerCycle.missing
| less got Missing: leave
| for Type Missing:
  | S = Spawns.find{?after_table.spawn >< Type}
  | when got S and Pentagram.can_do{S}:
    | Pentagram.order_act{S}
    | leave 1
| 0

roam Me =
| World = $world
| Owner = $owner
| OId = Owner.id
| Blockers = []
| block XYZ =
  | B = Owner.alloc_unit{unit_block}
  | B.move{XYZ}
  | push B Blockers
| free_blockers = for B Blockers: B.free
| Check = Dst =>
  | MoveIn = 0
  | Vs = World.units_at{Dst.xyz}
  | for V Vs
    | AI = V.ai
    | when AI:
      | Block = World.block_at{Dst.xyz}
      | if AI><unit and got Block and Owner.is_enemy{Block.owner}
           and not Block.invisible then
           | MoveIn <= 1
        else if AI><hold and no Block and no Vs.find{?ai><unhold}
           then MoveIn <= 1
        else if AI><pentagram and Owner.is_enemy{V.owner} then
           | when no Block or Owner.is_enemy{Block}: MoveIn <= 1
        else if AI><avoid and no Block then
           | block Dst.xyz
           | Dst.type <= 0
           | MoveIn <= 0
        else if AI><block then
           | Dst.type <= 0
           | MoveIn <= 0
           | _goto end 
        else
  | _label end
  | MoveIn
| TargetNode = $pathfind{1000 Check}
| less TargetNode:
  | free_blockers
  | leave 0
| TargetXYZ = TargetNode.1
| $backtrack <= 0
| $order_at{TargetXYZ}
| leave 1

ai.update_units Units =
| Player = $player
| when Player.params.attack_with_guards >< 1:
  | for U Units: U.attacker <= 1
  | Player.params.attack_with_guards <= 0
| for U Units:
  | if U.idle and not U.goal then
     | Handled = cast_spell U
     | less Handled:
       | Attacker = U.damage and U.attacker
       | when Attacker:
         | Os = U.world.units_at{U.xyz}
         | when no Os.find{?ai><hold} or got Os.find{?ai><unhold}:
           | Handled <= roam U
           | less Handled or U.flyer: //casting flight is required?
             | PP = Player.params
             | when PP.aiCastFlightCycle+(60*24*4)<$world.cycle:
               | PP.aiCastFlight <= 1
               | PP.aiCastFlightCycle <= $world.cycle
    else
     | when U.type><unit_spider and U.goal.is_unit: //FIXME: hack
       | G = U.goal
       | when got G.child{effect_poison}:
         | Ts = U.targets_in_range{1}.skip{?.child{effect_poison}^got}
         | Ts = Ts.skip{?empty}
         | Ts = Ts.keep{?is_enemy{U}}
         | when Ts.size: U.order_at{Ts.0.xyz}
| 0

//when leader is too far from pentagram, just teleport leader back to it
// after units get teleported, order them to attack
ai.harm Attacker Victim =
| when Victim.leader><1:
  | Pent = Victim.owner.pentagram
  | when Pent and (Pent.xyz-Victim.xyz).abs>>5.0:
    | Victim.order_act{recall target/Victim}
    | leave
  | when Attacker:
    | R = Attacker.range
    | when R><cross or R><1 or (Attacker.xyz-Victim.xyz).abs<2.0:
        | F = Victim.find{8
          | D => (D.xyz-Attacker.xyz).abs >> 2.0
                 and (D.xyz-Victim.xyz).abs < 3.0}
        | when F: Victim.order_at{F}
  | when Pent:
    | SAct = $main.params.acts.summon_blob
    | when Pent.can_do{SAct}: Pent.order_act{SAct}
  | Cycle = $world.cycle
  | PParams = $player.params
  | LHC = $params.aiLeaderHarmCycle
  | when LHC+24*120>Cycle:
    | when Attacker: for U $player.units: when U.damage and U.idle:
      | U.order_at{Attacker.xyz}
    | leave
  | Bonus = max 0 LHC
  | !$player.mana + ((Cycle-Bonus)/24*$main.params.ai.leader_defense_bonus)
  | $params.aiLeaderHarmCycle <= Cycle
  | for U $player.units: when U.id <> Victim.id: when U.speed:
    | U.attacker <= 1
    | U.order_act{recall target/U}

ai.group_attack Types =
| Units = $player.units
| UTs = Units.keep{U => not U.attacker and U.nonguard}.div{?type}
| As = []
| Missing = []
| for T Types:
  if UTs.T^~{[]}.size then push UTs.T^pop As
  else push T Missing
| when Missing.size:
  | PerCycle.missing <= Missing.flip
  | leave 0
| PerCycle.missing <= No
| for A As: A.attacker <= 1
| leave 1

ai.script =
| Player = $player
| PParams = Player.params
| Params = $main.params
| when $world.cycle < PParams.aiWait: leave 0
| AIType = PParams.aiType
| AIStep = PParams.aiStep
| AISteps = Params.main.ai.AIType
| less got AISteps
  | $world.notify{"AI: missing type `[AIType]`"}
  | leave 0
| AISteps = AISteps.tail
| less AIStep<AISteps.size:
  | AIStep <= 0
  | PParams.aiStep <= 0
| Command = AISteps.AIStep
| case Command
  [attack @Types]
    | less $group_attack{Types{"unit_[?]"}}: leave 0
    | !PParams.aiStep+1
  [wait Cycles]
    | PParams.aiWait <= $world.cycle+Cycles
    | !PParams.aiStep+1
  [goto NewAIType when @Condition]
    | if case Condition [[`>>` lossage X]]
              Player.params.lossage+PParams.difficulty*2>>X
      then | PParams.aiType <= NewAIType
           | PParams.aiStep <= 0
      else | !PParams.aiStep+1
  [goto NewAIType]
    | PParams.aiType <= NewAIType
    | PParams.aiStep <= 0
  [set Var Value]
    | PParams.Var <= Value
    | !PParams.aiStep+1
  Else
    | bad 'invalid AI command: [Command]'
| leave 1

ai_update Me =
| Player = $player
| Player.lore <= 9000
| when Player.id: while $script><1:
| Quit = $update_units{Player.units}
| when Quit: leave
//| $update_research

ai.update =
| PerCycle <= t
| ai_update Me
| PerCycle <= 0


export