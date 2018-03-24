use util macros


type act{name title/0 icon/No hotkey/0 hint/0 tab/0 room/0
         lore/0 cost/0 mov/1 cool/0 needs/[] needsGene/[]
         priority/50 range/0 speed/4 animate/No repeat/0
         menu/0 onMenu/0
         check/unit before/[] impact/Impact after/[]}
  title/Title
  icon/Icon
  hotkey/Hotkey //keyboard shortcut
  hint/Hint //hint for AI: harm (single unit), harm_all (all units)
            //             boost(single unit), boost_allies(all allies),
            //             heal_allies, morph
  tab/Tab //UI tab where this action appears
  room/Room // this act places room scaffolds
  mov/Mov //movement points require to execute this action
  lore/Lore //amount of lore required to research this action
  cost/Cost //how much to cast it
  cool/Cool //action cooldown
  needs/Needs //list of dependencies
  needsGene/NeedsGene //available only when unit has specific status
  priority/Priority
  range/Range //range
  speed/Speed //number of cycles before unit can act again
  animate/Animate
  repeat/Repeat //repeat action, while possible (i.e. tree is not chopped)
  check/Check //what it can target (see Allowed below)
  menu/Menu
  onMenu/OnMenu
  before/Before
  impact/Impact
  after/After
  players/#FFFFFF //flags which players have access to this action
  flags //unit flags this actions sets up
  before_table
  after_table
  icon_gfx //icon graphics for fast access
| $before_table <= $before.table
| $after_table <= $after.table
| when $needsGene <> []:
  | when $needsGene.is_text or $needsGene.0><'-': $needsGene <= [$needsGene]
  | $needsGene <= map N $needsGene:
    | if N.is_text or N.0><'-' then [N] else []
| when $cool>0: $before <= [[cool $cool] @$before]
| less $title: $title <= $name.replace{_ ' '}
| Flags = []
| for E [@$before @$after]: case E [add Name]: push Name Flags
| $flags <= Flags
| Allowed = [land water clear seen below outdoor owned ally non_leader organic will
             menu any unit empty self pentagram
             placeable c_fullhp]
| T = Allowed{[? 0]}.table
| As = $check
| less As.is_list: As <= [As]
| for A As:
  | when no T.A: bad "Act [$name]: illegal check item `[A]`"
  | T.A <= 1
| less T.unit or T.any or T.empty or T.self or T.pentagram or T.menu:
  | bad "Act [$name]: missing check target type."
| $check <= T

act.validate Actor XYZ Target Invalid =
| T = $check
| less Invalid: Invalid <= | M =>
| O = Actor.owner
| less O.seen{XYZ}:
  | Invalid{"Needs seen territory."}
  | leave 0
| when T.unit and not Target or Target.removed: leave 0
| Cost = $cost
| when T.will and Target: Cost += Target.will
| when Cost > O.mana:
  | Invalid{"Needs [Cost] mana."}
  | leave 0
| Wr = Actor.world
| when T.pentagram:
  | P = O.pentagram
  | when P.removed:
    | Invalid{"Needs pentagram."}
    | leave 0
  | when Wr.block_at{P.xyz}:
    | Invalid{"Pentagram is blocked"}
    | leave 0
| when T.clear:
  | less Actor.cell.is_floor_empty:
    | Invalid{"Needs clear floor"}
    | leave 0
| when T.empty and Wr.block_at{XYZ}:
  | Invalid{"Needs empty floor"}
  | leave 0
| Below = Wr.at{XYZ.0 XYZ.1 XYZ.2-1}
| when T.land and (Below.liquid or Below.type><void):
  | Invalid{"Needs land."}
  | leave 0
| when T.ally and Actor.is_enemy{Target}:
  | Invalid{"Needs ally."}
  | leave 0
| when T.owned and Target and Target.owner.id<>O.id:
  | Invalid{"Needs a unit you own."}
  | leave 0 
| when T.water and Below.type <> water:
  | Invalid{"Needs water."}
  | leave 0
| when T.outdoor and not Wr.outdoor{XYZ}:
  | Invalid{"Needs outdoor space."}
  | leave 0
| when T.non_leader and Target and Target.leader:
  | Invalid{"Needs non-leader."}
  | leave 0
| when T.organic and not Target.has{organic}:
  | Invalid{"Needs organic."}
  | leave 0
| when T.c_fullhp and Actor.hp < Actor.class.hp:
  | Invalid{"Needs full health."}
  | leave 0
| when T.seen and not Wr.seen_from{Actor.xyz XYZ}:
  | Invalid{"Needs to be in line of sight."}
  | leave 0
| when T.below and XYZ.2>>Actor.xyz.2:
  | Invalid{"Needs lower target"}
  | leave 0
| when T.placeable and not Actor.placeable_at{Wr.cellp{XYZ}}:
  | Invalid{"Needs place where this unit can stand."}
  | leave 0
| when $name >< room_demolish and not Below.cost:
  | Invalid{"Cant demolish this."}
  | leave 0
| 1

//turns on/off act(s) for player(s)
world.turn_act State Players ActNames =
| when Players >< all: Players <= 16{(?)}
| when ActNames >< all: ActNames <= $params.acts{}{?0}
| when Players.is_int: Players <= [Players]
| when ActNames.is_text: ActNames <= [ActNames]
| Acts = $main.params.acts
| for ActName ActNames:
  | Act = Acts.ActName
  | less got Act: bad "missing act [ActName]"
  | for Id Players: Act.players <= Act.players^set_bit{Id State}

act.enabled Player = $players^get_bit{Player.id}<>0

act.researched Player =
| $needs.all{Ns=>Ns.any{N=>Player.research_remain{Me}<<0}}

act.earned Unit =
| geneCheck N = if N.is_list then not Unit.has{N.1} else Unit.has{N}
| when $needsGene.any{Ns=>not Ns.any{&geneCheck}}: leave 0

//checks if specific act is availalble for particular unit
act.available Unit =
| $enabled{Unit.owner} and $researched{Unit.owner} and $earned{Unit}

export act
