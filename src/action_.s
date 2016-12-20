dact Method Body =
| Type =
| Name =
| case Method
  [`.` T N] | Type <= T; Name <= N
  Else | bad "dact: invalid method ([Method])"
| FName = Name.rand
| form @
  | FName $'Me' = Body
  | $\Acts->Type.Name <= &FName

export 'dact'
