/* ============================================================
   03_GESTOR_POR_LEAD.SQL
   ------------------------------------------------------------
   OBJETIVO: para cada lead da aba CONSOLIDADO da planilha
   VENDAS VALIDAS, buscar o nome do gestor no banco.

   Isto e um PROCV, escrito em SQL. A diferenca:
   o PROCV precisa da tabela de consulta aberta no Excel;
   aqui a tabela de centenas de milhares de linhas fica no
   servidor e so voltam as respostas que voce pediu.

   Rode um bloco por vez: selecione e Ctrl+Shift+E.
   Confira se a barra de status embaixo mostra CRM_ETL.
   ============================================================ */


/* ------------------------------------------------------------
   BLOCO 1 - DIAGNOSTICO: a base tem um lead por linha?
   ------------------------------------------------------------
   A tabela dbo.Leads tem colunas "referencia" e
   "referencia_data", o que sugere que ela guarda varias
   fotos do mesmo lead ao longo do tempo.

   Se "linhas" e "leads_distintos" derem numeros diferentes,
   existe mais de uma linha por lead - e ai precisamos dizer
   qual delas queremos, senao um PROCV traria a resposta
   errada sem avisar. O Bloco 2 ja resolve isso pegando a
   foto mais recente de cada lead.
------------------------------------------------------------ */
SELECT
    COUNT(*)                        AS linhas,
    COUNT(DISTINCT idlead)          AS leads_distintos
FROM dbo.Leads;


/* ------------------------------------------------------------
   BLOCO 2 - A CONSULTA PRINCIPAL
   ------------------------------------------------------------
   A lista abaixo e a coluna C (LEADS) da sua planilha, com o
   numero da linha do Excel do lado. O resultado volta na mesma
   ordem das linhas - entao a coluna "gestor" pode ser copiada
   e colada direto em E2, sem PROCV nenhum no Excel.

   OUTER APPLY + TOP 1 = "para cada lead da minha lista,
   pegue UMA linha da base, a mais recente". O OUTER garante
   que leads sem correspondencia apareçam mesmo assim, com
   gestor vazio, em vez de sumirem da lista e desalinharem tudo.

   Trago tambem "gestor_ultimo", porque a base tem dois campos
   parecidos. Compare as duas colunas: se forem diferentes em
   varias linhas, me avise que a gente decide qual e o certo
   para o seu relatorio.
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
    g.gestor,
    g.gestor_ultimo,
    g.situacao,
    g.empreendimento
FROM vendas AS v
OUTER APPLY (
    SELECT TOP 1
        l.gestor,
        l.gestor_ultimo,
        l.situacao,
        l.empreendimento
    FROM dbo.Leads AS l
    WHERE l.idlead = v.idlead
    ORDER BY l.referencia_data DESC
) AS g
ORDER BY v.linha_excel;


/* ------------------------------------------------------------
   BLOCO 3 - QUANTOS NAO FORAM ENCONTRADOS?
   ------------------------------------------------------------
   Roda a mesma busca e conta os acertos. Serve para voce saber
   o tamanho do problema antes de olhar linha a linha.
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
    COUNT(*)                                                    AS total_de_vendas,
    SUM(CASE WHEN g.gestor IS NOT NULL THEN 1 ELSE 0 END)       AS com_gestor,
    SUM(CASE WHEN g.gestor IS NULL     THEN 1 ELSE 0 END)       AS sem_gestor
FROM vendas AS v
OUTER APPLY (
    SELECT TOP 1 l.gestor
    FROM dbo.Leads AS l
    WHERE l.idlead = v.idlead
    ORDER BY l.referencia_data DESC
) AS g;
