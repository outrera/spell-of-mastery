use fxn
/*hline X Y L F =
| E = X+L
| D = if X<E then 1 else -1
| while X<>E:
  | F{X Y}
  | X+=D
| 0

vline X Y L F =
| E = Y+L
| D = if Y<E then 1 else -1
| while Y<>E:
  | F{X Y}
  | Y+=D
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
    | if P < 0 then P += YLen*2
      else | Y += Incr
           | P += (YLen-XLen)*2
    | X++
  | leave 0
| when XLen < YLen:
  | P = XLen*2 - YLen
  | Y = SY
  | while Y < DY:
    | F{X Y}
    | if P < 0 then P += XLen*2
      else | X += Incr
           | P += (XLen-YLen)*2
    | Y++
  | leave 0
| while Y <> DY:
  | F{X Y}
  | X += Incr
  | Y++
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
      | Y += SY
      | T -= DXA*2
    | X += SX
    | T += DYA*2
    | F{X Y}
  | leave
| T = DXA*2 - DYA
| while X<>BX or Y<>BY: 
  | when T >> 0:
    | X += SX
    | T -= DYA*2
  | Y += SY
  | T += DXA*2
  | F{X Y}

line_calls AX AY BX BY F =
| DX = BX - AX
| DY = BY - AY
| SX = DX.sign
| SY = DY.sign
| DX = DX.abs
| DY = DY.abs
| DX2 = DX*2
| DY2 = DY*2
| X = AX
| Y = AY
| when DX > DY:
  | TY = DY2 - DX
  | while X<>BX:
    | when TY >> 0
      | Y += SY
      | TY -= DX2
    | X += SX
    | TY += DY2
    | less F{X Y}: leave 0
  | leave 1
| TX = DX2 - DY
| while Y<>BY: 
  | when TX >> 0:
    | X += SX
    | TX -= DY2
  | Y += SY
  | TX += DX2
  | less F{X Y}: leave 0
| 1

//voxel ray caster / ray marching
line_calls3d AX AY AZ BX BY BZ F = fxn:
| DX = BX - AX
| DY = BY - AY
| DZ = BZ - AZ
| SX = DX.sign
| SY = DY.sign
| SZ = DZ.sign
| DX = DX.abs
| DY = DY.abs
| DZ = DZ.abs
| DX2 = DX*2
| DY2 = DY*2
| DZ2 = DZ*2
| X = AX
| Y = AY
| Z = AZ
| when DX >> DY and DX >> DZ:
  | TY = DY2 - DX
  | TZ = DZ2 - DX
  | while X<>BX:
    | when TY >> 0: //should it be `>`?
      | Y += SY
      | TY -= DX2
    | when TZ >> 0:
      | Z += SZ
      | TZ -= DX2
    | X += SX
    | TY += DY2
    | TZ += DZ2
    | less F{X Y Z}: leave 0
  | leave 1
| when DY >> DX and DY >> DZ:
  | TX = DX2 - DY
  | TZ = DZ2 - DY
  | while Y<>BY: 
    | when TX >> 0:
      | X += SX
      | TX -= DY2
    | when TZ >> 0:
      | Z += SZ
      | TZ -= DY2
    | TX += DX2
    | Y += SY
    | TZ += DZ2
    | less F{X Y Z}: leave 0
  | leave 1
| TX = DX2 - DZ
| TY = DY2 - DZ
| while Z<>BZ: 
  | when TX >> 0:
    | X += SX
    | TX -= DZ2
  | when TY >> 0:
    | Y += SY
    | TY -= DZ2
  | TX += DX2
  | TY += DY2
  | Z += SZ
  | less F{X Y Z}: leave 0
| 1

line_points SX SY DX DY =
| Ps = []
| line_calls SX SY DX DY: X Y => | push X,Y Ps; 1
| when Ps.end: leave []
| Ps = Ps.list
| when Ps.head <> [SX SY]: Ps <= Ps.flip
| Ps

export line_points line_calls line_calls3d
