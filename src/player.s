type ai{player} world
| $world <= $player.world

ai.picked = $world.picked

ai.clear =

PlayerColors = [white red blue cyan violet orange black yellow magenta]

type player{id world} name ai human color power moves leader pentagram
                      params research/(t) picked
| $ai <= ai Me
| $name <= if $id >< 0 then "Independent" else "Player[$id]"
| $color <= PlayerColors.$id
| $clear

player.main = $world.main

player.researching = $params.researching
player.`!researching` R = $params.researching <= R

player.clear =
| $ai.clear
| $picked <= $world.nil
| $leader <= 0
| $pentagram <=0
| $params <= t
| $researching <= 0
| for Type,Act $main.params.acts: $research.Type <= 0

// player 0 shouldnt be used
// player 1 would be neutral creatures, moving on their own

export player