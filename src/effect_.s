effect Name @Rest =
| Args = Rest.lead
| Body = Rest.last
| FName = Name.rand
| when Args.size >< 0: Args == ['Dummy'.rand]
| if Args.size >< 1 and Args.0.is_text then Args == Args.0
  else Args == form [$@Args]
| form @
  | FName $'Me' $'Target' $'TargetXYZ' Args = Body
  | $\Effects.Name == &FName

export 'effect'
