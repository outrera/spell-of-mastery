UnitFlags = 
UnitFlagsTable = 

main.init_unit_flags =
| Fs = $cfg.gene.flags
| when no Fs: bad "missing cfg/main/gene.txt/flags"
| UnitFlags <= Fs
| UnitFlagsTable <= UnitFlags{[?0 ?1]}.table

getUnitFlags = UnitFlags
getUnitFlagsTable = UnitFlagsTable

export getUnitFlags getUnitFlagsTable
