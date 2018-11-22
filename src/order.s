use util

unit.order_at Goal Act =
| XYZ = if Goal.is_list then Goal else Goal.xyz
| when Goal.is_list: Goal <= 0
| Cell = $site.cellp{XYZ}
| Units = Cell.units
| OAct = Act
| less Goal: Goal <= Cell.block
| Act <= if Act.is_text then $main.acts.Act
         else if Act then Act
         else if Goal and $owner.is_enemy{Goal.owner}
                 and not Goal.invisible then
           $main.acts.attack
         else if $owner.human and and got Units.find{?type><mark_jump} then
           $main.acts.act_jump
         else $main.acts.move
| ActName = Act.name
| when ActName><idle: Goal <= Me
| less ActName><idle or ActName><move or ActName><swap:
  | invalid Error =
    | $owner.notify{Error}
    | $owner.sound{illegal}
  | less Act.validate{Me XYZ Goal &invalid}: leave
| when $afraid and Act.name<>move and Act.name<>swap:
  | $owner.notify{"Unit is too scared to perform any action!"}
  | leave
| when $moves < Act.mov:
  | $owner.notify{"Not enough moves ([Act.mov] required)"}
  | leave
| when Act.name><move: Goal <= 0 //otherwise it will hung in swap-loop
| when $site.cur_player.human and (Act.name><move or Act.name><attack):
  | Mark = "mark_[Act.name]"
  | Ms = [mark_move mark_attack mark_swap]
  | Move = Units.keep{U=>Ms.has{U.type}}
  | less Move.size
    | $owner.notify{'Cant move there'}
    | leave
  | Goal
| when $owner.human and Act.name<>attack and Act.range>>1 and Act.range<9000:
  | Move = Units.keep{?type><mark_cast}
  | less Move.size: when Act.name<>act_jump:
    | $owner.notify{'Out of range!'}
    | leave
| $reset_goal
| $goal_act <= Act
| $goal <= if Goal then Goal else $site.new_goal{XYZ}
| $goal_serial <= $goal.serial
| $site.actors.set{[Me @$site.actors.get]}
| $set_path{$path_around_to{1000 $goal.xyz}}

unit.order_act Act Target =
| $order.init{Act Target}
| $site.actors.set{[Me @$site.actors.get]}

// order taking over any other order
unit.forced_order Act Target =
| O = $order.init{Act Target}
| O.priority <= 1000
| O.cycles <= 0
| O

unit.die =
| OnDeath = $class.onDeath
| when OnDeath: $effect{OnDeath Me $xyz}
| $animate{death}
| $forced_order{die 0}
| $order.priority <= 2000
| $delay <= 0 //no delay in death

unit.reset_goal =
| less $path.end: $set_path{[]}
| when $goal and $goal.type><special_goal and not $goal.removed: $goal.free
| $goal <= 0

unit.set_path Path =
| P = Path.enheap
| $path.heapfree
| $path <= P

unit.shot_missile Target Args Effect =
| XYZ = if Target.is_unit then Target.xyz else Target
| Type = 0
| Offset = \user
| Speed = 2
| case Args
   [T S O]
     | Type <= T
     | if S><height_div then Speed <= 1
       else Speed <= S
     | Offset <= O
   [T] | Type <= T
| S = $owner.alloc_unit{"effect_[Type]"}
| case Offset
  user | S.move{$xyz}
       | S.face{XYZ}
       | S.animate{idle}
  [target @D] | S.move{$xyz}
              | O = if Target.is_unit then Target.fxyz
                    else $site.fxyz{XYZ}
              | S.fxyz.init{O+D}
  Else | bad "invalid offset specifier [Offset]"
| S.add_gene{missile 0 [[payload $id $serial Effect]]}
| Or = S.order
| Or.init{missile Target}
| Or.priority <= 1500
| C = Speed.float*(XYZ-$xyz).abs*1.5
| Or.cycles <= @int C

unit.order = $ordered

