use action macros unit_flags pathfind

HarmMap = dup 256: dup 256: 0

PerCycle = 0

ai.end_turn = $world.end_turn
ai.order_act U Act target/0 = U.order_act{Act target/Target}
ai.order_at_xyz U XYZ = U.guess_order_at{XYZ}

ai.cast_pentagram =
| Leader = $player.leader
| when Leader: case Leader.acts.keep{?hint >< pentagram} [Act@_]
  | when $player.mana < Act.cost: leave 0
  | $order_act{Leader Act}
  | leave 1
| leave 0

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
| $order_act{U Act target/Target}
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

// recasts pentagram, when it doesnt exist or occupied by enemy
ai.update_leader =
| Pentagram = $player.pentagram
| Leader = $player.leader
| less Leader: leave
| Turn = $world.turn
| less Leader and Leader.idle: leave 0
| when cast_spell Me Leader: leave 1
| less Pentagram: leave $cast_pentagram
| 0

ai.remove_blocker Blocker =
| Turn = $world.turn
| less Blocker.idle: leave 0
| Ms = Blocker.list_moves{Blocker.xyz}.keep{?type><move}
| A = if Blocker.attack then #200 else #100
| harmCheck M = 
  | X,Y,Z = M.xyz
  | Harm = HarmMap.X.Y
  | (Harm^^#FF) and (Harm^^#FF00)<A
| Ms <= Ms.skip{&harmCheck} // avoid harm when enemies near pentagram
| when Ms.size
  | $order_at_xyz{Blocker Ms.(Turn%Ms.size).xyz} //move out of the way
  | leave 1
| Ms = Blocker.list_moves{Blocker.xyz}.keep{?type><swap}
| for M Ms
  | B = $world.block_at{M.xyz}
  | when B.leader
    | Ms = B.list_moves{B.xyz}.keep{?type><move}
    | when Ms.size
      | $order_at_xyz{B Ms.(Turn%Ms.size).xyz} //move out of the way
      | leave 1

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

ai.update_pentagram =
| Pentagram = $player.pentagram
| less Pentagram: leave 0
| Blocker = $world.block_at{Pentagram.xyz}
| when got Blocker: leave 0
| Summons = Pentagram.acts.keep{?after_table.summon^got}
| less Summons.size: leave 0
| Missing = PerCycle.missing
| less got Missing: leave
| for Type Missing:
  | S = Summons.find{?after_table.summon >< Type}
  | Turn = $world.turn
  | when got S and $player.research_remain{S} >< 0:
    | when Pentagram.idle and S.cost<<$player.mana:
      | $order_act{Pentagram S}
      | leave 1
| 0

ai.roam_with Radius U =
| World = $world
| Owner = U.owner
| OId = Owner.id
| allows_attack M = M.type >< move
                    and U.list_moves{M.xyz}.keep{?type><attack}.size
| Ms = U.list_moves{U.xyz}.keep{&allows_attack}
| when Ms.size:
  | Dst = Ms{M=>[(M.xyz-U.xyz).abs M]}.sort{?0<??0}.0.1
  | $order_at_xyz{U Dst.xyz}
  | leave 1
| Blockers = []
| block XYZ =
  | B = World.alloc_unit{unit_block owner/U.owner}
  | B.move{XYZ}
  | push B Blockers
| free_blockers = for B Blockers: B.free
| Player = $player
| PentXYZ = if Player.pentagram then Player.pentagram.xyz else [-100 -100 -100]
| when Radius: less (PentXYZ-U.xyz).all{?abs<Radius}: leave 0
| Check = Dst =>
  | MoveIn = 0
  | Vs = World.units_at{Dst.xyz}
  | for V Vs
    | AI = V.ai
    | when AI:
      | Blocked = World.block_at{Dst.xyz}
      | Enemy = Owner.is_enemy{V.owner}
      | if AI><unit and Enemy then MoveIn <= 1
        else if AI><hold and no Blocked and no Vs.find{?ai><unhold}
           then MoveIn <= 1
        else if Dst.type><swap and V.summoned and (U.xyz-Dst.xyz).take{2}.all{?.abs<2}
           then
           | block Dst.xyz
           | Dst.type <= 0
        else if AI><turret and no Blocked then MoveIn <= 1
        else if AI><pentagram and Enemy then MoveIn <= 1
        else if AI><avoid and no Blocked then
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
| TargetNode = U.pathfind{1 Check}
| less TargetNode:
  | free_blockers
  | leave 0
| TargetXYZ = TargetNode.1
| Target = $world.block_at{TargetXYZ}
| EnemyTarget = got Target and Target.owner.id <> OId
| XYZ = TargetNode^node_to_path.0
| Turn = $world.turn
| Ms = U.list_moves{U.xyz}
| free_blockers
| when EnemyTarget and (XYZ-Target.from).all{?abs << 1}:
  | M = Ms.find{?xyz >< Target.from}
  | when got M:
    | $order_at_xyz{U M.xyz}
    | leave 1
| M = Ms.find{?xyz >< XYZ}
| less got M: leave 0
| $order_at_xyz{U M.xyz}
| leave 1

ai.update_units Units =
| Player = $player
| Pentagram = Player.pentagram
| Leader = Player.leader
| PentID = 0
| PentXYZ = [-1 -1 -1]
| LeaderID = 0
| when Leader: LeaderID <= Leader.id
| when Pentagram:
  | PentID <= Pentagram.id
  | PentXYZ <= Pentagram.xyz
| when Player.params.attack_with_guards >< 1:
  | for U Units: U.attacker <= 1
  | Player.params.attack_with_guards <= 0
| for U Units: when U.idle: less U.path:
  | Os = $world.units_at{U.xyz}
  | AttackTrigger = Os.find{?ai><attack}
  | when got AttackTrigger and U.ai<>attack:
    | U.attacker <= 1
    | Os = Os.skip{?ai><attack}
    | AttackTrigger.free
  | Path = U.path
  | less Path.end
    | XYZ = Path.head.unheap
    | U.path <= Path.heapfree1
    | $order_at_xyz{U XYZ}
    | leave 1
  | Attacker = U.attack and U.attacker
  | less Player.human
    | when Attacker:
      | when no Os.find{?ai><hold} or got Os.find{?ai><unhold}:
        | when $roam_with{0 U}: leave 1
    | less Attacker:
      | when U.id >< LeaderID: when $update_leader: leave 1
      | when U.id >< PentID: when $update_pentagram: leave 1
      | when U.summoned:
        | when $roam_with{4 U}: leave 1
    | when U.xyz >< PentXYZ and U.id <> PentID:
      | when $remove_blocker{U}: leave 1
| leave 0

ai.harm Attacker Victim =
| Victim.attacker <= 1 //have to be aggressive

ai.group_attack Types =
| Units = $player.active
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
| when PParams.aiLastWait >< $world.turn: leave 0
| Params = $main.params
| when PParams.aiWait > 0:
  | PParams.aiLastWait <= $world.turn
  | !PParams.aiWait-1
  | leave 0
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
  [wait Turns]
    | less Turns.is_int
      | case Turns
        [`*` difficulty N] | Turns <= Player.params.difficulty*N
        Else | bad "AI: wrong arg for `wait`: [Turns]"
    | PParams.aiWait <= Turns
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
| PID = Player.id
| Pentagram = Player.pentagram
| Params = $main.params
| Units = Player.active
| less Player.human
  | Player.mana <= 100000
  | Player.lore <= 9000
  | while $script><1:
| target_priority U X =
  | B = $world.block_at{X.xyz}
  | B.health - B.hits - max{1 U.attack-B.defense}
| for U Units: // check if we can attack someone
  | Ms = U.list_moves{U.xyz}.keep{?type >< attack}
  | Ms = Ms.sort{A B => target_priority{U A}<target_priority{U B}}
  | case Ms [A@_]
    | U.attacker <= 1
    | $order_at_xyz{U A.xyz}
    | leave
| for Xs HarmMap: for I Xs.size: Xs.I <= 0
| for U Units{U=>U.list_attack_moves{U.xyz}}.join:
  | XYZ = U.xyz
  | !HarmMap.(XYZ.0).(XYZ.1) + #100 // mark where allies can attack
| isEnemy U = U.owner.id <> PID and U.health and not U.removed
| Es = $world.active.list.keep{&isEnemy}
| Ts = Es{U=>U.list_attack_moves{U.xyz}{[U ?]}}.join //threatened map cells
| for U,T Ts
  | XYZ = T.xyz
  | X,Y,Z = XYZ
  | O = U.owner
  | if U.ranged then HarmMap.X.Y <= #1
    else !HarmMap.X.Y + #1
| Ts <= Ts{?1}
| for U Units: when U.attack:
  | X,Y,Z = U.xyz
  | Harm = HarmMap.X.Y
  | when Harm^^#FF and no $world.units_at{U.xyz}.find{?ai><unhold}:
    | U.attacker <= 1
    | UH = $world.alloc_unit{trigger_unhold}
    | UH.move{U.xyz}
| Quit = $update_units{Units}
| when Quit: leave
| less Player.human: $update_research
| less Player.human: for U Units
  | X,Y,Z = U.xyz
  | Harm = HarmMap.X.Y
  | when Harm^^#FF:
    | Moves = U.list_moves{U.xyz}.keep{?type><move}
    | SafeMoves = Moves.skip{M=>| XYZ = M.xyz; Ts.any{?xyz><XYZ}}
    | when SafeMoves.size //avoid harm
      | $order_at_xyz{U SafeMoves.(($world.turn+U.id)%SafeMoves.size).xyz}
      | leave // using SafeMoves.rand will complicate debug
| $params.aiLastTurn <= $world.turn
| less Player.human: $end_turn

ai.update =
| PerCycle <= t
| ai_update Me
| PerCycle <= 0


export