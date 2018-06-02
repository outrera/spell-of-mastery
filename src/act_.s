defcheck Name @Rest =
| Args = Rest.lead
| Body = Rest.last
| FName = Name.rand
| form @
  | FName $'Me' $'Target' $'XYZ' ~As =
    | [$@Args] = ~As
    | Body
  | $\CheckTable.Name <= &FName

export 'defcheck'
