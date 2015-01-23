type game{main world} cycle turn 
| $world.game <= Me

game.update =
| !$cycle + 1

export game