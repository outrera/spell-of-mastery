use util

ClassIdCounter = 1
ZeroXY = [0 0]
ActiveAIs = [unit visual door chest node item]

type class{bank class_name Main
           title/0 icon/0
           durability/No
           sprite/Sprite
           height/0
           speed/0 ascendSpeed/4
           cost/0
           mov/0 stamina/1 health/0 atk/0 def/0 sight/No range/0
           inborn/[] acts/[]
           ai/0
           pickable/0 show/1 gate/0
           tier/0
           counter/0 trigger/0 onAttack/0 onHit/0 onHarm/0 onDeath/0 onMove/0
           aux/0 foldable/0 draworder/100 box_xy/ZeroXY
           text/0 text_xy/ZeroXY}
  id                    //for unit counts table
  type/"[Bank]_[Class_name]"
  block/0               //acts as map block
  icon/Icon             //icon for this unit
  title/Title           //proper unit name shown ingame
  default_sprite/Sprite
  draworder/Draworder
  height/Height         //height in tiles
  fheight/0             //fine height (when unit takes only part of a tile)
  box_xy/Box_xy         //bounding box x,y correction
  aux/Aux               //auxilary unit, like mark
  speed/Speed           //cycles to move between cells
  ascendSpeed/AscendSpeed //how many pixels/cycle flyer can climb
  gold                  //cost in gold of this unit
  mov/Mov               //movement points this unit gains per turn
  stamina/Stamina       //fatigue decrement speed
  hp/Health             //health points
  durability/Durability //amount of HP attacker has to pay for bashing it
  atk/Atk               //damage this unit deals on attack
  def/Def               //how many moves it takes to hit this unit
  sight/Sight           //scout range
  range/Range           //attack range
  acts/Acts             //acts this unit can perform
  ai/Ai                 //how AI treats this unit
  aiArg/[]              //additional data for ai
  active/0              //update unit each cycle?
  pickable/Pickable     //can be picked by player?
  show/Show             //show this unit ingame
  tier/Tier             //unit power-level
  inborn/Inborn         //inborn abilities
  counter/Counter       //counter-attack script
  onAttack/OnAttack     //called when unit starts its attack
  trigger/Trigger       //called when unit enters cell of this object
  onHit/OnHit           //called when attack hits the enemy
  onHarm/OnHarm         //called when unit receives damage
  onDeath/OnDeath       //called when unit dies
  onMove/OnMove         //called when unit enters a cell
  gate/Gate             //gateway, teleporting units to other cell
  foldable/Foldable     //fold unit`s sprite when cursor is behind
  inbornFlyer/0
  passCursor/0
  text/Text
  text_xy/Text_xy
| case $ai [X@Xs]:
  | $aiArg <= Xs
  | $ai <= X
| when $height.is_list:
  | $fheight <= $height.2
  | $height <= $height.1
| $active <= if Sprite.anims.idle.size>1 or $inborn.size or $text then 1
             else if ActiveAIs.has{$ai} then 1
             else 0 
| when $active:
  | when Cost: $gold <= Cost.0
  | less $title: $title <= $class_name.title
  | $id <= ClassIdCounter++
  | when $inborn.has{leader}: $acts <= [@$acts @Main.cfg.world.spells].list
  | when $inborn.has{flyer}: $inbornFlyer <= 1
| when $ai >< door: $passCursor <= 1
| when $height and $ai <> unit:
  | Block = Main.tiles."h[$height]_"
  | when got Block: $block <= Block

class.form = $default_sprite.form

main.load_classes =
| BankNames = case $cfg.site.class_banks [@Xs](Xs) X[X]
| $classes <= @table: @join: map BankName BankNames
  | map Name,Cfgs $cfg.BankName
    | SN = Cfgs.'sprite'
    | when no SN: SN <= "system_dummy"
    | when SN><auto: SN <= "unit_[Name]"
    | S = $sprites.SN
    | less got S: bad "missing sprite `[SN]` for `[BankName]_[Name]`"
    | Cfgs.sprite <= S
    | "[BankName]_[Name]",|class BankName Name Me @Cfgs.list.join
| for S $sprites{}{?1}.keep{?class}
  | $classes."[S.bank]_[S.name]" <= class S.bank S.name Me sprite S @S.class
| for K,V $classes:
  | when V.active:
    | As = []
    | when V.atk and V.atk><impact: V.atk<=0
    | As <= [@As @V.acts]
    | As <= [@As @$cfg.global.acts]
    | V.acts <= As
| Acts = $acts
| for K,Act Acts:
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
