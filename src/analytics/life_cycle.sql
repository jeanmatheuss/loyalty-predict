WITH tb_daily as (

SELECT DISTINCT
        IdCliente,
        substr(DtCriacao,0,11) as DtDia
FROM transacoes
),

tb_idade AS (
SELECT IdCliente,
        min(DtDia) AS DtPrimTransacao,
        cast(max(julianday('now') - julianday(DtDia)) as INT) AS qtdeDiasPrimeiraTransacao,
        
        max(DtDia) AS DtUltTransacao,
        cast(min(julianday('now') - julianday(DtDia)) as INT) AS qtdeDiasUltTransacao

FROM tb_daily

GROUP BY IdCliente
),

tb_rn AS (
SELECT *,
        row_number() OVER (PARTITION BY IdCliente ORDER BY DtDia DESC) AS rnDia

FROM tb_daily
),

tb_penultimo_dia AS (
SELECT *, cast(julianday('now') - julianday(DtDia) AS INT) as qtdeDiasPenultimaTransacao
FROM tb_rn
WHERE rnDia = 2
),
tb_life_cycle AS (
SELECT t1.*,
        t2.qtdeDiasPenultimaTransacao,
        CASE 
            WHEN qtdeDiasPrimeiraTransacao <= 7 THEN '01-CURIOSO'
            WHEN qtdeDiasUltTransacao <= 7 AND qtdeDiasPenultimaTransacao - qtdeDiasUltTransacao <= 14 THEN '02-FIEL'
            WHEN qtdeDiasUltTransacao BETWEEN 7 AND 14 THEN '03-TURISTA'
            WHEN qtdeDiasUltTransacao BETWEEN 15 AND 28 THEN '04-DESENCANTADA'
            WHEN qtdeDiasUltTransacao > 28 THEN '05-ZUMBI'
            WHEN qtdeDiasUltTransacao <=7 AND qtdeDiasPenultimaTransacao - qtdeDiasUltTransacao BETWEEN 15 AND 28 THEN '02-RECONQUISTADO'
            WHEN qtdeDiasUltTransacao <=7 AND qtdeDiasPenultimaTransacao - qtdeDiasUltTransacao > 28 THEN '02-REBORN'  
        END AS descLifeCycle
FROM tb_idade as t1

LEFT JOIN tb_penultimo_dia as t2
ON t1.IdCliente = t2.IdCliente
)

SELECT descLifeCycle, count(*)
FROM tb_life_cycle
GROUP BY descLifeCycle