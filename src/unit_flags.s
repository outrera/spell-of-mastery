UnitFlags = 
UnitFlagsTable = 

init_unit_flags Me =
| Fs = $params.effect.flags
| when no Fs: bad "missing params/main/effect.txt/flags"
| UnitFlags <= Fs{[A [B C]]=>[A B C]}
| UnitFlagsTable <= UnitFlags{[?0 ?1]}.table

getUnitFlags = UnitFlags
getUnitFlagsTable = UnitFlagsTable

export init_unit_flags getUnitFlags getUnitFlagsTable
