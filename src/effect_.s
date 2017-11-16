effect Name @Rest =
| Args = Rest.lead
| Body = Rest.last
| FName = Name.rand
| form @
  | FName $'Me' $'Target' $'TargetXYZ' ~As =
    | [$@Args] = ~As
    | Body
  | $\Effects.Name <= &FName

export 'effect'
