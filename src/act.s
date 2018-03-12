use util


type act{name title/0 icon/No hotkey/0 hint/0 tab/0 room/0
         lore/0 cost/0 steps/1 cool/0 needs/[]
         priority/50 range/0 speed/4 repeat/0
         check/unit before/[] impact/Impact after/[]}
  title/Title
  icon/Icon
  hotkey/Hotkey //keyboard shortcut
  hint/Hint //hint for AI: harm (single unit), harm_all (all units)
            //             boost(single unit), boost_allies(all allies),
            //             heal_allies, morph
  tab/Tab //UI tab where this action appears
  room/Room // this act places room scaffolds
  lore/Lore //amount of lore required to research this action
  cost/Cost //how much to cast it
  steps/Steps //action points
  cool/Cool //action cooldown
  needs/Needs //list of dependencies
  priority/Priority
  range/Range //range
  speed/Speed //number of cycles before unit can act again
  repeat/Repeat //repeat action, while possible (i.e. tree is not chopped)
  check/Check //what it can target (see Allowed below)
  before/Before
  impact/Impact
  after/After
  enabled/#FFFFFF //which players have access to this action
  flags //unit flags this actions sets up
  before_table
  after_table
  icon_gfx //icon graphics for fast access
| $before_table <= $before.table
| $after_table <= $after.table
| when $cool>0: $before <= [[cool $cool] @$before]
| less $title: $title <= $name.replace{_ ' '}
| Flags = []
| for E [@$before @$after]: case E [add Name]: push Name Flags
| $flags <= Flags
| Allowed = [land water clear seen below outdoor owned ally non_leader will
             any unit empty self pentagram
             placeable c_fullhp]
| T = Allowed{[? 0]}.table
| As = $check
| less As.is_list: As <= [As]
| for A As:
  | when no T.A: bad "Act [$name]: illegal check item `[A]`"
  | T.A <= 1
| when not T.unit and not T.any and not T.empty and not T.self and not T.pentagram: 
  | bad "Act [$name]: missing check target type."
| $check <= T

act.validate Actor XYZ Target Invalid =
| T = $check
| less Actor.owner.seen{XYZ}:
  | Invalid{"Needs seen territory."}
  | leave 0
| when T.unit and not Target or Target.removed: leave 0
| when T.pentagram:
  | P = Actor.owner.pentagram
  | less P:
    | Invalid{"This action requires pentagram."}
    | leave 0
  | when Actor.world.block_at{P.xyz}:
    | Invalid{"Pentagram is blocked"}
    | leave 0
| when T.clear:
  | less Actor.cell.is_floor_empty:
    | Invalid{"Needs clear floor"}
    | leave 0
| when T.empty and Actor.world.block_at{XYZ}:
  | Invalid{"Needs empty floor"}
  | leave 0
| Below = Actor.world.at{XYZ.0 XYZ.1 XYZ.2-1}
| when T.land and (Below.liquid or Below.type><void):
  | Invalid{"Needs land."}
  | leave 0
| when T.ally and Actor.is_enemy{Target}:
  | Invalid{"Needs ally."}
  | leave 0
| when T.owned and Target and Target.owner.id<>Actor.owner.id:
  | Invalid{"Needs a unit you own."}
  | leave 0 
| when T.water and Below.type <> water:
  | Invalid{"Needs water."}
  | leave 0
| when T.outdoor and not Actor.world.outdoor{XYZ}:
  | Invalid{"Needs outdoor space."}
  | leave 0
| when T.non_leader and Target and Target.leader><1:
  | Invalid{"Needs non-leader."}
  | leave 0
| when T.will and Target and Target.will > Actor.owner.mana:
  | Invalid{"Needs [Target.will] mana."}
  | leave 0
| when T.c_fullhp and Actor.hp < Actor.class.hp:
  | Invalid{"Needs full health."}
  | leave 0
| when T.seen and not Actor.world.seen_from{Actor.xyz XYZ}:
  | Invalid{"Needs to be in line of sight."}
  | leave 0
| when T.below and XYZ.2>>Actor.xyz.2:
  | Invalid{"Needs lower target"}
  | leave 0
| when T.placeable and not Actor.placeable_at{Actor.world.cellp{XYZ}}:
  | Invalid{"Needs place where this unit can stand."}
  | leave 0
| when $name >< room_demolish and not Below.cost:
  | Invalid{"Cant demolish this."}
  | leave 0
| 1

export act
