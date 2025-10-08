WITH tb_transacao AS (

    SELECT *,
            substr(DtCriacao,0,11) AS dtDia,
            cast(substr(dtCriacao,12,2) AS INT) as dtHora
    FROM transacoes
    WHERE DtCriacao < '{date}'
),

tb_agg_transacao AS (

    SELECT IdCliente,

            max(julianday('{date}') - julianday(DtCriacao)) AS idadeDias,

            count(DISTINCT dtDia) AS qtdeAtivacaoVida,
            count(DISTINCT CASE WHEN dtDia >= date('{date}', '7 days') THEN dtDia END) AS qtdeAtivacaoD7,
            count(DISTINCT CASE WHEN dtDia >= date('{date}', '14 days') THEN dtDia END) AS qtdeAtivacaoD14,
            count(DISTINCT CASE WHEN dtDia >= date('{date}', '28 days') THEN dtDia END) AS qtdeAtivacaoD28,
            count(DISTINCT CASE WHEN dtDia >= date('{date}', '56 days') THEN dtDia END) AS qtdeAtivacaoD56,

            count(DISTINCT IdTransacao) AS qtdeTransacaoVida,
            count(DISTINCT CASE WHEN dtDia >= date('{date}', '7 days') THEN IdTransacao END) AS qtdeTransacaoD7,
            count(DISTINCT CASE WHEN dtDia >= date('{date}', '14 days') THEN IdTransacao END) AS qtdeTransacaoD14,
            count(DISTINCT CASE WHEN dtDia >= date('{date}', '28 days') THEN IdTransacao END) AS qtdeTransacaoD28,
            count(DISTINCT CASE WHEN dtDia >= date('{date}', '56 days') THEN IdTransacao END) AS qtdeTransacaoD56,

            sum(qtdePontos) AS SaldoVida,
            sum(CASE WHEN dtDia >= date('{date}', '7 days') THEN qtdePontos ELSE 0 END) AS saldoD7,
            sum(CASE WHEN dtDia >= date('{date}', '14 days') THEN qtdePontos ELSE 0 END) AS saldoD14,
            sum(CASE WHEN dtDia >= date('{date}', '28 days') THEN qtdePontos ELSE 0 END) AS saldoD28,
            sum(CASE WHEN dtDia >= date('{date}', '56 days') THEN qtdePontos ELSE 0 END) AS saldoD56,

            sum(CASE WHEN qtdePontos > 0 THEN qtdePontos ELSE 0 END) AS qtdePontosPosVida,
            sum(CASE WHEN dtDia >= date('{date}', '7 days') THEN qtdePontos > 0 ELSE 0 END) AS  qtdePontosPosD7,
            sum(CASE WHEN dtDia >= date('{date}', '14 days') THEN qtdePontos > 0  ELSE 0 END) AS  qtdePontosPosD14,
            sum(CASE WHEN dtDia >= date('{date}', '28 days') THEN qtdePontos > 0  ELSE 0 END) AS  qtdePontosPosD28,
            sum(CASE WHEN dtDia >= date('{date}', '56 days') THEN qtdePontos > 0  ELSE 0 END) AS qtdePontosPosD56,

            sum(CASE WHEN qtdePontos < 0 THEN qtdePontos ELSE 0 END) AS qtdePontosNegVida,
            sum(CASE WHEN dtDia >= date('{date}', '7 days') THEN qtdePontos  < 0 ELSE 0 END) AS  qtdePontosNegD7,
            sum(CASE WHEN dtDia >= date('{date}', '14 days') THEN qtdePontos < 0  ELSE 0 END) AS  qtdePontosNegD14,
            sum(CASE WHEN dtDia >= date('{date}', '28 days') THEN qtdePontos < 0  ELSE 0 END) AS  qtdePontosNegD28,
            sum(CASE WHEN dtDia >= date('{date}', '56 days') THEN qtdePontos < 0  ELSE 0 END) AS qtdePontosNegD56,

            count(CASE WHEN dtHora BETWEEN 10 AND 14 THEN IdTransacao END) AS qtdeTransacaoManha,
            count(CASE WHEN dtHora BETWEEN 15 AND 21 THEN IdTransacao END) AS qtdeTransacaoTarde,
            count(CASE WHEN dtHora > 21 OR dtHora < 10 THEN IdTransacao END) AS qtdeTransacaoNoite,
           
            1. * count(CASE WHEN dtHora BETWEEN 10 AND 14 THEN IdTransacao END) / count(IdTransacao) AS pctTransacaoManha,
            1. * count(CASE WHEN dtHora BETWEEN 15 AND 21 THEN IdTransacao END) / count(IdTransacao) AS pctTransacaoTarde,
            1. * count(CASE WHEN dtHora > 21 OR dtHora < 10 THEN IdTransacao END) / count(IdTransacao) AS pctTransacaoNoite


    FROM tb_transacao
    GROUP BY IdCliente
),
    tb_agg_calc as (
    SELECT *,
            COALESCE(1. * qtdeTransacaoVida/qtdeAtivacaoVida,0) AS qtdeTransacaoDiaVida,
            COALESCE(1.* qtdeTransacaoD7/qtdeAtivacaoD7,0) AS qtdeTransacaoDiaD7,
            COALESCE(1.* qtdeTransacaoD14/qtdeAtivacaoD14,0) AS qtdeTransacaoDiaD14,
            COALESCE(1.* qtdeTransacaoD28/qtdeAtivacaoD28,0) AS qtdeTransacaoDiaD28,
            COALESCE(1.* qtdeTransacaoD56/qtdeAtivacaoD56,0) AS qtdeTransacaoDiaD56,
            COALESCE(1.* qtdeAtivacaod28/28, 0) pctAtivacaoMAU
    FROM tb_agg_transacao
),

tb_horas_dia as (
    SELECT 
        idCliente,
        dtDia,
        24 * (max(julianday(DtCriacao)) - min(julianday(DtCriacao))) AS duracao

    FROM tb_transacao
    GROUP BY idCliente,dtDia
),

tb_hora_cliente AS (
    SELECT idCliente,
        sum(duracao) as qtdeHorasVida,
        sum(CASE WHEN dtDia >= date('{date}', '7 days') THEN duracao ELSE 0 END) AS qtdeHorasD7,
        sum(CASE WHEN dtDia >= date('{date}', '14 days') THEN duracao ELSE 0 END) AS qtdeHorasD14,
        sum(CASE WHEN dtDia >= date('{date}', '28 days') THEN duracao ELSE 0 END) AS qtdeHorasD28,
        sum(CASE WHEN dtDia >= date('{date}', '56 days') THEN duracao ELSE 0 END) AS qtdeHorasD56
    FROM tb_horas_dia
    GROUP BY idCliente
),

tb_lag_dia AS (
    SELECT idCliente,
        dtDia,
        LAG(dtDia) OVER (PARTITION by idCliente ORDER BY dtDia) as lagDia
    FROM tb_horas_dia
),
    tb_intervalo_dias AS (
    SELECT 
        idCliente,
        avg(julianday(dtDia) - julianday(lagDia)) AS avgIntervaloDiasVida,
        avg(CASE WHEN dtDia >= date('{date}', '-28 day') THEN julianday(dtDia) - julianday(lagDia) END) AS avgIntervaloDiasD28

    FROM tb_lag_dia
    GROUP BY idCliente
),
share_produtos as (
    SELECT 
        idCliente,

        1. * count(CASE WHEN DescNomeProduto = 'ChatMessage' THEN t1.IdTransacao END) AS qtdeChatMessage,
        1. * count(CASE WHEN DescNomeProduto = 'Airflow Lover' THEN t1.IdTransacao END) AS qtdeAirflowLover,
        1. * count(CASE WHEN DescNomeProduto = 'R Lover' THEN t1.IdTransacao END) AS qtdeRLover,
        1. * count(CASE WHEN DescNomeProduto = 'Resgatar Ponei' THEN t1.IdTransacao END) AS qtdeResgatarPonei,
        1. * count(CASE WHEN DescNomeProduto = 'Lista de presença' THEN t1.IdTransacao END) AS qtdeListadepresença,
        1. * count(CASE WHEN DescNomeProduto = 'Presença Streak' THEN t1.IdTransacao END) AS qtdePresençaStreak,
        1. * count(CASE WHEN DescNomeProduto = 'Troca de Pontos StreamElements' THEN t1.IdTransacao END) AS qtdeTrocadePontosStreamElements,
        1. * count(CASE WHEN DescNomeProduto = 'Reembolso: Troca de Pontos StreamElements' THEN t1.IdTransacao END) AS qtdeReembolsoTrocadePontosStreamElements,
        1. * 
        1. * count(CASE WHEN DescCategoriaProduto = 'rpg' THEN t1.IdTransacao END) AS qtdeRpg,
        1. * count(CASE WHEN DescCategoriaProduto = 'churn_model' THEN t1.IdTransacao END) AS qtdeChurnModel



    FROM tb_transacao as t1

    LEFT JOIN transacao_produto as t2
    ON t1.IdTransacao = t2.IdTransacao

    LEFT JOIN produtos as t3
    ON t2.IdProduto = t3.IdProduto

    GROUP BY idCliente
),

    tb_join as (

    SELECT 
        t1.*,
        t2.qtdeHorasVida,
        t2.qtdeHorasD7,
        t2.qtdeHorasD14,
        t2.qtdeHorasD28,
        t2.qtdeHorasD56,
        t3.avgIntervaloDiasVida,
        t3.avgIntervaloDiasD28,
        t4.qtdeChatMessage,
        t4.qtdeAirflowLover,
        t4.qtdeRLover,
        t4.qtdeResgatarPonei,
        t4.qtdeListadepresença,
        t4.qtdePresençaStreak,
        t4.qtdeTrocadePontosStreamElements,
        t4.qtdeReembolsoTrocadePontosStreamElements,
        t4.qtdeRpg,
        t4.qtdeChurnModel


    FROM tb_agg_calc as t1

    LEFT JOIN tb_hora_cliente as t2
    ON t1.idCliente = t2.idCliente

    LEFT JOIN tb_intervalo_dias as t3
    ON t1.idCliente = t3.idCliente

    LEFT JOIN share_produtos as t4
    ON t1.idCliente = t4.idCliente
)


SELECT date('{date}', '-1 day') AS dtRef,
        *

FROM tb_join