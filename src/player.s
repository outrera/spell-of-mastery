type ai{player} world
| $world <= $player.world
| $params.aiSwapXYZ <= [0 0 0]

ai.params = $player.params

ai.picked = $world.picked

ai.clear =
| $params.aiSwapXYZ.init{[0 0 0]}

PlayerColors = [white red blue cyan violet orange black yellow magenta]

type player{id world} name ai human color mana power moves leader pentagram
                      params research/(t) picked
| $name <= if $id >< 0 then "Independent" else "Player[$id]"
| $color <= PlayerColors.$id
| $params <= t
| $ai <= ai Me
| $clear

player.main = $world.main

player.researching = $params.researching
player.`!researching` R = $params.researching <= R

player.clear =
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