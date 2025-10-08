SELECT 
    t1.dtRef,
    t1.IdCliente,
    t1.descLifeCycle,
    t2.descLifeCycle,
    CASE WHEN t2.descLifeCycle = '02-FIEL' THEN 1 ELSE 0 END AS flFiel

FROM  life_cycle as t1

LEFT JOIN life_cycle as t2
ON t1.IdCliente = t2.IdCliente
AND date(t1.dtRef, '+28 day') = date(t2.dtRef)