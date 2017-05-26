use util

unit.new_turn =

unit.end_turn =
| Turn = $world.turn
| when not $empty and $class.hp>0:
  | for V $world.units_get{$xyz}: less V.effects.end:
    | V.run_effects{?when><tenant_endturn Me $xyz}
| $run_effects{?when><endturn Me $xyz}
| $run_effects{(E=>E.when><ttl0 and E.params.0><Turn) Me $xyz}
| $strip_effect{E=>E.name><cool and E.params.1+E.params.2<<Turn} 
| $steps <= $class.steps
| $handled <= 0

world.new_turn =

EndTurnLoop = 0
player.new_turn =
| less $total_units:
  | if EndTurnLoop++ > 16
    then | say "caught in end turn loop"
    else | $world.end_turn //no units, skip his turn
         | leave
| EndTurnLoop <= 0
| say "[$name] ([$color]) begins turn [$world.turn]"
| for U $units: U.new_turn

player.end_turn =
| for U $units: U.end_turn

world.end_turn =
| $players.$player.end_turn
| $player++
| when $player >< $players.size:
  | $player <= 0
  | $turn++
  | $new_turn
| $players.$player.new_turn
