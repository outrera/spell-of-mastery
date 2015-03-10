type ai{player} world
| $world <= $player.world

ai.update = 0

type player{id world} name ai human color power moves pentagram researched/(t)
                      research/[0 0]
| $ai <= ai Me

// player 0 shouldnt be used
// player 1 would be neutral creatures, moving on their own

export player