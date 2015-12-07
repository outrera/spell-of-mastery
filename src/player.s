use bits

type ai{player} world
| $world <= $player.world
| $params.aiSwapXYZ <= [0 0 0]
| $params.view <= [0 0 0]
| $params.cursor <= [0 0 1]

ai.main = $player.main
ai.params = $player.params

ai.picked = $player.picked
ai.`!picked` V = $player.picked <= V

ai.clear =
| $params.aiSwapXYZ.init{[0 0 0]}
| $params.aiType <= 'default'
| $params.aiStep <= 0
| $params.aiWait <= 0
| $params.aiSpellWait <= 0 //hack to stop AI from spamming spells
| $params.aiLastTurn <= -1
| $params.difficulty <= 6 // 5 is normal, 0 is impossible, 10 is very easy

PlayerColors = [white red blue cyan violet orange black yellow magenta]

type player{id world}
   name ai human color mana
   moves //use to be number for creatues movable per turn; currently obsolete
   leader
   pentagram
   params
   research/(t) //research and latency
   picked_ //picked units
   sight // fog of war
| $name <= if $id >< 0 then "Independents" else "Player[$id]"
| $color <= PlayerColors.$id
| $params <= t
| $sight <= dup 132: 132.bytes
| $ai <= ai Me
| $clear

player.picked = $picked_.unheap
player.`!picked` Us =
| for U $picked_: U.picked <= 0
| for U Us: U.picked <= 1
| Us = Us.enheap
| $picked_.heapfree
| $picked_ <= Us

player.is_enemy P = $id <> P.id

player.notify Text =
| less $human: leave
| $world.notify{Text}

player.main = $world.main

player.researching = $params.researching
player.`!researching` R = $params.researching <= R

player.lore = $params.lore
player.`!lore` R = $params.lore <= R

player.explore State =
| when State
  | for S $sight: S.clear{3}
  | for U $units: U.explore{1}
  | leave
| for S $sight: S.clear{0}
| for U $units: U.explore{1}


player.explored X,Y,Z = $sight.Y.X

player.clear =
| for Xs $sight: Xs.clear{3}
| $ai.clear
| $picked <= []
| $leader <= 0
| $pentagram <= 0
| $researching <= 0
| $mana <= 0
| $lore <= 0
| $params.lossage <= 0
| $params.mana <= 0
| for Type,Act $main.params.acts: $research.Type <= 0

player.got_unit U =

player.lost_unit U =
| when U.ai >< pentagram: $pentagram <= 0

player.research_item What =
| Act = $main.params.acts.What
| $research.What <= Act.research
| $notify{"Acquired [Act.title]"}

player.research_remain Act =
| ResearchSpent = $research.(Act.name)
| ResearchRemain = Act.research - ResearchSpent
| ResearchRemain

player.units =
| PID = $id
| Turn = $world.turn
| $world.active.list.keep{(?owner.id >< PID and not ?removed)}

update_units Me =
| Cycle = $world.cycle
| for U $units: 
  | when U.health>0: for V $world.units_at{U.xyz}: less V.effects.end:
    | V.run_effects{(X=>case X [`.`tenant_cycle N] Cycle%N><0) U U.xyz}
  | less U.effects.end:
    | U.run_effects{(X=>case X [`.`cycle N] Cycle%N><0) U U.xyz}
    | Remove = []
    | RunEs = []
    | for E U.effects: case E [When Name Duration Params]: when Duration>0:
      | !Duration-1
      | less Duration > 0:
        | when When >< timeout: push Name RunEs
        | push Name Remove
      | E.2 <= Duration
    | for Name Remove: U.strip_effect{Name}
    | for Name RunEs:
      | Effect = $world.main.params.effect.Name
      | U.effect{Effect U U.xyz}

alloc_ai_blockers Me =
| for U $units: less U.removed: when U.ai >< avoid:
  | B = U.owner.alloc_unit{unit_block}
  | B.move{U.xyz}

free_ai_blockers Me =
| for U $units: less U.removed: when U.type >< unit_block:
  | U.free

update_spell_of_mastery Me P =
| SOM = P.params.spell_of_mastery
| when got SOM:
  | !SOM-1
  | less SOM > 0:
    | $params.winner <= P.id
    | $params.victory_type <= 'Victory by casting the Spell of Mastery'
    | leave
  | P.params.spell_of_mastery <= SOM
| when P.human: for Q $players:
  | S = Q.params.spell_of_mastery
  | when got S: P.notify{"[Q.name] will finish Spell of Mastery in [S] turns"}

//FIXME:calculate income per second here
update_income Me =
| IC = $main.params.world.income_cycle
| when $world.cycle%IC><0: !$mana + 1
| Leader = $leader
| when $mana < $main.params.world.defeat_threshold and Leader:
  | $main.show_message{'Wizard has Lost Too Much Mana'
       "[$name] is too exhausted and cannot continue his life."}
  | Leader.harm{Leader 1000}
  | Leader.harm{Leader 1000} //in case leade has shell
  | $world.effect{Leader.xyz electrical}

player.update =
| when $world.cycle><0 and $human and $leader:
  | $world.view.center_at{$leader.xyz cursor/1}
| update_units Me
| update_income Me
| PResearch = $research
| for Type,Act $main.params.acts: when PResearch.Type > Act.research:
  | !PResearch.Type-1 //cooldown
| update_spell_of_mastery $world Me
//|less $human: alloc_ai_blockers $world
//| $ai.update
//|less $human: free_ai_blockers $world


export player