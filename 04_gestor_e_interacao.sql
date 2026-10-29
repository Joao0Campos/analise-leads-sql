/* ============================================================
   04_GESTOR_E_INTERACAO.SQL
   ------------------------------------------------------------
   Substitui o 03. Mesmos leads da aba CONSOLIDADO,
   agora trazendo tambem a data da ultima interacao e o
   idgestor (o codigo numerico por tras do nome).

   Rode um bloco por vez: selecione e Ctrl+Shift+E.
   Confira se a barra de status embaixo mostra CRM_ETL.
   ============================================================ */


/* ------------------------------------------------------------
   BLOCO 1 - A CONSULTA PRINCIPAL
   ------------------------------------------------------------
   Resultado esperado: uma linha por lead da lista, com
   linha_excel na mesma sequencia da planilha. Confira o rodape da grade antes de
   copiar qualquer coisa - se o numero de linhas nao bater,
   a colagem sai desalinhada e o erro passa despercebido.

   Trago "idgestor" junto de "gestor" de proposito. Quando o
   nome vier vazio mas o codigo vier preenchido, o problema e
   na carga do banco (o nome nao foi trazido), nao no lead.
   Quando os dois vierem vazios, o lead realmente nunca teve
   gestor atribuido. Sao causas diferentes.
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
    g.idgestor,
    g.gestor,
    g.gestor_ultimo,
    g.data_ultima_interacao,
    g.situacao,
    g.empreendimento,
    g.data_cad
FROM vendas AS v
OUTER APPLY (
    SELECT TOP 1
        l.idgestor,
        l.gestor,
        l.gestor_ultimo,
        l.data_ultima_interacao,
        l.situacao,
        l.empreendimento,
        l.data_cad
    FROM dbo.Leads AS l
    WHERE l.idlead = v.idlead
    ORDER BY l.referencia_data DESC
) AS g
ORDER BY v.linha_excel;


/* ------------------------------------------------------------
   BLOCO 2 - O TAMANHO DO BURACO
   ------------------------------------------------------------
   Uma linha so, com a contagem de cada campo. Serve para voce
   saber, antes de colar na planilha, quantas celulas vao ficar
   em branco e por que.
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
    COUNT(*)                                                             AS total_de_vendas,
    SUM(CASE WHEN g.idlead   IS NOT NULL THEN 1 ELSE 0 END)              AS lead_existe_na_base,
    SUM(CASE WHEN g.idgestor IS NOT NULL THEN 1 ELSE 0 END)              AS com_idgestor,
    SUM(CASE WHEN g.gestor   IS NOT NULL THEN 1 ELSE 0 END)              AS com_nome_do_gestor,
    SUM(CASE WHEN g.data_ultima_interacao IS NOT NULL THEN 1 ELSE 0 END) AS com_data_interacao
FROM vendas AS v
OUTER APPLY (
    SELECT TOP 1 l.idlead, l.idgestor, l.gestor, l.data_ultima_interacao
    FROM dbo.Leads AS l
    WHERE l.idlead = v.idlead
    ORDER BY l.referencia_data DESC
) AS g;


/* ------------------------------------------------------------
   BLOCO 3 - QUAIS LINHAS FICARAM SEM GESTOR, E POR QUE
   ------------------------------------------------------------
   Lista so as problematicas, ja com o numero da linha do Excel
   e o diagnostico de cada uma.
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
    g.idgestor,
    CASE
        WHEN g.idlead   IS NULL THEN 'lead nao existe na base'
        WHEN g.idgestor IS NULL THEN 'lead sem gestor atribuido'
        ELSE                         'tem codigo de gestor, mas o nome veio vazio'
    END                             AS motivo
FROM vendas AS v
OUTER APPLY (
    SELECT TOP 1 l.idlead, l.idgestor, l.gestor
    FROM dbo.Leads AS l
    WHERE l.idlead = v.idlead
    ORDER BY l.referencia_data DESC
) AS g
WHERE g.idlead IS NULL OR g.gestor IS NULL
ORDER BY v.linha_excel;


/* ------------------------------------------------------------
   BLOCO 4 - QUEM SAO OS GESTORES DESSA CARTEIRA
   ------------------------------------------------------------
   Agrupa os nomes encontrados. Serve para voce ver se aparecem
   nomes genericos de fila (do tipo "GA GESTOR ESTOQUE") no meio
   das pessoas reais, e decidir como trata-los no relatorio.
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
    ISNULL(g.gestor, '(vazio)')     AS gestor,
    COUNT(*)                        AS qtd_vendas
FROM vendas AS v
OUTER APPLY (
    SELECT TOP 1 l.gestor
    FROM dbo.Leads AS l
    WHERE l.idlead = v.idlead
    ORDER BY l.referencia_data DESC
) AS g
GROUP BY ISNULL(g.gestor, '(vazio)')
ORDER BY qtd_vendas DESC;
