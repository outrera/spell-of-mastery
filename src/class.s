use gfx util

ClassIdCounter = 1

type class{bank class_name Main pickable/0 empty/0 sprite/system_dummy
           unit/0 box_xy/[0 0] aux/0 speed/0 cooldown/24
           active/0
           mov/0 health/0 atk/0 def/0 sight/No range/0 will/0 inborn/[]
           acts/[] spells/0 summons/0 rooms/0 icon/0 title/0 item/0
           ai/0 show/1 height/0
           passable/1 movable/0 counter/0 tier/0
           onAttack/0 onHit/0 onHarm/0 onDeath/0 onMove/0
           platform/0 gate/0 ascendSpeed/4}
  id                    //for unit counts table
  type/"[Bank]_[Class_name]"
  block/0               //acts as map block
  pickable/Pickable     //can be picked?
  empty/Empty           //other units can move through this one
  default_sprite/Sprite
  unit/Unit             //what kind of unit?
  box_xy/Box_xy         //bounding box x,y correction
  aux/Aux               //auxilary unit, like mark
  speed/Speed           //cycles to move between cells
  ascendSpeed/AscendSpeed //how many pixels/cycle flyer can climb
  active/Active         //update unit each cycle?
  hp/Health             //health points
  atk/Atk               //damage this unit deals on attack
  def/Def               //how many moves it takes to hit this unit
  sight/Sight           //scout range
  range/Range           //attack range
  will/Will             //amount of mana required to subvert the unit
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
  counter/Counter       //counter-attack script
  tier/Tier             //unit power-level
  mov/Mov               //movement points this unit gains per turn
  inborn/Inborn         //inborn abilities
  onAttack/OnAttack     //called when unit starts its attack
  onHit/OnHit           //called when attack hits the enemy
  onHarm/OnHarm         //called when unit receives damage
  onDeath/OnDeath       //called when unit dies
  onMove/OnMove         //called when unit enters a cell
  platform/Platform     //increased tenants position on screen
  gate/Gate             //gateway, teleporting units to other cell
| when Spells: $acts <= [@$acts @Spells].list
| when Summons: $acts <= [@$acts @Summons].list
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
    | DS = R.default_sprite
    | when DS><auto: DS <= "unit_[Name]"
    | S = $sprites.DS
    | less got S: bad "missing sprite `[DS]` for `[BankName]_[Name]`"
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
    | when V.atk and V.atk><impact: V.atk<=0
    | As <= [@As @V.acts]
    | As <= [@As @$params.global.acts]
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
