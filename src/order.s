use util

unit.order_at XYZ act/0 goal/0 =
| Units = $world.cell{@XYZ}.units
| OAct = Act
| less Goal: Goal <= $world.block_at{XYZ}
| Act <= if Act.is_text then $main.params.acts.Act
         else if Act then Act
         else if Goal and $owner.is_enemy{Goal.owner} then
           $main.params.acts.attack
         else if $owner.human and and got Units.find{?type><mark_jump} then
           $main.params.acts.act_jump
         else $main.params.acts.move
| ActName = Act.name
| less ActName><idle or ActName><move or ActName><swap:
  | invalid Error =
    | $owner.notify{Error}
    | $owner.sound{illegal}
  | less Act.validate{Me XYZ Goal &invalid}: leave
| when $afraid and Act.name<>move and Act.name<>swap:
  | $owner.notify{"Unit is too scared to perform any action!"}
  | leave
| when $mov < Act.mov:
  | $owner.notify{"Not enough moves ([Act.mov] required)"}
  | leave
| when Act.name><move: Goal <= 0 //otherwise it will hung in swap-loop
| when $owner.human and (Act.name><move or Act.name><attack):
  | Mark = "mark_[Act.name]"
  | Move = Units.keep{U=>U.type^~{mark_swap mark_move}><Mark}
  | less Move.size
    | $owner.notify{'Cant move there'}
    | leave
| when $owner.human and Act.tab><spell and Act.range>1 and Act.range<9000:
  | Move = Units.keep{?type><mark_cast}
  | less Move.size
    | $owner.notify{'Cant cast there'}
    | leave
| $unit_goal.xyz.init{XYZ}
| $goal <= if Goal then Goal else $unit_goal
| $goal_act <= Act
| $goal_serial <= $goal.serial
| $world.actors.set{[Me @$world.actors.get]}
| $set_path{$path_around_to{1000 $goal.xyz}}

unit.validated_order_at Act Target =

