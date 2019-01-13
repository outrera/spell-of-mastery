use util macros act_

type act{name title/0 icon/No hotkey/0 tier/1 gold/0 maxPicks/3 pickChance/50
         hint/0 tab/0 kind/0
         cost/0 mov/1 fatigue/1 cool/0 needs/[] needsGene/[]
         priority/50
         range/0 zfree/0
         speed/4 delay/0 animate/No repeat/0
         menu/0 onMenu/0
         check/unit onInit/[] onHit/OnHit onEnd/[]}
  title/Title
  icon/Icon
  hotkey/Hotkey //keyboard shortcut
  hint/Hint //hint for AI: harm (single unit), harm_all (all units)
            //             boost(single unit), boost_allies(all allies),
            //             heal_allies, morph
  tab/Tab //UI tab where this action appears
  kind/Kind //type of unit to which this act is allowed:
            //enemy, ally, any or 0; if 0 then show only for owned units
  mov/Mov //movement points require to execute this action
  fatigue/Fatigue
  maxPicks/MaxPicks //maximum number of actions that can appear in a mission
  pickChance/PickChance //chance that one pick of this spells will appear
  picked/(if MaxPicks then -1 else 0) //number of actions of this type picked by player
  picks/(dup 8 -1)
  gold/Gold //cost to pick single instance of this action into battle
  cost/Cost //how much to cast it
  cool/Cool //action cooldown
  needs/Needs //list of dependencies
  needsGene/NeedsGene //available only when unit has specific gene
  priority/Priority
  range/Range //range
  zfree/Zfree //Z value is not locked to range
  speed/Speed //number of cycles before unit can act again
  delay/Delay //number cooldown cycles, after action completes.
  animate/Animate
  repeat/Repeat //repeat action, while possible (i.e. tree is not chopped)
  check/Check //what it can target (see Allowed below)
  menu/Menu
  onMenu/OnMenu
  onInit/OnInit
  onHit/OnHit
  onEnd/OnEnd
  players/#FFFFFF //flags which players have access to this action
  researched/1
  flags //unit flags this actions sets up
  onInitTable
  onEndTable
  icon_gfx //icon graphics for fast access
| $onInitTable <= $onInit.table
| $onEndTable <= $onEnd.table
| less $needsGene.end:
  | when $needsGene.is_text or $needsGene.0><'-': $needsGene <= [$needsGene]
  | $needsGene <= map N $needsGene:
    | if N.is_text or N.0><'-' then [N] else N
| when $cool>0: $onInit <= [[cool $cool] @$onInit]
| less $title:
  | T = $name.replace{_ ' '}
  | when T.size > 5 and T.take{5}><"cast ":
    | T <= T.drop{5}
  | $title <= T.title
| Flags = []
| for E [@$onInit @$onEnd]: case E [add Name]: push Name Flags
| $flags <= Flags
| Cs = $check
| less Cs.is_list: Cs <= [Cs]
| $check <= Cs.flip.list

CheckTable = t

defcheck any:

defcheck self:

defcheck menu:

defcheck unit: when not Target or Target.removed: leave "Needs unit target."

defcheck empty:
| when $site.block_at{XYZ}: leave "Needs empty floor."

defcheck corpse:
| Cs = $site.cellp{XYZ}.units.keep{?type><special_corpse}
| when Cs.end: leave "Needs a corpse."

defcheck clear:
| less $cell.is_floor_empty: leave "Needs clear floor."

defcheck land:
| Below = $site.at{XYZ.0 XYZ.1 XYZ.2-1}
| when Below.liquid or Below.type><void: leave "Needs land."

defcheck water:
| Below = $site.at{XYZ.0 XYZ.1 XYZ.2-1}
| when Below.type <> water: leave "Needs water."

defcheck same_z:
| when (XYZ.2-$xyz.2).abs>0: leave "Too far."

defcheck digable:
| DZ = XYZ.2
| when DZ><1: leave "Cant dig any further."
| less $site.at{XYZ.0 XYZ.1 XYZ.2-1}.dig><1:
  | leave "Undiggable terrain."
| SZ = $xyz.2
| when DZ-SZ>2 or SZ-DZ>0: leave "Too far."
| when $site.cellp{[XYZ.0 XYZ.1 XYZ.2-1]}.neibs8.any{?tile.liquid}:
  | leave "Can't dig near liquid."




defcheck outdoor: less $site.outdoor{XYZ}: leave "Needs outdoor space."

defcheck ally:
| less Target: leave 1
| when $is_enemy{Target}: leave "Needs ally."

defcheck owned:
| less Target: leave 1
| when Target.owner.id <> $owner.id:
  | leave "Needs a unit you own."

defcheck non_leader:
| less Target: leave 1
| when Target.leader: leave "Needs non-leader."

defcheck non_disciplined:
| less Target: leave 1
| when Target.disciplined: leave "Needs non-disciplined unit."

defcheck organic:
| less Target: leave 1
| less Target.has{organic}: leave "Needs organic."

defcheck c_fullhp: when $hp < $class.hp: leave "Needs full health."

defcheck seen:
| less $site.seen_from{$xyz XYZ}: leave "Needs to be in line of sight."

defcheck node:
| Node = $site.cellp{XYZ}.units.find{?type><special_node}
| when no Node: leave "Needs node."
| when Node.blessed: leave "Already activated."

defcheck below: when XYZ.2>>$xyz.2: leave "Needs lower target."

defcheck placeable:
| less $placeable_at{$site.cellp{XYZ}}:
  | leave "Needs place where this unit can stand."

defcheck sinner:
| less Target: leave 1
| less Target.punish_hp: leave "Needs sinner."

defcheck got Gene Err:
| less Target: leave 1
| less Target.has{Gene}: leave Err

defcheck no Gene Err:
| less Target: leave 1
| when Target.has{Gene}: leave Err

act.validate Actor XYZ Target Invalid =
| less Invalid: Invalid <= | M =>
| when Actor.moves < $mov:
  | Invalid{"Needs [$mov] movement points."}
  | leave 0
| less Actor.owner.seen{XYZ}:
  | Invalid{"Needs seen territory."}
  | leave 0
| for C $check:
  | Args = []
  | when C.is_list:
    | Args <= C.tail.list
    | C <= C.0
  | Fn = CheckTable.C
  | when no Fn:
    | Invalid{"Act [$name] has invalid check [C]"}
    | leave 0
  | R = Fn Actor Target XYZ Args
  | when R.is_text:
    | Invalid{R}
    | leave 0
| 1

//turns on/off act(s) for player(s)
site.turn_act State Players ActNames =
| when Players >< all: Players <= 16{(?)}
| when ActNames >< all: ActNames <= $data.acts{}{?0}
| when Players.is_int: Players <= [Players]
| when ActNames.is_text: ActNames <= [ActNames]
| Acts = $main.acts
| for ActName ActNames:
  | Act = Acts.ActName
  | less got Act: bad "missing act [ActName]"
  | for Id Players: Act.players <= Act.players.bitSet{Id State}

unit.earned Act =
| geneCheck N = if N.is_list then not $has{N.1} else $has{N}
| Act.needsGene.all{?any{&geneCheck}}

//is specific act is availalble for particular unit?
unit.can Act = $owner.enabled{Act} and Act.picks.($owner.id) and $earned{Act}

export act
