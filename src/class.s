use gfx util param

type class{bank class_name Main static/0 empty/0 sprite/system_dummy
           unit/0 draw_order/10 aux/0 shadow/0 moves/[] speed/-1 sight/No
           starts/0 flyer/0 mountaineer/0 ranged/0 leader/Leader
           health/0 attack/0 defense/0 level/0 ttl/100000000
           acts/[] sounds/[] icon/0 title/0 income/0}
  type/"[Bank]_[Class_name]"
  static/Static
  empty/Empty
  default_sprite/Sprite
  unit/Unit
  draw_order/Draw_order
  aux/Aux
  shadow/Shadow // unit casts shadow in air
  moves/Moves // movement pattern
  speed/Speed // number of turns it has to wait, before moving again
  sight/Sight
  starts/Starts // non-zero if unit starts active
  flyer/Flyer
  mountaineer/Mountaineer
  ranged/Ranged
  leader/Leader
  health/Health
  attack/Attack
  defense/Defense
  level/Level
  ttl/Ttl
  acts/Acts
  sounds/Sounds.group{2}.table
  icon/Icon
  title/Title
  income/Income
| less $moves.is_list: bad "wrong `moves` field for [$type]"
| less $moves.size: leave Me
| Ms = $moves.tail
| Pad = dup Ms.size 0
| Ms <= [Pad @Ms Pad]{[0 @? 0]}
| $moves <= Ms

class.height = $default_sprite.height

class.form = $default_sprite.form

main.load_classes =
| BankNames = case $params.world.class_banks [@Xs](Xs) X[X]
| $classes <= @table: @join: map BankName BankNames
  | map Name,Params $params.BankName
    | R = class BankName Name Me @Params.list.join
    | S = $sprites.(R.default_sprite)
    | less got S: bad "missing sprite `[R.default_sprite]`"
    | R.default_sprite <= S
    | "[BankName]_[Name]",R
| for S $sprites{}{?1}.keep{?class}
  | C = class S.bank S.name Me @S.class
  | C.default_sprite <= S
  | $classes."[S.bank]_[S.name]" <= C
| for K,V $classes: V.acts <= map ActName V.acts
  | Act = $params.acts.ActName
  | less got Act: bad "[K] references undefined act [ActName]"
  | Act

export class
