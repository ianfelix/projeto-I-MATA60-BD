# Análise de Dados - Sistema de Agendamento Terapêutico

## 1. Perguntas Analíticas

### 1.1 Performance dos Terapeutas [RF13]

1. **Qual a taxa de conversão de agendamentos em sessões realizadas por terapeuta?**

   - View: `mvw_taxa_conversao`
   - Gráfico: Barras horizontais com % de conversão
   - Atualização: Diária
   - Filtros: Período, Especialidade

2. **Qual o ticket médio e receita total por especialidade?**

   - View: `mvw_receita_especialidade`
   - Gráfico: Barras empilhadas (receita) + linha (ticket)
   - Atualização: Semanal
   - Filtros: Mês, Ano

3. **Quais os horários mais populares por dia da semana?**
   - View: `mvw_horarios_pico`
   - Gráfico: Heatmap (dia x hora)
   - Atualização: Mensal
   - Filtros: Especialidade, Cidade

### 1.2 Retenção e Satisfação [RF14]

4. **Qual o índice de retenção de pacientes por terapeuta?**

   - View: `mvw_retencao_pacientes`
   - Gráfico: Funil de retenção
   - Atualização: Mensal
   - Filtros: Período, Especialidade

5. **Qual a média de avaliações por especialidade?**

   - View: `mvw_avaliacoes_especialidade`
   - Gráfico: Radar (nota média)
   - Atualização: Semanal
   - Filtros: Período

6. **Qual o tempo médio entre sessões por paciente?**
   - View: `mvw_intervalo_sessoes`
   - Gráfico: Histograma
   - Atualização: Mensal
   - Filtros: Terapeuta, Especialidade

### 1.3 Operacional [RF13]

7. **Qual a taxa de cancelamento por período do dia?**

   - View: `mvw_cancelamentos_periodo`
   - Gráfico: Pizza
   - Atualização: Diária
   - Filtros: Mês, Especialidade

8. **Quais terapeutas têm maior crescimento de novos pacientes?**
   - View: `mvw_crescimento_pacientes`
   - Gráfico: Linha temporal
   - Atualização: Mensal
   - Filtros: Período, Cidade

### 1.4 Financeiro [RF14]

9. **Qual a distribuição de métodos de pagamento por faixa de valor?**

   - View: `mvw_metodos_pagamento`
   - Gráfico: Barras empilhadas %
   - Atualização: Semanal
   - Filtros: Período

10. **Qual o tempo médio de confirmação de agendamento?**
    - View: `mvw_tempo_confirmacao`
    - Gráfico: Gauge
    - Atualização: Diária
    - Filtros: Terapeuta

## 2. Views Materializadas

### 2.1 Horários Populares (Base)

```sql
CREATE MATERIALIZED VIEW mvw_horarios_populares AS
SELECT
    DATE(data_hora) as data,
    EXTRACT(DOW FROM data_hora) as dia_semana,
    EXTRACT(HOUR FROM data_hora) as hora,
    COUNT(*) as total_agendamentos
FROM sessao s
GROUP BY data, dia_semana, hora
ORDER BY total_agendamentos DESC;
```

### 2.2 Taxa de Conversão

```sql
CREATE MATERIALIZED VIEW mvw_taxa_conversao AS
SELECT
    t.nome as terapeuta,
    COUNT(s.cp_id_sessao) as total_agendamentos,
    COUNT(CASE WHEN s.status = 'realizada' THEN 1 END) as sessoes_realizadas,
    ROUND((COUNT(CASE WHEN s.status = 'realizada' THEN 1 END)::decimal /
           NULLIF(COUNT(s.cp_id_sessao), 0) * 100), 2) as taxa_conversao
FROM terapeuta t
LEFT JOIN sessao s ON s.ce_id_terapeuta = t.cp_id_terapeuta
GROUP BY t.cp_id_terapeuta, t.nome;
```

### 2.3 Receita por Especialidade

```sql
CREATE MATERIALIZED VIEW mvw_receita_especialidade AS
SELECT
    e.nome as especialidade,
    COUNT(DISTINCT s.cp_id_sessao) as total_sessoes,
    ROUND(AVG(p.valor)::decimal, 2) as ticket_medio,
    SUM(p.valor) as receita_total
FROM especialidade e
JOIN terapeuta_especialidade te ON te.ce_id_especialidade = e.cp_id_especialidade
JOIN sessao s ON s.ce_id_terapeuta = te.ce_id_terapeuta
JOIN pagamento p ON p.ce_id_sessao = s.cp_id_sessao
WHERE p.status = 'confirmado'
GROUP BY e.cp_id_especialidade, e.nome;
```

### 2.4 Horários de Pico

```sql
CREATE MATERIALIZED VIEW mvw_horarios_pico AS
SELECT
    CASE dia_semana::integer
        WHEN 0 THEN 'Domingo'
        WHEN 1 THEN 'Segunda'
        WHEN 2 THEN 'Terça'
        WHEN 3 THEN 'Quarta'
        WHEN 4 THEN 'Quinta'
        WHEN 5 THEN 'Sexta'
        WHEN 6 THEN 'Sábado'
    END as dia_semana,
    hora,
    total_agendamentos,
    ROUND((total_agendamentos::decimal / NULLIF(SUM(total_agendamentos) OVER(), 0) * 100), 2) as percentual
FROM mvw_horarios_populares
WHERE total_agendamentos > 0
ORDER BY total_agendamentos DESC;
```

### 2.5 Métodos de Pagamento

```sql
CREATE MATERIALIZED VIEW mvw_metodos_pagamento AS
SELECT
    CASE
        WHEN p.valor <= 100 THEN 'Até R$100'
        WHEN p.valor <= 200 THEN 'R$101-R$200'
        ELSE 'Acima de R$200'
    END as faixa_valor,
    mp.nome as metodo,
    COUNT(*) as quantidade,
    ROUND((COUNT(*)::decimal / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY
        CASE
            WHEN p.valor <= 100 THEN 'Até R$100'
            WHEN p.valor <= 200 THEN 'R$101-R$200'
            ELSE 'Acima de R$200'
        END), 0) * 100), 2) as percentual
FROM pagamento p
JOIN metodo_pagamento mp ON mp.cp_id_metodo = p.ce_id_metodo
WHERE p.status = 'confirmado'
GROUP BY faixa_valor, mp.nome;
```

## 3. Dashboards [RF15]

### 3.1 Dashboard Executivo

1. KPIs Principais:

   - Total de sessões realizadas
   - Receita total
   - Média de avaliações
   - Taxa de conversão global

2. Gráficos:
   - Receita por especialidade (barras)
   - Evolução mensal de sessões (linha)
   - Top 5 terapeutas (tabela)
   - Distribuição de avaliações (pizza)

### 3.2 Dashboard Operacional

1. Monitoramento:

   - Sessões do dia
   - Cancelamentos
   - Pagamentos pendentes
   - Horários disponíveis

2. Gráficos:
   - Heatmap de horários
   - Taxa de ocupação
   - Status das sessões
   - Alertas de sistema

### 3.3 Dashboard Financeiro

1. Indicadores:

   - Faturamento diário
   - Ticket médio
   - Inadimplência
   - Projeção mensal

2. Gráficos:
   - Métodos de pagamento
   - Faturamento por terapeuta
   - Histórico de recebimentos
   - Previsão de receita

## 4. Relatórios Periódicos [RF13, RF14]

### 4.1 Relatório Diário

1. Operacional:

   - Sessões realizadas
   - Cancelamentos
   - Novos agendamentos
   - Incidentes

2. Financeiro:
   - Pagamentos recebidos
   - Pagamentos pendentes
   - Cancelamentos
   - Estornos

### 4.2 Relatório Mensal

1. Performance:

   - Análise de crescimento
   - Comparativo YoY
   - Metas atingidas
   - Projeções

2. Qualidade:
   - Satisfação dos pacientes
   - Reclamações
   - Melhorias implementadas
   - Plano de ação

## 5. Processo ETL [RF15]

### 5.1 Extração

1. Fontes:

   - Banco operacional
   - Logs de sistema
   - Avaliações
   - Pagamentos

2. Frequência:
   - Real-time: Sessões e pagamentos
   - Diária: Indicadores e KPIs
   - Semanal: Análises complexas

### 5.2 Transformação

1. Limpeza:

   - Remoção de duplicados
   - Correção de dados
   - Padronização
   - Enriquecimento

2. Agregações:
   - Cálculos estatísticos
   - Métricas derivadas
   - Indicadores compostos

### 5.3 Carga

1. Destino:

   - Views materializadas
   - Tabelas agregadas
   - Cache de relatórios

2. Validação:
   - Integridade dos dados
   - Consistência
   - Performance
   - Auditoria
