UnitFlags = 
UnitFlagsTable = 

init_unit_flags Me =
| Fs = $params.gene.flags
| when no Fs: bad "missing params/main/gene.txt/flags"
| UnitFlags <= Fs
| UnitFlagsTable <= UnitFlags{[?0 ?1]}.table

getUnitFlags = UnitFlags
getUnitFlagsTable = UnitFlagsTable

export init_unit_flags getUnitFlags getUnitFlagsTable
