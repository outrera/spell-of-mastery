use macros unit_flags util

SeenUnits = 0
OwnedUnits = 0
SeenEnemies = 0
PerCycle = 0

unit.advance_to GoalXYZ =
| when $xyz >< GoalXYZ: leave 1
| Path = $path_to{GoalXYZ}
| less Path.size: leave 2
| Moves = map C $reachable: C.1
| Cell = No
| while Path.size and got Moves.find{Path.0}: Cell <= pop Path
| when no Cell:
  | Path = $path_around_to{10 GoalXYZ}
  | while Path.size and got Moves.find{Path.0}: Cell <= pop Path
  | when no Cell:
    | $handled <= 1 //FIXME: this may not be correct
    | leave 2
| B = Cell.block
| when B and not B.handled and not $is_enemy{B}:
  | less $handled:
    | $handled <= \wait //try to avoid swapping
    | leave 0
  | B.backtrack <= B.xyz
| $order_at{Cell.xyz 0}
| 0

unit.ai_pick_target Act =
| R = Act.range
| Targets =
    if R>>9000 then SeenUnits
    else if R><0 then [Me]
    else $site.units_in_range{Me.xyz Act.range}
| Explored = $owner.sight
| Ts = Targets.keep{?ai><unit}.keep{?alive}
| Ts = Ts.keep{T => Explored.(T.xyz.1).(T.xyz.0)>1}
| Hint = Act.hint
//| less Hint >< teleport: leave 0
| if Hint >< heal then
    | Ts1 = Ts.keep{?is_ally{Me}}.keep{?harmed}.skip{?undead}
    | Ts2 = Ts.skip{?is_ally{Me}}.keep{?undead}
    | Ts <= [@Ts1 @Ts2].list
  else if Hint >< lifedrain then
    | less $harmed: leave 0
    | Ts <= Ts.keep{?is_enemy{Me}}.skip{?undead}.skip{?blessed}
  else if Hint >< harm then
    | Ts <= Ts.keep{?is_enemy{Me}}
  else if Hint >< raise then
    | Player = $owner
    | Ts <= $site.active.list.keep{U=>Player.seen{U.xyz}}
                     .keep{(?ai><corpse and not ?removed)}
    | Xs = Ts{T=>[T $main.classes.(T.get{corpse})]}.sort{?1.gold>??1.gold}
    | when Xs.size:
      | G = Xs.0.1.gold
      | Xs <= Xs.skip{?1.gold<G}
    | Ts <= Xs{?0}
  else if Hint >< superpose then
    | less $leader: leave 0
    | less got Ts.keep{?is_enemy{Me}}.find{T=>T.xyz.mdist{$xyz}><1}:
      | leave 0
    | Ts <= Ts.keep{?owner.id><$owner.id}
  else if Hint >< teleport then
    | less $type><unit_devil: leave 0
    | Ts <= Ts.keep{?is_enemy{Me}}.keep{?punish_hp>3}
    | TR = []
    | for T Ts: for C T.cell.neibs{}{?floor}:
      | when C.vacant and T.xyz.2-C.xyz.2 > -1: push C.xyz TR
    | Ts <= TR.keep{T => Act.validate{Me T 0 0}}
    | when Ts.end: 0
    | leave Ts.rand
  else if Hint >< punish then
    | Ts <= Ts.keep{?is_enemy{Me}}.keep{?punish_hp>3}
    | Ts <= Ts.keep{T=>T.xyz.mdist{$xyz}><1}
  else if Hint >< telekinesis then
    | Ts <= Ts.keep{?is_enemy{Me}}.skip{?heavy}.skip{?flyer}
    | TR = []
    | badplace C =
      | CF = C.floor
      | C-CF > 1 or (CF-1).tile.liquid
    | for T Ts.keep{T=>T.xyz.mdist{$xyz}><1}:
      | when badplace T.telepush{0 $xyz -6}: push T TR
    | when TR.end:
      | for T  Ts.skip{T=>T.xyz.mdist{$xyz}><1}:
        | when badplace T.telepush{1 $xyz -6}: push T TR
    | Ts <= TR
  else if Hint >< flight then
    | Ts <= Ts.keep{?is_ally{Me}}.skip{?heavy}.skip{?flyer}
  else if Hint >< benefit then
    | Ts <= Ts.keep{?is_ally{Me}}
  else leave 0
| Ts <= Ts.keep{T => Act.validate{Me T.xyz T 0}}
| for Flag Act.flags //avoid overriding
  | FlagN = getUnitFlagsTable{}.Flag
  | when got FlagN: Ts <= Ts.skip{T => T.flags.bit{FlagN}}
| if Ts.size then Ts.rand else 0

unit.ai_ability_sub Act =
| when Act.mov > $moves: leave 0
| when $cooldown_of{Act.name}: leave 0
| less $owner.enabled{Act} and $earned{Act}: leave 0
| when Act.hint >< dismiss: leave 0
| Target = $ai_pick_target{Act}
| less Target: leave 0 //no suitable target for this act
| Cost = Act.cost
| when $can{Act}
  | if Target.is_unit then $order_act{Act Target}
    else $order_at{Target Act}
  | leave 1
| 0

// for final build do some random-shuffle $acts to make it less predictable
list_rotate I Xs =
| N = Xs.size
| less N: leave Xs
| N <= I%N
| [@Xs.drop{N} @Xs.take{N}]

unit.ai_ability =
| for Act list_rotate{$site.turn $acts}: when $ai_ability_sub{Act}: leave 1
| 0

ai_leader_harmed Me Attacker Victim =

ai.harm Attacker Victim =
| when Victim.leader: ai_leader_harmed Me Attacker Victim

unit.ai_roam =
| Site = $site
| Owner = $owner
| OId = Owner.id
| Us = Site.units_get{$xyz}
| when got Us.find{?ai><hold} and no Us.find{?ai><unhold}: leave 0
| Check = Dst =>
  | MoveIn = 0
  | Vs = Dst.units
  | for V Vs
    | AI = V.ai
    | when AI:
      | Block = Dst.block
      | if AI><unit and Block and Owner.is_enemy{Block.owner}
           and not Block.invisible then
           | MoveIn <= 1
        else if AI><hold and not Block and no Vs.find{?ai><unhold}
           then MoveIn <= 1
        else if AI><avoid then
           | MoveIn <= \block
           | _goto end
        else if AI><block then
           | MoveIn <= \block
           | MoveIn <= 0
           | _goto end
        else
  | _label end
  | MoveIn
| TargetNode = $pathfind{1000 Check}
| less TargetNode: leave 0
| TargetXYZ = TargetNode.xyz
| $backtrack <= 0
| $advance_to{TargetXYZ}
| leave 1

unit.enemies_in_sight =
| $units_in_range{$sight}.keep{X=>$is_enemy{X} and not X.invisible}

unit.ai_runaway Btrack =
| Es = $enemies_in_sight
| Rs = $reachable{}{?1}.skip{?block}
| Best = 0
| BestDist = 0
| for R Rs:
  | Dist = 9000
  | for E Es:
    | Found = $site.closest_reach{$sight Me R E.xyz}
    | Path = if Found then Found.path else []
    | when Path.size<Dist: Dist <= Path.size
  | when BestDist<Dist:
    | BestDist <= Dist
    | Best <= R
| when Best:
  | $order_at{Best.xyz 0}
  | when Btrack: less $get{btrack}: $backtrack <= $xyz
| $handled <= 1

unit.ai_update =
| less $moves > 0:
  | $handled <= 1
  | leave 0
| when $afraid:
  | when $enemies_in_sight.size: $ai_runaway{1}
  | leave 0
| when $ai_ability: leave break
| when $atk:
  | Cs = $reachable
  | case Cs.keep{?0><attack} [[Type Cell]@_]:
    | Block = Cell.block
    | when Block and not Block.invisible:
      | $backtrack <= $xyz
      | $order_at{Cell.xyz 0}
      | leave break
  | when $moves:
    | Es = $enemies_in_sight
    | PursueRange = max $sight 10
    | Flt = Cs{[?1 1]}.table //filtering table
    | Es = Es.skip{E => Flt.(E.cell)><1}
    | EsR = Es.keep{E => $path_to{E.xyz}.size<PursueRange}
    | less EsR.size: EsR <= Es.keep{E => $path_near{E.xyz}.size<PursueRange}
    | case EsR [E@_]:
      | $backtrack <= $xyz
      | $advance_to{E.xyz}
      | less $handled: $handled <= 1
      | leave break
| when $aistate <> roam:
  | BtXYZ = $get{btrack}
  | when BtXYZ and $advance_to{BtXYZ}: $backtrack <= 0
| when $aistate >< roam and $ai_roam: leave break
| $handled <= 1
| \next

ai.update_units =
| for U OwnedUnits: less U.handled:
  | R = U.ai_update
  | when R >< break: leave 0
| for U OwnedUnits: when U.handled><wait:
  | R = U.ai_update //handle units with delayed movement
  | when R >< break: leave 0
| 1 //return true, meaning that we have handled all units

ai.group_roam Types =
| Units = $player.units
| UTs = Units.keep{?aistate><free}.div{?type}
| As = []
| Missing = []
| for T Types:
  if UTs.T^~{[]}.size then push UTs.T^pop As
  else push T Missing
| when Missing.size:
  | PerCycle.missing_attackers <= Missing.flip
  | leave 0
| PerCycle.missing_attackers <= No
| for A As: A.aistate <= \roam
| leave 1

ai.update_turn =
| when $site.turn><0 //ensure human player always gets first turn
       or $update_units:
  | $site.end_turn

ai.update =
| PerCycle <= t
| Player = $player
| SeenUnits <= $site.active.list.keep{U=>Player.seen{U.xyz}}
                     .keep{(?ai><unit and not ?removed)}
| PID = Player.id
| OwnedUnits <= SeenUnits.keep{?owner.id><PID}
| SeenEnemies <= SeenUnits.keep{?owner.is_enemy{Player}}.skip{?invisible}
| $update_turn
| SeenUnits <= 0
| OwnedUnits <= 0
| SeenEnemies <= 0
| PerCycle <= 0

export
