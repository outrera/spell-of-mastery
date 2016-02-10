use macros unit_flags pathfind util

PerCycle = 0

world.targets_in_range Center R =
| Targets = []
| Points = points_in_circle R
| for X,Y Points
  | XYZ = Center+[X Y 0]
  | X = XYZ.0
  | Y = XYZ.1
  | when X>0 and X<<$w and Y>0 and Y<<$h:
    | for U $column_units_at{X Y}: when $seen_from{Center U.xyz}:
      | push U Targets
| Targets

cast_spell_sub Me Offensive =
| SpellType = if Offensive then \aiOffensiveSpell else \aiDefensiveSpell
| SpellName = $owner.params.SpellType
| when no SpellName: leave 0
| Act = $main.params.acts.SpellName
| when no Act: bad "AI: cant find SpellType `[SpellName]`"
| Targets = $world.targets_in_range{Me.xyz Act.range}
| Ts = Targets.skip{?empty}
| if Offensive
  then Ts <= Ts.keep{?owner.id<>$owner.id}
  else Ts <= Ts.keep{?owner.id><$owner.id}
| Ts = Ts.keep{?alive}
| case SpellName //FIXME: spells actions should have `can do` method
  cast_shell
    | FlagN = getUnitFlagsTable{}.shell
    | Ts <= Ts.skip{T => T.flags^get_bit{FlagN}}
| less Ts.size: leave 0
| Target = Ts.0
| Cost = Act.cost
| !Me.owner.mana+Cost
| $order_act{Act target/Target}
| 1

cast_spell Me =
| PP = $owner.params
| Cycle = $world.cycle
| when PP.aiSpellWait>>Cycle /*and Cycle>10000*/: leave 0
| AT = $owner.params.aiType
| when cast_spell_sub{Me 1} or cast_spell_sub{Me 0}:
  | D = max 1 10-PP.difficulty
  | PP.aiSpellWait <= Cycle+D*24
  | leave 1
| 0

unit.can_do Act =
| when $owner.research_remain{Act}: leave 0
| when $owner.mana < Act.cost: leave 0
| when $cooldown_of{Act.name}: leave 0
| 1

cast_pentagram Me =
| case $acts.keep{?hint >< pentagram} [Act@_]
  | less $can_do{Act}: leave 0
  | $order_act{Act}
  | leave 1
| leave 0

// recasts pentagram, when it doesnt exist or occupied by enemy
update_leader Me =
| less $idle: leave
| Pentagram = $owner.pentagram
| less Pentagram: // if enemies are near, attacking them could do better results
  | when cast_pentagram Me: leave
| when cast_spell Me: leave


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
      | if AI><unit and got Block and Owner.is_enemy{Block.owner} then
           | MoveIn <= 1
        else if AI><hold and no Block and no Vs.find{?ai><unhold}
           then MoveIn <= 1
        else if AI><turret and no Block then MoveIn <= 1
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
| Pentagram = Player.pentagram
| Leader = Player.leader
| LeaderID = if Leader then Leader.id else 0
| PentID = if Pentagram then Pentagram.id else 0
| when Player.params.attack_with_guards >< 1:
  | for U Units: U.attacker <= 1
  | Player.params.attack_with_guards <= 0
| for U Units: when U.idle and not U.goal:
  | Handled = 0
  | Os = $world.units_at{U.xyz}
  | AttackTrigger = Os.find{?ai><attack}
  | when got AttackTrigger and U.ai<>attack:
    | U.attacker <= 1
    | Os = Os.skip{?ai><attack}
    | AttackTrigger.free
  | Attacker = U.damage and U.attacker
  | when Attacker:
    | when no Os.find{?ai><hold} or got Os.find{?ai><unhold}:
      | Handled <= roam U
  | less Handled:
    | when U.id >< LeaderID: update_leader U
    | when U.id >< PentID: ai_update_build Me
    //| when U.nonguard: roam U radius/4
| leave 0

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
  | Cycle = $world.cycle
  | PParams = $player.params
  | LHC = $params.aiLeaderHarmCycle
  | when LHC+24*120>Cycle:
    | when Attacker: for U $player.units: when U.damage and U.idle:
      | U.order_at{Attacker.xyz}
    | leave
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