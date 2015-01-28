// game world update routines

main.update =
| $world.update

world.update =
| $active <= $active^uncons{active}.keep{?update}^cons{active}
| !$cycle + 1

unit.update =
| 1