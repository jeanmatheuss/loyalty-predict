SELECT substr(DtCriacao,0,11) as DtDia,
        count(DISTINCT idCliente) AS DAU

FROM transacoes 
GROUP BY 1
ORDER BY DtDia