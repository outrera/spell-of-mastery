use bits

type ai{player} world
| $world <= $player.world
| $params.aiSwapXYZ <= [0 0 0]
| $params.view <= [0 0 0]
| $params.cursor <= [0 0 1]

ai.params = $player.params

ai.picked = $world.picked

ai.clear =
| $params.aiSwapXYZ.init{[0 0 0]}

PlayerColors = [white red blue cyan violet orange black yellow magenta]

type player{id world}
   name ai human color mana power
   moves //use to be number for creatues movable per turn; currently obsolete
   leader
   pentagram
   params research/(t) picked
   sight // fog of war
| $name <= if $id >< 0 then "Independent" else "Player[$id]"
| $color <= PlayerColors.$id
| $params <= t
| $sight <= dup 132: 132.bytes
| $ai <= ai Me
| $clear

player.main = $world.main

player.researching = $params.researching
player.`!researching` R = $params.researching <= R

player.clear =
| for Xs $sight: Xs.clear{1}
| $ai.clear
| $picked <= $world.nil
| $leader <= 0
| $pentagram <= 0
| $researching <= 0
| $power <= 1
| for Type,Act $main.params.acts: $research.Type <= 0


player.active =
| PID = $id
| Turn = $world.turn
| $world.active.list.keep{(?owner.id >< PID and ?moved < Turn
                           and not ?removed)}
player.units =
| PID = $id
| Turn = $world.turn
| $world.active.list.keep{(?owner.id >< PID and not ?removed)}

player.research_remain Act =
| ResearchSpent = $research.(Act.type)
| ResearchRemain = Act.research - ResearchSpent
| ResearchRemain

export player