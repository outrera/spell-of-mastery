use gfx util

ClassIdCounter = 1

type class{bank class_name Main pickable/0 empty/0 sprite/system_dummy
           unit/0 box_xy/[0 0] aux/0 speed/0 sight/No
           active/0 range/0 leader/0
           health/0 combat/0 armor/0 cooldown/24
           acts/[] spells/0 rooms/0 icon/0 title/0 item/0
           ai/0 show/1 height/0
           passable/1 movable/0 counter/0 tier/0
           steps/0 inborn/[] pentagram/0
           attack/0 impact/0 impact_hit/0
           hit/0 death/0 moves/0 platform/0}
  id                    //for unit counts table
  type/"[Bank]_[Class_name]"
  block/0               //acts as map block
  pickable/Pickable     //can be picked?
  empty/Empty           //other units can move through this one
  default_sprite/Sprite
  unit/Unit             //is creature or leader?
  box_xy/Box_xy         //bounding box x,y correction
  aux/Aux               //auxilary unit, like mark
  speed/Speed           //cycles to move between cells
  sight/Sight           //scout range
  active/Active         //update unit each cycle?
  range/Range           //attack range
  leader/Leader         //is this unit a leader?
  hp/Health             //health points
  combat/Combat         //damage this unit deals on attack
  armor/Armor           //
  cooldown/Cooldown     //number of cycles between unit attacks
  acts/Acts             //acts this unit can perform
  icon/Icon             //icon for this unit
  title/Title           //proper unit name shown ingame
  item/Item             //for item units
  ai/Ai                 //how AI treats this unit
  show/Show             //show this unit ingame
  height/Height         //height in tiles
  passable/Passable     //other units can move on top of this one
  movable/Movable       //can move
  counter/Counter       //counterattack
  tier/Tier             //unit power-level
  steps/Steps           //cells this unit can move per turn
  inborn/Inborn         //inborn abilities
  attack/Attack         //on attack script
  impact/Impact         //on impact script
  impact_hit/Impact_hit //on impact hit script
  hit/Hit               //on hurt script
  death/Death           //on death script
  moves/Moves           //on movement script
  pentagram/Pentagram   //pentagram this unit casts
  platform/Platform     //increased tenants position on screen
| when Spells: $acts <= [@$acts @Spells].list
| when Rooms: $acts <= [@$acts @Rooms].list
| when $active:
  | less $title: $title <= $class_name.title
  | $id <= ClassIdCounter++
| less $empty
  | Block = Main.tiles."h[$height]_"
  | when got Block: $block <= Block

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
| Acts = $params.acts
| ItemDrop = Acts.item_drop
| ItemTake = Acts.item_take
| for K,V $classes:
  | when V.item><1: //FIXME: have act icons extract name/gfx from unit classes
    | for Pref,Item [`drop_`,ItemDrop `take_`,ItemTake]{?deep_copy}
      | Name = "[Pref][K]"
      | Item.name <= Name
      | Item.icon_gfx <= V.default_sprite.frames.0
      | Acts.Name <= Item
      | Item.title <= Name.replace{_ ' '}
  | when V.active:
    | As = []
    | when V.speed: As <= [recall @As]
    | when V.combat and V.combat><impact: V.combat<=0
    | As <= [@As @V.acts]
    | when V.leader<>1 and V.ai<>pentagram: As <= [@As disband]
    | V.acts <= As
| for K,Act $params.acts.list:
  | less Act.needs.end:
    | Act.needs <= map N Act.needs:
      | if N.is_list then N else [N]
  | for NAs Act.needs: for NeededAct NAs: when no Acts.NeededAct: 
    | bad "act [K] needs undefined act [NeededAct]"
| for K,V $classes: V.acts <= map ActName V.acts
  | Act = Acts.ActName
  | less got Act: bad "[K] references undefined act [ActName]"
  | Act

export class
