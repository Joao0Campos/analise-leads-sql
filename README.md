# Análise de Leads em SQL Server

Seis scripts T-SQL, em sequência, que substituíram uma análise de leads de CRM feita no Excel. A planilha travava ao importar a base inteira, que tinha centenas de milhares de linhas. Com os scripts, a agregação roda no servidor e só o resultado volta para o usuário. Eles também resolvem um "PROCV" de gestor por lead direto no banco.

## Problema

- Relatórios de leads eram montados exportando a tabela de leads (80 colunas) para o Excel e filtrando lá. O volume travava a planilha e obrigava a recortar por data.
- Para uma lista de vendas válidas, era preciso descobrir o gestor e a data da última interação de cada lead. A tabela guarda várias "fotos" do mesmo lead ao longo do tempo, e por isso um PROCV simples podia trazer a linha errada sem avisar.

## Solução

| Script | O que faz |
|---|---|
| `00_diagnostico.sql` | Reconhecimento da base: servidor/banco atuais, permissões do usuário (`sys.fn_my_permissions`), tabelas ordenadas por tamanho, busca de objetos por nome, colunas de uma tabela e procedures existentes |
| `01_leads.sql` | Agregações sobre a base inteira, sem filtro de data: totais e período, leads por ano/mês, por situação, ano × situação, top 20 empreendimentos com contagem condicional de reservas, recortes com `WHERE` e uma consulta de conferência contra o arquivo exportado |
| `02_onde_estou.sql` | Diagnóstico do erro "Nome de objeto inválido": banco atual, `USE`, busca em `INFORMATION_SCHEMA.TABLES` e nome totalmente qualificado (`banco.esquema.tabela`) |
| `03_gestor_por_lead.sql` | "PROCV em SQL": para uma lista de leads, traz o gestor da foto mais recente de cada um. Antes, testa se a tabela tem mais de uma linha por lead |
| `04_gestor_e_interacao.sql` | Evolução do 03, em quatro blocos: consulta principal (com `idgestor` e data da última interação), contagem de campos preenchidos, linhas problemáticas com o motivo e distribuição por gestor |
| `05_para_excel.sql` | A consulta do 04 com a saída pronta para colar no Excel em pt-BR (`FORMAT` dd/MM/yyyy, `ISNULL` → célula vazia) |

## Técnicas usadas

- **Contagem de linhas sem varrer as tabelas:** soma `sys.partitions.rows` com `index_id IN (0, 1)` (heap ou índice clustered), o que evita contar em duplicidade e responde na hora mesmo em tabelas grandes.
- **Agregar no servidor:** `GROUP BY` com `COUNT` e `SUM(CASE WHEN ... THEN 1 ELSE 0 END)` para contagens condicionais, e `TOP N` aplicado sobre o resultado agregado.
- **Lista de consulta inline:** uma CTE com *table value constructor* (`VALUES`) carrega os pares `(linha_excel, idlead)` sem precisar criar tabela no banco, o que funciona com acesso só de leitura.
- **Última versão de cada registro:** `OUTER APPLY (SELECT TOP 1 ... ORDER BY referencia_data DESC)` pega a foto mais recente do lead.
  - O `OUTER` mantém os leads sem correspondência, com campos nulos, em vez de descartá-los.
  - Junto com o `ORDER BY linha_excel`, preserva o alinhamento com a planilha de origem.
- **Diagnóstico das lacunas:** um `CASE` separa as causas: lead inexistente, lead sem gestor atribuído, ou código de gestor presente com nome vazio (problema de carga).
- **Saída compatível com o Excel brasileiro:** `FORMAT(data, 'dd/MM/yyyy HH:mm')` evita que datas ISO com 7 casas fracionárias sejam importadas como texto.

## Como rodar

Requisitos: SQL Server e um cliente (SSMS, Azure Data Studio ou a extensão MSSQL do VS Code), com permissão de leitura na base de leads.

1. Rode `00_diagnostico.sql` e `02_onde_estou.sql` para confirmar o servidor, o banco e a tabela.
2. Ajuste o nome do banco (`CRM_ETL`, um placeholder) e, se for o caso, o nome da tabela (`dbo.Leads`).
3. Execute **um bloco por vez**: selecione o bloco e execute (F5 no SSMS; Ctrl+Shift+E na extensão MSSQL do VS Code).
4. Nos scripts 03 a 05, substitua a lista ilustrativa de `VALUES` pelos pares `(linha_excel, idlead)` da sua planilha.

Todos os scripts só fazem leitura, exceto o `USE` do 02, que apenas troca o banco da sessão.

Colunas de `dbo.Leads` referenciadas: `idlead`, `data_cad`, `situacao`, `origem`, `empreendimento`, `corretor`, `imobiliaria`, `cidade`, `estado`, `reserva`, `data_cancelamento`, `ultima_data_conversao`, `referencia_data`, `gestor`, `gestor_ultimo`, `idgestor` e `data_ultima_interacao`.

## Estrutura

```
00_diagnostico.sql
01_leads.sql
02_onde_estou.sql
03_gestor_por_lead.sql
04_gestor_e_interacao.sql
05_para_excel.sql
```

## Limitações conhecidas

- A lista de leads é repetida em cada bloco dos scripts 03 e 04: cada bloco é autocontido para poder ser executado isoladamente.
- Os scripts dependem do esquema específico da tabela `dbo.Leads` do CRM (nomes de colunas acima).
- São scripts de análise *ad hoc*, comentados em tom didático. Não são procedures parametrizadas nem fazem parte de um pipeline.

## Sobre a confidencialidade

Os scripts vieram de um trabalho real com uma base de CRM corporativa e foram higienizados para publicação:

- o endereço do servidor virou `<SERVIDOR_SQL>`, e o nome do banco virou `CRM_ETL`;
- as listas de IDs reais de leads foram substituídas por cinco IDs fictícios;
- volumes e totais reais da base foram retirados dos comentários.

A lógica das consultas está intacta. Planilhas de entrada e de saída não fazem parte do repositório.
