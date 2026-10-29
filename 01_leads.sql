/* ============================================================
   01_LEADS.SQL  —  consultando a base inteira, sem filtro de data
   ------------------------------------------------------------
   Servidor : <SERVIDOR_SQL>
   Banco    : CRM_ETL
   Tabela   : dbo.Leads   (80 colunas)

   Rode UM bloco por vez: selecione com o mouse e Ctrl+Enter.

   A IDEIA CENTRAL deste arquivo, e a única coisa que você
   precisa levar daqui:

       Não traga LINHAS. Traga RESULTADO.

   O Excel travava porque puxava dezenas (ou centenas) de milhares
   de linhas para o seu PC. O SQL faz a conta no servidor e te devolve
   20 linhas prontas. Por isso você não precisa mais de filtro
   de data: não é o tamanho da base que pesa, é o tanto de linha
   que trafega até você.
   ============================================================ */


/* ------------------------------------------------------------
   A) QUAL É O TAMANHO REAL DESSA BASE?
   ------------------------------------------------------------
   Primeira coisa a saber. Responde em segundos.
   COUNT(*) = "conte as linhas". MIN/MAX = a data mais antiga
   e a mais nova. Isso te diz o período que a base cobre.
------------------------------------------------------------ */
SELECT
    COUNT(*)                        AS total_de_leads,
    MIN(data_cad)                   AS lead_mais_antigo,
    MAX(data_cad)                   AS lead_mais_recente
FROM dbo.Leads;


/* ------------------------------------------------------------
   B) LEADS POR ANO E MÊS — A BASE TODA
   ------------------------------------------------------------
   Esta é a consulta que substitui o que você fazia no Excel.
   Repare: não tem WHERE. Nenhum filtro de data. Ela varre
   a base inteira e volta com uma linha por mês.

   YEAR()  extrai o ano de uma data.
   MONTH() extrai o mês.
   GROUP BY  = "agrupe por". É o Tabela Dinâmica do SQL:
              o que está no GROUP BY vira as linhas,
              o COUNT(*) vira o valor.
------------------------------------------------------------ */
SELECT
    YEAR(data_cad)                  AS ano,
    MONTH(data_cad)                 AS mes,
    COUNT(*)                        AS qtd_leads
FROM dbo.Leads
GROUP BY YEAR(data_cad), MONTH(data_cad)
ORDER BY ano, mes;


/* ------------------------------------------------------------
   C) LEADS POR SITUAÇÃO
   ------------------------------------------------------------
   Mesma lógica, trocando o que vai no GROUP BY.
   Troque "situacao" por origem, empreendimento, corretor,
   imobiliaria, estado, cidade... qualquer coluna de texto.
------------------------------------------------------------ */
SELECT
    situacao,
    COUNT(*)                        AS qtd_leads
FROM dbo.Leads
GROUP BY situacao
ORDER BY qtd_leads DESC;


/* ------------------------------------------------------------
   D) CRUZANDO DUAS COISAS (ano x situação)
   ------------------------------------------------------------
   É só colocar as duas colunas no SELECT e as duas no GROUP BY.
   Regra que nunca muda: toda coluna do SELECT que NÃO está
   dentro de COUNT/SUM/AVG precisa estar no GROUP BY.
------------------------------------------------------------ */
SELECT
    YEAR(data_cad)                  AS ano,
    situacao,
    COUNT(*)                        AS qtd_leads
FROM dbo.Leads
GROUP BY YEAR(data_cad), situacao
ORDER BY ano, qtd_leads DESC;


/* ------------------------------------------------------------
   E) O RANKING QUE O EXCEL NÃO DAVA CONTA
   ------------------------------------------------------------
   Top 20 empreendimentos da base inteira.
   TOP 20 = só as 20 primeiras linhas DO RESULTADO
   (depois de somar tudo) — não confunda com filtrar a base.
------------------------------------------------------------ */
SELECT TOP 20
    empreendimento,
    COUNT(*)                        AS qtd_leads,
    SUM(CASE WHEN reserva IS NOT NULL THEN 1 ELSE 0 END) AS com_reserva
FROM dbo.Leads
GROUP BY empreendimento
ORDER BY qtd_leads DESC;


/* ------------------------------------------------------------
   F) FILTRANDO DE VERDADE (quando você QUER um recorte)
   ------------------------------------------------------------
   WHERE filtra ANTES de agrupar. Alguns exemplos úteis:

       WHERE data_cad >= '2026-01-01'          -- de 2026 pra cá
       WHERE situacao = 'Em atendimento'       -- texto: aspas simples
       WHERE origem IN ('Site', 'Facebook')    -- vários valores
       WHERE nome LIKE 'Jo%'                   -- começa com "Jo"
       WHERE data_cancelamento IS NULL         -- campo vazio
                                               -- (vazio é IS NULL,
                                               --  nunca = NULL)

   Formato de data no SQL Server: sempre 'AAAA-MM-DD'.
------------------------------------------------------------ */
SELECT
    origem,
    COUNT(*)                        AS qtd_leads
FROM dbo.Leads
WHERE data_cad >= '2026-01-01'
  AND data_cancelamento IS NULL
GROUP BY origem
ORDER BY qtd_leads DESC;


/* ------------------------------------------------------------
   G) REPRODUZINDO O SEU ARQUIVO ATUAL (para conferência)
   ------------------------------------------------------------
   O seu Pasta1.xlsx tem o filtro "mês de ultima_data_conversao
   igual a 9". Ele traz SETEMBRO DE TODOS OS ANOS — não um ano.
   A consulta abaixo faz exatamente a mesma coisa.

   Se o total bater com o numero de linhas do seu arquivo,
   está provado que estamos lendo a mesma base do mesmo jeito,
   e você pode confiar em tudo que vier depois.
------------------------------------------------------------ */
SELECT
    YEAR(ultima_data_conversao)     AS ano,
    COUNT(*)                        AS qtd_leads
FROM dbo.Leads
WHERE MONTH(ultima_data_conversao) = 9
GROUP BY YEAR(ultima_data_conversao)
ORDER BY ano;

/*  Esperado: um total por ano que, somado, bate com o numero de
    linhas do arquivo exportado. Fique de olho em anos como 1900:
    costumam indicar data invalida/padrao na origem.            */


/* ------------------------------------------------------------
   H) SÓ DEPOIS DE TUDO ISSO: OLHANDO LINHA A LINHA
   ------------------------------------------------------------
   Quando você precisar mesmo ver os registros, escolha as
   colunas. Não use SELECT * numa base grande: são 80 colunas,
   e a maioria você não vai olhar.
------------------------------------------------------------ */
SELECT TOP 100
    idlead,
    data_cad,
    situacao,
    origem,
    empreendimento,
    corretor,
    imobiliaria,
    cidade,
    estado
FROM dbo.Leads
WHERE data_cad >= '2026-09-01'
ORDER BY data_cad DESC;
