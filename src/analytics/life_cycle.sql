-- curioso -> idade < 7
-- fiel -> recência < 7 e recência anterior < 15
-- turista -> 7 <= recência <= 14
-- desencantado -> 14 < recência <= 28
-- zumbi -> recência > 28
-- reconquistado -> recência < 7 e 14 <= recencia anterior <= 28
-- reborn -> recência < 7 e recencia anterior > 28

WITH tb_daily as (

    SELECT DISTINCT
            IdCliente,
            substr(DtCriacao,0,11) as DtDia
    FROM transacoes
    WHERE DtCriacao < '{date}'
),

tb_idade AS (

    SELECT IdCliente,
            min(DtDia) AS DtPrimTransacao,
            cast(max(julianday('{date}') - julianday(DtDia)) as INT) AS qtdeDiasPrimeiraTransacao,
            
            max(DtDia) AS DtUltTransacao,
            cast(min(julianday('{date}') - julianday(DtDia)) as INT) AS qtdeDiasUltTransacao

    FROM tb_daily

    GROUP BY IdCliente
),

tb_rn AS (
    SELECT *,
            row_number() OVER (PARTITION BY IdCliente ORDER BY DtDia DESC) AS rnDia

    FROM tb_daily
),

tb_penultimo_dia AS (
    SELECT *, cast(julianday('{date}') - julianday(DtDia) AS INT) as qtdeDiasPenultimaTransacao
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

SELECT 
    date('{date}', '-1 day') as dtRef,
    *
FROM tb_life_cycle


