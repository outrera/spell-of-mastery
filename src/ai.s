use action macros unit_flags pathfind

PerCycle = 0

cast_spell_sub Me U Offensive =
| less Offensive:
  | Pentagram = U.owner.pentagram
  | less Pentagram: leave 0
  | when Pentagram.xyz >< U.xyz: leave 0
| SpellType = if Offensive then \aiOffensiveSpell else \aiDefensiveSpell
| SpellName = $player.params.SpellType
| when no SpellName: leave 0
| Act = $main.params.acts.SpellName
| when no Act: bad "AI: cant find SpellType `[SpellName]`"
| Targets,Path = action_list_moves U Act
| Ts = Targets{XYZ=>$world.block_at{XYZ}}.skip{No}
| if Offensive
  then Ts <= Ts.keep{?owner.id<>$player.id}
  else Ts <= Ts.keep{?owner.id><$player.id}
| case SpellName //FIXME: spells actions should have `can do` method
  cast_shell
    | FlagN = getUnitFlagsTable{}.shell
    | Ts <= Ts.skip{T => T.flags^get_bit{FlagN}}
| less Ts.size: leave 0
| Target = Ts.($world.turn%Ts.size)
| U.order_act{Act target/Target}
| 1

cast_spell Me U =
| PP = $player.params
| Turn = $world.turn
| when PP.aiSpellWait>>Turn and Turn>48: leave 0
| AT = $player.params.aiType
| when cast_spell_sub{Me U 1} or cast_spell_sub{Me U 0}:
  | D = max 0 PP.difficulty-2
  | PP.aiSpellWait <= Turn+D
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
//| when cast_spell $owner Me: leave


ai.update_research =
| P = $player
| Pentagram = P.pentagram
| less Pentagram: leave 0
| Summons = Pentagram.acts.keep{?after_table.summon^got}
| less Summons.size: leave 0
| Missing = PerCycle.missing
| less got Missing: leave
| for Type Missing:
  | S = Summons.find{?after_table.summon >< Type}
  | less got S: $world.notify{"AI: missing summon `[Type]`"}
  | when got S and P.research_remain{S} > 0 and S.research<<P.lore:
    | !P.lore-S.research
    | P.research_item{S.name}
    | leave 1
| 0

ai_update_build Me =
| Pentagram = $player.pentagram
| less Pentagram: leave 0
| Summons = Pentagram.acts.keep{?after_table.summon^got}
| less Summons.size: leave 0
| Missing = PerCycle.missing
| less got Missing: leave
| for Type Missing:
  | S = Summons.find{?after_table.summon >< Type}
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
      | if AI><unit and Owner.is_enemy{Block.owner} then MoveIn <= 1
        else if AI><hold and no Block and no Vs.find{?ai><unhold}
           then MoveIn <= 1
        else if AI><turret and no Block then MoveIn <= 1
        else if AI><pentagram and Owner.is_enemy{V.owner} then MoveIn <= 1
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
  | Attacker = U.attack and U.attacker
  | when Attacker:
    | when no Os.find{?ai><hold} or got Os.find{?ai><unhold}:
      | Handled <= roam U
  | less Handled:
    | when U.id >< LeaderID: update_leader U
    | when U.id >< PentID: ai_update_build Me
    //| when U.summoned: roam U radius/4
| leave 0

ai.harm Attacker Victim =
| Victim.attacker <= 1 //have to be aggressive

ai.group_attack Types =
| Units = $player.units
| UTs = Units.keep{U => not U.attacker and U.summoned}.div{?type}
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
    | less Cycles.is_int
      | case Cycles
        [`*` difficulty N] | Cycles <= Player.params.difficulty*N
        Else | bad "AI: wrong arg for `wait`: [Cycles]"
    | PParams.aiWait <= $world.cycle+Cycles
    | !PParams.aiStep+1
  [goto NewAIType when @Condition]
    | if case Condition [[`>>` lossage X]] Player.params.lossage>>X
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
| Player.mana <= 100000
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