/* ============================================================
   05_PARA_EXCEL.SQL
   ------------------------------------------------------------
   Mesma consulta do 04, com o resultado ja formatado para
   colar no Excel brasileiro:

     - datas em dd/MM/aaaa hh:mm  (o Excel reconhece como data)
     - vazios como celula em branco, nao como a palavra NULL

   Por que isso era preciso: o SQL Server entrega data no
   formato ISO com 7 casas de segundo (2026-01-17 09:21:02.0000000).
   O Excel em portugues nao reconhece esse formato e guarda como
   texto - por isso os valores ficavam grudados a esquerda da
   celula e nao davam para ordenar nem filtrar por periodo.

   FORMAT() reescreve a data no padrao brasileiro.
   ISNULL() troca o vazio do banco por texto em branco.
   ============================================================ */


/* ------------------------------------------------------------
   BLOCO UNICO - PRONTO PARA COLAR
   ------------------------------------------------------------
   Uma linha por lead da lista, na ordem de linha_excel.
   Confira o total no rodape da grade antes de copiar.
------------------------------------------------------------ */
WITH vendas (linha_excel, idlead) AS (
    SELECT * FROM (VALUES
        -- Lista ILUSTRATIVA com IDs ficticios. No uso real, cole aqui os pares
        -- (linha_excel, idlead) da planilha de vendas, um por linha.
        (   2,   100001),
        (   3,   100002),
        (   4,   100003),
        (   5,   100004),
        (   6,   100005)
    ) AS t(linha_excel, idlead)
)
SELECT
    v.linha_excel,
    v.idlead,
    ISNULL(g.gestor, '')                                              AS gestor,
    ISNULL(FORMAT(g.data_ultima_interacao, 'dd/MM/yyyy HH:mm'), '')   AS ultima_interacao,
    ISNULL(FORMAT(g.data_cad,              'dd/MM/yyyy'),        '')  AS data_cadastro,
    ISNULL(g.situacao, '')                                            AS situacao,
    ISNULL(g.empreendimento, '')                                      AS empreendimento
FROM vendas AS v
OUTER APPLY (
    SELECT TOP 1
        l.gestor,
        l.data_ultima_interacao,
        l.data_cad,
        l.situacao,
        l.empreendimento
    FROM dbo.Leads AS l
    WHERE l.idlead = v.idlead
    ORDER BY l.referencia_data DESC
) AS g
ORDER BY v.linha_excel;
