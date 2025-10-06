WITH tb_usuario_cursos AS (
    SELECT 
        idUsuario,
        descSlugCurso,
        count(descSlugCursoEpisodio) as qtdeEps

    FROM cursos_episodios_completos
    WHERE dtCriacao < '2025-09-01'
    GROUP BY idUsuario, descSlugCurso
),
tb_cursos_total_eps as (

    SELECT descSlugCurso,
            count(descEpisodio) AS qtdeTotalEps

    FROM cursos_episodios

    GROUP by descSlugCurso
),
tb_pct_cursos as (

    SELECT t1.idUsuario,
            t1.descSlugCurso,
            1. * t1.qtdeEps/t2.qtdeTotalEps as pctCursoCompleto

    FROM tb_usuario_cursos as t1

    LEFT JOIN tb_cursos_total_eps as t2
    ON t1.descSlugCurso = t2.descSlugCurso

    GROUP BY t1.idUsuario
),
tb_pct_cursos_pivot as (

    SELECT 
        idUsuario,

        sum(CASE WHEN pctCursoCompleto = 1 THEN 1 ELSE 0 END) as qtdeCursosCompletos,
        SUM(CASE WHEN pctCursoCompleto > 0 and pctCursoCompleto < 1 then 1 else 0 end) AS qtdeCursosIncompletos,
        sum(CASE WHEN  descSlugCurso = 'carreira' THEN pctCursoCompleto ELSE 0 END) AS carreira,
        sum(CASE WHEN  descSlugCurso = 'coleta-dados-2024' THEN pctCursoCompleto ELSE 0 END) AS coletadados2024,
        sum(CASE WHEN  descSlugCurso = 'ds-databricks-2024' THEN pctCursoCompleto ELSE 0 END) AS dsdatabricks2024,
        sum(CASE WHEN  descSlugCurso = 'ds-pontos-2024' THEN pctCursoCompleto ELSE 0 END) AS dspontos2024,
        sum(CASE WHEN  descSlugCurso = 'estatistica-2024' THEN pctCursoCompleto ELSE 0 END) AS estatistica2024,
        sum(CASE WHEN  descSlugCurso = 'estatistica-2025' THEN pctCursoCompleto ELSE 0 END) AS estatistica2025,
        sum(CASE WHEN  descSlugCurso = 'github-2024' THEN pctCursoCompleto ELSE 0 END) AS github2024,
        sum(CASE WHEN  descSlugCurso = 'github-2025' THEN pctCursoCompleto ELSE 0 END) AS github2025,
        sum(CASE WHEN  descSlugCurso = 'ia-canal-2025' THEN pctCursoCompleto ELSE 0 END) AS iacanal2025,
        sum(CASE WHEN  descSlugCurso = 'lago-mago-2024' THEN pctCursoCompleto ELSE 0 END) AS lagomago2024,
        sum(CASE WHEN  descSlugCurso = 'machine-learning-2025' THEN pctCursoCompleto ELSE 0 END) AS machinelearning2025,
        sum(CASE WHEN  descSlugCurso = 'matchmaking-trampar-de-casa-2024' THEN pctCursoCompleto ELSE 0 END) AS matchmakingtrampardecasa2024,
        sum(CASE WHEN  descSlugCurso = 'ml-2024' THEN pctCursoCompleto ELSE 0 END) AS ml2024,
        sum(CASE WHEN  descSlugCurso = 'mlflow-2025' THEN pctCursoCompleto ELSE 0 END) AS mlflow2025,
        sum(CASE WHEN  descSlugCurso = 'pandas-2024' THEN pctCursoCompleto ELSE 0 END) AS pandas2024,
        sum(CASE WHEN  descSlugCurso = 'pandas-2025' THEN pctCursoCompleto ELSE 0 END) AS pandas2025,
        sum(CASE WHEN  descSlugCurso = 'python-2024' THEN pctCursoCompleto ELSE 0 END) AS python2024,
        sum(CASE WHEN  descSlugCurso = 'python-2025' THEN pctCursoCompleto ELSE 0 END) AS python2025,
        sum(CASE WHEN  descSlugCurso = 'sql-2020' THEN pctCursoCompleto ELSE 0 END) AS sql2020,
        sum(CASE WHEN  descSlugCurso = 'sql-2025' THEN pctCursoCompleto ELSE 0 END) AS sql2025,
        sum(CASE WHEN  descSlugCurso = 'streamlit-2025' THEN pctCursoCompleto ELSE 0 END) AS streamlit2025,
        sum(CASE WHEN  descSlugCurso = 'trampar-lakehouse-2024' THEN pctCursoCompleto ELSE 0 END) AS tramparlakehouse2024,
        sum(CASE WHEN  descSlugCurso = 'tse-analytics-2024' THEN pctCursoCompleto ELSE 0 END) AS tseanalytics2024


    FROM tb_pct_cursos
    GROUP BY idUsuario
),

tb_atividade as (

    SELECT 
        idUsuario,
        max(dtRecompensa) as dtCriacao

    FROM recompensas_usuarios
    WHERE dtRecompensa < '2025-09-01'
    GROUP BY idUsuario

    UNION ALL

    SELECT 
        idUsuario,
        max(dtCriacao) as dtCriacao

    FROM habilidades_usuarios
    WHERE dtCriacao < '2025-09-01'
    GROUP BY idUsuario

    UNION ALL

    SELECT
        idUsuario,
        max(dtCriacao) as dtCriacao

    FROM cursos_episodios_completos
    WHERE dtCriacao < '2025-09-01'
    GROUP BY idUsuario
),

tb_ultima_atividade as (

    SELECT idUsuario,
        min(julianday('2025-10-01') - julianday(dtCriacao)) AS qtdDiasUltiAtividade

    FROM tb_atividade
    GROUP BY idUsuario
),
tb_join as (

    SELECT 
        t3.idTMWCliente AS idCliente,
        t1.qtdeCursosCompletos,
        t1.qtdeCursosIncompletos,
        t1.carreira,
        t1.coletaDados2024,
        t1.dsDatabricks2024,
        t1.dsPontos2024,
        t1.estatistica2024,
        t1.estatistica2025,
        t1.github2024,
        t1.github2025,
        t1.iaCanal2025,
        t1.lagoMago2024,
        t1.machineLearning2025,
        t1.matchmakingTramparDeCasa2024,
        t1.ml2024,
        t1.mlflow2025,
        t1.pandas2024,
        t1.pandas2025,
        t1.python2024,
        t1.python2025,
        t1.sql2020,
        t1.sql2025,
        t1.streamlit2025,
        t1.tramparLakehouse2024,
        t1.tseAnalytics2024,
        t2.qtdDiasUltiAtividade

    FROM tb_pct_cursos_pivot as t1

    LEFT JOIN tb_ultima_atividade AS t2
    ON t1.idUsuario = t2.idUsuario

    INNER JOIN usuarios_tmw as t3
    ON t1.idUsuario = t3.idUsuario
)

SELECT date('2025-10-01', '-1 day') AS dtRef,
        *
FROM tb_join