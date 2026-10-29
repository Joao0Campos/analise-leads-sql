/* ============================================================
   02_ONDE_ESTOU.SQL  —  descobrir em que banco a consulta roda
   ------------------------------------------------------------
   Rode um bloco por vez: selecione e Ctrl+Shift+E.
   ============================================================ */


/* ------------------------------------------------------------
   1) EM QUE BANCO EU ESTOU AGORA?
   ------------------------------------------------------------
   Se responder "master" (ou qualquer coisa diferente de
   CRM_ETL), achamos a causa do erro "Nome de objeto inválido".
------------------------------------------------------------ */
SELECT DB_NAME() AS banco_atual;


/* ------------------------------------------------------------
   2) A SOLUÇÃO MAIS SIMPLES: TROCAR DE BANCO
   ------------------------------------------------------------
   USE = "a partir de agora, trabalhe neste banco".
   Vale para a janela/conexão atual.

   Rode este bloco e depois volte para o 01_leads.sql:
   as consultas de lá vão funcionar sem alterar nada.
------------------------------------------------------------ */
USE CRM_ETL;


/* ------------------------------------------------------------
   3) CONFIRMANDO QUE A TROCA FUNCIONOU
------------------------------------------------------------ */
SELECT DB_NAME() AS banco_atual;


/* ------------------------------------------------------------
   4) SE AINDA ASSIM NÃO ACHAR A TABELA
   ------------------------------------------------------------
   Aqui a gente procura o objeto pelo nome, sem supor nada.
   Pode ser que ela se chame um pouco diferente, esteja em
   outro esquema (não "dbo"), ou seja uma VIEW em vez de tabela.
------------------------------------------------------------ */
SELECT
    TABLE_CATALOG                   AS banco,
    TABLE_SCHEMA                    AS esquema,
    TABLE_NAME                      AS objeto,
    TABLE_TYPE                      AS tipo
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME LIKE '%ead%'
ORDER BY esquema, objeto;


/* ------------------------------------------------------------
   5) ALTERNATIVA: NOME COMPLETO, SEM DEPENDER DO "USE"
   ------------------------------------------------------------
   Escrevendo banco.esquema.tabela, funciona de qualquer lugar.
   Serve como teste definitivo de que a tabela existe.
------------------------------------------------------------ */
SELECT COUNT(*) AS total_de_leads
FROM CRM_ETL.dbo.Leads;
