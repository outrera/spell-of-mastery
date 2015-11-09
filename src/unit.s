use util action macros

type unit.$class{Id World}
  id/Id
  world/World
  name
  serial
  class
  xyz/[0 0 -1] // world coordinates
  fix_z/0
  from/[0 0 0]
  xy/[0 0] // fine X,Y
  anim // animation id
  anim_step // frame index inside of current animation
  anim_seq // current animation sequence
  anim_wait // cycles till the next animation frame
  frame
  facing // direction this unit faces
  owner // player controlling this unit
  action // currently executing action
  next_action // action to be taken after the current one
  ordered // what owner of this unit has ordered
  sprite
  moved // last turn, this unit moved
  mirror // true, if drawing code should mirror the sprite
  picked // cons of the next unit in the selection
  mark // next mark in the map marks chain
  active // true if this unit resides in the list of active units
  slope // unit is standing on a sloped terrain
  path // next unit in path
  hits // how damaged is this unit
  turn // turn it was created
  flags
  alpha //how transparent is this unit
  delta //change of transparency per cycle
  kills
| $action <= action Me
| $next_action <= action Me
| $ordered <= action Me

unit.as_text = "#unit{[$type] [$id]}"

unit.main = $world.main

unit.attacker = $flags^get_bit{0}
unit.`!attacker` State = $flags <= $flags^set_bit{0 State}

unit.handled = $flags^get_bit{1}
unit.`!handled` State = $flags <= $flags^set_bit{1 State}

unit.summoned = $flags^get_bit{2}
unit.`!summoned` State = $flags <= $flags^set_bit{2 State}

unit.haste = $flags^get_bit{3}
unit.`!haste` State = $flags <= $flags^set_bit{3 State}

unit.shell = $flags^get_bit{4}
unit.`!shell` State = $flags <= $flags^set_bit{4 State}

unit.flyer = $flags^get_bit{5}
unit.`!flyer` State = $flags <= $flags^set_bit{5 State}

unit.poison = $flags^get_bit{6}
unit.`!poison` State = $flags <= $flags^set_bit{6 State}

unit.alive = $hits < $health


world.income_at XYZ =
| for U $units_at{XYZ}:
  | when U.empty and U.income and U.owner.id >< 0:
    | leave U.income
| 0

// extort income from the territory occupied by the unit
unit.move_in State =
| when $item <> pickup: leave
| Income = $world.income_at{$xyz}
| if State then $owner.got_income{Income} else $owner.lost_income{Income}
| for U $world.units_at{$xyz}: when U.item and U.item <> pickup:
  | Add = if U.show then [effect,pickup sound,pickup remove,self] else []
  | U.effect{[@Add @U.item] Me Me.xyz}

//FIXME: when serials get exhausted, compress serial space
unit.init Class =
| $class <= Class
| $sprite <= if $show or $world.mode <> play
             then $default_sprite
             else $world.nil.sprite
| $facing <= 3
| $mirror <= 0
| $serial <= $world.serial
| !$world.serial + 1
| $animate{idle}
| $picked <= 0
| $mark <= 0
| $path <= 0
| $hits <= 0
| $moved <= 0
| $turn <= $world.turn
| $flags <= 0
| $alpha <= 0
| $delta <= 0
| $kills <= 0
| when $class.flyer: $flyer <= 1
| $from.init{0,0,-1}
| when $starts
  | less $active
    | $world.active.push{Me}
  | $active <= 1
  | $ordered.type <= 0
  | $next_action.type <= 0
  | $action.init{idle 0,0,0}
  | $action.cycles <= 0

unit.change_owner NewOwner =
| $owner.lost_unit{Me}
| $owner <= NewOwner
| NewOwner.got_unit{Me}

unit.idle = not $ordered.type and
           [$action $next_action].all{?type^~{0 idle} >< idle}

//FIXME: move these into sprite loading code
AngleReplacements = [6,1 6,1 3,0 -1,0 3,1 3,1 3,1 6,0]

missing_frame Me =
| Index = $anim_seq.$anim_step.0
| bad "[$type] is missing frame `[Index]` of `[$anim]` at angle [$facing]"

unit.pick_facing F =
| $facing <= F
| FrameIndex = $anim_seq.$anim_step.0
| Frame = $sprite.frames.FrameIndex
| less Frame.is_list
  | $frame <= Frame
  | when no $frame: missing_frame Me
  | when $facing <> 3: $mirror <= 1
  | leave
| $mirror <= 0
| Angle = $facing
| till Frame.Angle
  | $mirror <= AngleReplacements.Angle.1
  | Angle <= AngleReplacements.Angle.0
| $frame <= Frame.Angle
| when no $frame: missing_frame Me

unit.animate Anim =
| $anim <= Anim
| $anim_seq <= $sprite.anims.$anim
| when no $anim_seq:
  | $anim_seq <= $sprite.anims.idle
  | less got $anim_seq: bad "unit [$type] is missing `idle` anim"
| $anim_step <= 0
| $pick_facing{$facing}
| $anim_wait <= $anim_seq.$anim_step.1

player_lost_leader Me Leader =
| Leaders = []
| RemainingUnits = []
| for U $world.active.list: when U.id <> Leader.id:
  | when U.leader><1: push U Leaders
  | when U.owner.id >< $id: push U RemainingUnits
| case Leaders [L@Ls]: when Ls.all{?owner.id><L.owner.id}:
  | $world.params.winner <= L.owner.id
  | $world.params.victory_type <= 'Victory by defeating other leaders.'
| when Leader.owner.human: less Leaders.any{?owner.human}:
  | $world.params.winner <= 0
  | $world.params.victory_type <= 'Defeat by losing your leader.'
| when RemainingUnits.any{?leader}: for U RemainingUnits: U.free

unit.free =
| when $id >< $world.waiting: $world.waiting <= 0
| when $owner: $owner.lost_unit{Me}
| when $leader><1 and $hits >> $health: player_lost_leader $owner Me
| when $active: $active <= 2 //request removal from active list
| $world.free_unit{Me}

unit.remove =
| when $xyz.2 <> -1:
  | when $passable and $block: $world.clear_tile{$xyz $world.void}
  | $move_in{0}
| $world.remove_unit{Me}
| $xyz.2 <= -1

unit.removed = $xyz.2 >< -1

unit.order = $ordered

unit.order_act Act target/0 =
| less Target: Target <= Me
| $order.init{target Target @Act.list.join}

unit.guess_order_at_mark Mark =
| XYZ = Mark.xyz
| Us = $world.units_at{XYZ}
| Path = cons path: map M Mark^uncons{path}.lead.flip
  | Node = $world.alloc_unit{mark_node owner/$owner}
  | Node.move{M.xyz}
  | Node
| case Mark.type
  mark_move
    | $order.init{type/move at/XYZ path/Path}
  mark_attack
    | Target = Us.skip{?empty}.0
    | $order.init{type/attack target/Target at/XYZ path/Path}
  mark_swap
    | Target = Us.skip{?empty}.0
    | $order.init{type/swap target/Target at/XYZ path/Path}
  mark_push
    | D = XYZ-$xyz
    | D.2 <= 0
    | TargetXYZ = $xyz+D
    | Target = $world.block_at{TargetXYZ}
    | $order.init{type/push target/Target at/TargetXYZ path/Path}
  Else | leave 0
| 1

unit.guess_order_at XYZ =
| Marks = $world.units_at{XYZ}.keep{?mark}
| for Mark Marks: when $guess_order_at_mark{Mark}: leave

unit.move XYZ =
| $from.init{$xyz}
| $remove
| $xyz.init{XYZ}
| $fix_z <= $world.fix_z{XYZ}
| $xy.init{0,0}
| $world.place_unit{Me}
| when $passable and $block:
  | $world.set{@$xyz $block}
  | XY = $xyz.take{2}
  | $world.update_move_map{XY}
| $environment_updated
| $move_in{1}
| Me

unit.seen = $world.seen{$xyz.0 $xyz.1}

unit.environment_updated =
| UX,UY,UZ = $xyz
| $slope <= $world.slope_at{UX UY UZ-1}^|$1 #@1111 => 0

unit.face XYZ =
| XY = (XYZ-$xyz).take{2}{?sign}
| less XY >< [0 0]: $facing <= Dirs.locate{(XYZ-$xyz).take{2}{?sign}}

type move{type src xyz}
move.as_text = "#move{[$type] [$src] [$xyz]}"

unit.list_moves XYZ =
| less $moves.size: leave []
| Moves = []
| I = 0
| OMs = $moves
| Ms = OMs.deep_copy
| O = Ms.size/2
| StackSrc = []
| StackDst = []
| for N [[O O-1] [O+1 O] [O O+1] [O-1 O]]:
  | X,Y = N
  | Xs = Ms.Y
  | when Xs.X
    | Xs.X <= 0
    | push XYZ StackSrc
    | push N StackDst
| BX,BY,BZ = XYZ
| till StackDst.end
  | Blocked = 0
  | Src = pop StackSrc
  | when Src.is_move //hack to propagate blocked=-1 through path
    | Src <= Src.src
    | Blocked <= -1
  | DX,DY = pop StackDst
  | V = OMs.DY.DX
  | X = BX+DX-O
  | Y = BY+DY-O
  | Z = Src.2
  | Move = 0
  | less $world.at{X Y Z}.empty:
    | I = 0
    | till I><4 or $world.at{X Y Z}.empty:
      | !Z + $world.at{X Y Z}.height
      | !I+1
  | !Z - 1
  | while $world.at{X Y Z}.empty: !Z - 1
  | !Z + 1
  | Dst = [X Y Z]
  | less Blocked: Blocked <= not $can_move{Src Dst}
  | B = $world.block_at{Dst}
  | when got B:
    | when Blocked < 1:
      | EnemyBlocker = $owner.id <> B.owner.id
      | if EnemyBlocker
        then | Blocked <= EnemyBlocker
             | if B.hits < B.health then
                 | when V < 3 and $attack>0:
                   | Move <= move attack Src Dst
               else when can_push Me B:
                 | Move <= move push Src [Dst.0 Dst.1 Dst.2+B.height]
        else | when B.moves.size and B.can_move{Dst Src} and V <> 2:
               | Move <= move swap Src Dst
             | when Blocked>>0: Blocked <= if $ranged then -1 else 1
  | when Blocked < 1:
    | less Move: when V<>2: less Blocked: Move <= move move Src Dst
    | for N [[DX DY-1] [DX+1 DY] [DX DY+1] [DX-1 DY]]:
      | X,Y = N
      | Xs = Ms.Y
      | when Xs.X
        | Xs.X <= 0
        | D = if Blocked < 0 then move 0 Dst 0 else Dst
        | push D StackSrc
        | push N StackDst
  | when Move: push Move Moves
| Moves.list

unit.list_attack_moves XYZ =
| less $attack: leave []
| Map = $moves
| $moves <= Map.deep_copy
| for Xs $moves: for I Xs.size: when Xs.I >< 2: Xs.I <= 1
| Ms = $list_moves{XYZ}
| $moves <= Map
| O =  Map.size/2
| OO = [O O 0]
| Map = $moves
| Ms.keep{M => 
          | X,Y,Z = OO+M.xyz-XYZ
          | V = Map.Y.X
          | V >< 1 or V >< 2}

unit.mark_moves @As =
| XYZ = if As.size then As.0 else $xyz
| Moves = $list_moves{XYZ}
| Marks = map Move Moves
  | Mark = $world.alloc_unit{"mark_[Move.type]" owner/$owner}
  | Mark.move{Move.xyz}
  | Src = Move.src
  | Mark.path <= if Src >< XYZ then 0 else Move.src
  | Mark
| for M Marks: when M.path:
  | for N Marks: when M.path >< N.xyz: M.path <= N
| for M Marks: when M.path.is_list: M.path <= 0
| Marks

// order taking over any other order
unit.forced_order @As =
| O = $order.init{@As}
| O.priority <= 1000
| O.speed <= 0
| O

unit.die =
| $sound{die}
| $world.waiting <= $id
| $forced_order{type/die}

unit.harm Attacker Damage =
| less $hits < $health: leave
| case Damage
  [_ piercing D] | Damage <= D
  Else | when Damage > 0: Damage <= max 1 Damage-$defense
| when $shell and Damage > 0:
  | $shell <= 0
  | $world.effect{$xyz shell}
  | $main.sound{shell}
  | leave
| !$hits + Damage
| less $owner.human: $owner.ai.harm{Attacker Me}
| when $hits < $health:
  | if Damage >> 0
    then | $sound{hit}
         | $animate{hit}
    else when $hits << 0: $hits <= 0
  | leave
| when Attacker:
  | AO = Attacker.owner
  | when $owner.id <> AO.id: !AO.lore+$tier
  | !$owner.params.lossage+$tier
  | !Attacker.kills+1
| $die
| $action.cycles <= 1

unit.sound Type =
| less $world.human.explored{$xyz}>1: leave
| when got!it $sounds.Type: $main.sound{it.rand}


export unit