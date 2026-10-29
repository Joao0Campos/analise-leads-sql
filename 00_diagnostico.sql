/* ============================================================
   00_DIAGNOSTICO.SQL  —  primeiro contato com a base
   ------------------------------------------------------------
   Como usar: rode UMA consulta por vez.
   Selecione o bloco com o mouse e aperte Ctrl+Enter (ou F5).
   Se rodar o arquivo inteiro de uma vez, vem tudo junto e
   fica difícil de ler.

   Nenhuma consulta aqui altera nada. É tudo leitura.
   ============================================================ */


/* ------------------------------------------------------------
   1) ESTOU CONECTADO? EM QUE SERVIDOR E EM QUE BANCO?
   ------------------------------------------------------------
   Esse é o "alô, está me ouvindo?" do SQL.
   Se isso responder, a conexão está de pé.
------------------------------------------------------------ */
SELECT
    @@SERVERNAME        AS servidor,
    DB_NAME()           AS banco_atual,
    @@VERSION           AS versao_do_sql_server;


/* ------------------------------------------------------------
   2) QUEM SOU EU AQUI DENTRO E O QUE EU POSSO FAZER?
   ------------------------------------------------------------
   Responde a dúvida "meu acesso é só leitura?".
   Olhe a coluna "permissao": se aparecer só SELECT / VIEW,
   você é leitor. Se aparecer INSERT, UPDATE ou DELETE,
   você também consegue gravar — e aí é bom ter cuidado.
------------------------------------------------------------ */
SELECT
    SUSER_NAME()        AS login_no_servidor,
    USER_NAME()         AS usuario_no_banco;

SELECT DISTINCT
    permission_name     AS permissao
FROM sys.fn_my_permissions(NULL, 'DATABASE')
ORDER BY permissao;


/* ------------------------------------------------------------
   3) O QUE TEM NESTE BANCO? (com o tamanho de cada tabela)
   ------------------------------------------------------------
   Essa é a consulta mais útil do arquivo.
   Ela lista as tabelas JÁ ORDENADAS DA MAIOR PARA A MENOR,
   com a quantidade de linhas de cada uma.

   Detalhe importante: ela NÃO varre as tabelas. Ela lê uma
   estatística que o SQL Server já mantém pronta. Por isso
   responde na hora, mesmo numa base gigante — enquanto um
   SELECT COUNT(*) numa tabela de 80 milhões de linhas pode
   demorar minutos.
------------------------------------------------------------ */
SELECT
    SCHEMA_NAME(t.schema_id)        AS esquema,
    t.name                          AS tabela,
    SUM(p.rows)                     AS qtd_linhas
FROM sys.tables AS t
INNER JOIN sys.partitions AS p
        ON p.object_id = t.object_id
       AND p.index_id IN (0, 1)   -- 0 = heap, 1 = índice clustered. Evita contar em duplicidade.
GROUP BY SCHEMA_NAME(t.schema_id), t.name
ORDER BY qtd_linhas DESC;


/* ------------------------------------------------------------
   4) ONDE ESTÃO OS LEADS?
   ------------------------------------------------------------
   Procura a palavra "lead" em nomes de tabelas E de views.
   Troque 'lead' por outra palavra se a sua empresa usa outro
   termo (prospect, contato, oportunidade, cliente...).

   O % é o coringa do SQL — equivale ao * do Windows.
   '%lead%' = "qualquer coisa, lead, qualquer coisa".
------------------------------------------------------------ */
SELECT
    SCHEMA_NAME(schema_id)          AS esquema,
    name                            AS objeto,
    type_desc                       AS tipo        -- USER_TABLE ou VIEW
FROM sys.objects
WHERE type IN ('U', 'V')            -- U = tabela, V = view
  AND name LIKE '%lead%'
ORDER BY tipo, objeto;


/* ------------------------------------------------------------
   5) QUAIS SÃO AS COLUNAS DE UMA TABELA ESPECÍFICA?
   ------------------------------------------------------------
   Depois que o passo 4 te der o nome certo, troque
   'NOME_DA_TABELA' abaixo e rode. É o equivalente a olhar
   o cabeçalho da planilha antes de mexer nela.
------------------------------------------------------------ */
SELECT
    c.name                          AS coluna,
    ty.name                         AS tipo_do_dado,
    c.max_length                    AS tamanho,
    CASE WHEN c.is_nullable = 1
         THEN 'pode ficar vazio'
         ELSE 'obrigatório'
    END                             AS aceita_vazio
FROM sys.columns AS c
INNER JOIN sys.types AS ty
        ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID('NOME_DA_TABELA')   -- <<< troque aqui
ORDER BY c.column_id;


/* ------------------------------------------------------------
   6) ESPIADA NOS DADOS (as 100 primeiras linhas)
   ------------------------------------------------------------
   NUNCA rode "SELECT * FROM tabela" sem o TOP numa base
   pesada — é exatamente isso que trava o Excel.
   O TOP 100 manda o servidor parar depois de 100 linhas.
------------------------------------------------------------ */
SELECT TOP 100 *
FROM NOME_DA_TABELA;                              -- <<< troque aqui


/* ------------------------------------------------------------
   7) QUAIS STORED PROCEDURES EXISTEM?
   ------------------------------------------------------------
   Você mencionou "procs". Isso lista as que existem no banco.
   Para ver o código de uma delas depois:
       EXEC sp_helptext 'nome_da_proc';
------------------------------------------------------------ */
SELECT
    SCHEMA_NAME(schema_id)          AS esquema,
    name                            AS procedure_name,
    create_date                     AS criada_em,
    modify_date                     AS alterada_em
FROM sys.procedures
ORDER BY modify_date DESC;
