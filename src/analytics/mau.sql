WITH tb_daily as (

    SELECT DISTINCT
        date(substr(DtCriacao,0,11)) as DtDia,
        IdCliente

    FROM transacoes
    ORDER BY DtDia
),

tb_distinct_day as (
    SELECT 
        DISTINCT DtDia as dtRef
    
    FROM tb_daily
)

SELECT t1.dtRef,
    count(DISTINCT IdCliente) AS MAU,
    count(DISTINCT t2.DtDia) AS qtdeDias

FROM tb_distinct_day AS t1

LEFT JOIN tb_daily as t2
ON t2.DtDia <= t1.dtRef
AND julianday(t1.dtRef) - julianday(t2.DtDia) < 28

GROUP BY t1.dtRef
ORDER BY t1.dtRef DESC

LIMIT 1000