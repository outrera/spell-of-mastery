type ai{player} world
| $world <= $player.world

ai.update =
| PID = $player.id
| Turn = $world.turn
| Units = $world.active.list.keep{(?owner.id >< PID and ?moved <> Turn)}
| Moved = 0
| for U Units: less Moved:
  | Ms = U.mark_moves
  | case Ms [M@_]
    | $world.update_pick{[U]}
    | U.guess_order_at{M.xyz}
    | Moved <= 1
  | for M Ms: M.free
| less Moved
  | $world.update_pick{[]}
  | $world.end_turn

ai.picked = $world.picked

ai.clear =

PlayerColors = [white red blue cyan violet orange black yellow magenta]

type player{id world} name ai human color power moves leader pentagram
                      research/(t) researching picked
| $ai <= ai Me
| $name <= if $id >< 0 then "Independent" else "Player[$id]"
| $color <= PlayerColors.$id
| $clear

player.clear =
| $ai.clear
| $picked <= 0

// player 0 shouldnt be used
// player 1 would be neutral creatures, moving on their own

export player