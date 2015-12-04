/*hline X Y L F =
| E = X+L
| D = if X<E then 1 else -1
| while X<>E:
  | F{X Y}
  | !X+D
| 0

vline X Y L F =
| E = Y+L
| D = if Y<E then 1 else -1
| while Y<>E:
  | F{X Y}
  | !Y+D
| 0

line_points_sub SX SY DX DY F =
| when SX >< DX: leave: vline SX SY DY-SY F
| when SY >< DY: leave: hline SX SY DX-SX F
| when SY > DY:
  | swap SX DX
  | swap SY DY
| YLen = DY - SY
| XLen = 0
| Incr = 0
| if SX > DX
  then | XLen <= SX - DX
       | Incr <= -1
  else | XLen <= DX - SX
       | Incr <= 1
| X = SX
| Y = SY
| when YLen < XLen:
  | when SX > DX:
    | swap SX DX
    | Y <= DY
  | P = YLen*2 - XLen
  | X = SX
  | while X < DX:
    | F{X Y}
    | if P < 0 then !P + YLen*2
      else | !Y + Incr
           | !P + (YLen-XLen)*2
    | !X+1
  | leave 0
| when XLen < YLen:
  | P = XLen*2 - YLen
  | Y = SY
  | while Y < DY:
    | F{X Y}
    | if P < 0 then !P + XLen*2
      else | !X + Incr
           | !P + (XLen-YLen)*2
    | !Y+1
  | leave 0
| while Y <> DY:
  | F{X Y}
  | !X + Incr
  | !Y + 1
*/

line_points_sub AX AY BX BY F =
| DX = BX - AX
| DY = BY - AY
| DXA = DX.abs
| DYA = DY.abs
| SX = DX.sign
| SY = DY.sign
| X = AX
| Y = AY
| when DXA > DYA:
  | T = DYA*2 - DXA
  | while X<>BX or Y<>BY:
    | when T >> 0
      | !Y + SY
      | !T - DXA*2
    | !X + SX
    | !T + DYA*2
    | F{X Y}
  | leave
| T = DXA*2 - DYA
| while X<>BX or Y<>BY: 
  | when T >> 0:
    | !X + SX
    | !T - DYA*2
  | !Y + SY
  | !T + DXA*2
  | F{X Y}

line_points SX SY DX DY =
| Ps = []
| line_points_sub SX SY DX DY: X Y => push X,Y Ps
| when Ps.end: leave []
| Ps = Ps.list
| when Ps.head <> [SX SY]: Ps <= Ps.flip
| Ps


line_calls AX AY BX BY F =
| DX = BX - AX
| DY = BY - AY
| DXA = DX.abs
| DYA = DY.abs
| SX = DX.sign
| SY = DY.sign
| X = AX
| Y = AY
| when DXA > DYA:
  | T = DYA*2 - DXA
  | while X<>BX or Y<>BY:
    | when T >> 0
      | !Y + SY
      | !T - DXA*2
    | !X + SX
    | !T + DYA*2
    | less F{X Y}: leave 0
  | leave 1
| T = DXA*2 - DYA
| while X<>BX or Y<>BY: 
  | when T >> 0:
    | !X + SX
    | !T - DYA*2
  | !Y + SY
  | !T + DXA*2
  | less F{X Y}: leave 0
| 1

export line_points line_calls