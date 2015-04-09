type ai{player} world params
| $world <= $player.world

ai.picked = $world.picked

ai.clear =
| $params <= t

PlayerColors = [white red blue cyan violet orange black yellow magenta]

type player{id world} name ai human color power moves leader pentagram
                      research/(t) researching picked
| $ai <= ai Me
| $name <= if $id >< 0 then "Independent" else "Player[$id]"
| $color <= PlayerColors.$id
| $clear

player.clear =
| $ai.clear
| $picked <= $world.nil

// player 0 shouldnt be used
// player 1 would be neutral creatures, moving on their own

export player