use gfx util param

type class{bank class_name Main pickable/0 empty/0 sprite/system_dummy
           unit/0 box_xy/[0 0] aux/0 shadow/0 moves/[] speed/-1 sight/No
           starts/0 flyer/0 ranged/0 leader/0
           health/0 attack/0 defense/0 ttl/100000000
           acts/[] sounds/[] icon/0 title/0 income/0 trigger/0 item/0
           ai/0 show/1 height/0
           passable/1 impact/0 movable/0 counter/0 tier/0
           start_effects/[]}
  type/"[Bank]_[Class_name]"
  block/0
  pickable/Pickable
  empty/Empty
  default_sprite/Sprite
  unit/Unit
  box_xy/Box_xy // bounding box x,y correction
  aux/Aux
  shadow/Shadow // unit casts shadow in air
  moves/Moves // movement pattern
  speed/Speed // number of turns it has to wait, before moving again
  sight/Sight
  starts/Starts // non-zero if unit starts active
  flyer/Flyer
  ranged/Ranged
  leader/Leader
  health/Health
  attack/Attack
  defense/Defense
  ttl/Ttl
  acts/Acts
  sounds/Sounds.group{2}.table
  icon/Icon
  title/Title
  income/Income
  item/Item
  ai/Ai
  show/Show
  trigger/Trigger
  height/Height
  passable/Passable
  impact/Impact
  movable/Movable
  counter/Counter //counterattack
  tier/Tier
  start_effects/Start_effects
| less $empty
  | Block = Main.tiles."h[$height]_"
  | when got Block: $block <= Block
| less $moves.is_list: bad "wrong `moves` field for [$type]"
| less $moves.size: leave Me
| $moves <= add_border_to_matrix $moves.tail 0

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
| for K,V $classes:
  | when V.health and V.leader<>1: V.acts <= [@V.acts disband]
| for K,V $classes: V.acts <= map ActName V.acts
  | Act = $params.acts.ActName
  | less got Act: bad "[K] references undefined act [ActName]"
  | Act

export class
