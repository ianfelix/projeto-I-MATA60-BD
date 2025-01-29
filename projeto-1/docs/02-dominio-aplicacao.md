# Domínio de Aplicação - Sistema de Agendamento Terapêutico

## 1. Materialized Views

```sql
-- Views materializadas para análise de desempenho e horários

-- Materialized view para análise de desempenho dos terapeutas
CREATE MATERIALIZED VIEW mvw_desempenho_terapeutas AS
SELECT
t.cp_id_terapeuta,
t.nome,
COUNT(s.cp_id_sessao) as total_sessoes,
COUNT(DISTINCT s.ce_id_paciente) as total_pacientes,
AVG(a.nota)::DECIMAL(3,2) as media_avaliacoes,
SUM(CASE WHEN p.status = 'confirmado' THEN p.valor ELSE 0 END) as receita_total,
COUNT(CASE WHEN s.status = 'cancelada' THEN 1 END) as cancelamentos
FROM terapeuta t
LEFT JOIN sessao s ON s.ce_id_terapeuta = t.cp_id_terapeuta
LEFT JOIN avaliacao a ON a.ce_id_sessao = s.cp_id_sessao
LEFT JOIN pagamento p ON p.ce_id_sessao = s.cp_id_sessao
GROUP BY t.cp_id_terapeuta, t.nome
WITH DATA;

-- Materialized view para análise de horários mais procurados
CREATE MATERIALIZED VIEW mvw_horarios_populares AS
SELECT
EXTRACT(DOW FROM s.data_hora) as dia_semana,
EXTRACT(HOUR FROM s.data_hora) as hora,
COUNT(*) as total_agendamentos,
COUNT(CASE WHEN s.status = 'realizada' THEN 1 END) as sessoes_realizadas,
COUNT(CASE WHEN s.status = 'cancelada' THEN 1 END) as cancelamentos
FROM sessao s
GROUP BY dia_semana, hora
ORDER BY total_agendamentos DESC
WITH DATA;

-- View materializada para controle de acesso
CREATE MATERIALIZED VIEW acesso_controle AS
SELECT
t.cp_id_terapeuta,
t.nome,
t.email,
t.cpf as dado_sensivel_cpf,
t.crp as dado_sensivel_crp,
t.valor_hora,
t.ultimo_acesso,
COUNT(s.cp_id_sessao) as total_sessoes,
COUNT(DISTINCT e.cp_id_especialidade) as total_especialidades
FROM terapeuta t
LEFT JOIN sessao s ON s.ce_id_terapeuta = t.cp_id_terapeuta
LEFT JOIN terapeuta_especialidade te ON te.ce_id_terapeuta = t.cp_id_terapeuta
LEFT JOIN especialidade e ON e.cp_id_especialidade = te.ce_id_especialidade
GROUP BY t.cp_id_terapeuta;

-- Índice para performance

-- Refresh das materialized views
REFRESH MATERIALIZED VIEW mvw_desempenho_terapeutas;
REFRESH MATERIALIZED VIEW mvw_horarios_populares;
REFRESH MATERIALIZED VIEW acesso_controle;
```

## 2. Stored Procedures

```sql
-- Procedimentos armazenados para operações comuns

-- Procedure para reagendar sessão
CREATE OR REPLACE PROCEDURE sp_reagendar_sessao(
p_sessao_id INTEGER,
p_nova_data TIMESTAMP,
OUT p_status VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
-- Verifica se a sessão existe e pode ser reagendada
IF NOT EXISTS (
SELECT 1 FROM sessao
WHERE cp_id_sessao = p_sessao_id
AND status IN ('agendada', 'confirmada')
) THEN
p_status := 'Sessão não pode ser reagendada';
RETURN;
END IF;

    -- Tenta atualizar a data
    UPDATE sessao
    SET data_hora = p_nova_data,
        status = 'agendada'
    WHERE cp_id_sessao = p_sessao_id;

    p_status := 'Sessão reagendada com sucesso';

EXCEPTION
WHEN OTHERS THEN
p_status := 'Erro ao reagendar: ' || SQLERRM;
END;

$$
;

-- Procedure para gerar relatório financeiro
CREATE OR REPLACE PROCEDURE sp_relatorio_financeiro(
    p_terapeuta_id INTEGER,
    p_data_inicio DATE,
    p_data_fim DATE,
    OUT p_total_sessoes INTEGER,
    OUT p_receita_total DECIMAL(10,2),
    OUT p_receita_pendente DECIMAL(10,2)
)
LANGUAGE plpgsql
AS
$$

BEGIN
-- Total de sessões
SELECT COUNT(*),
SUM(CASE WHEN p.status = 'confirmado' THEN p.valor ELSE 0 END),
SUM(CASE WHEN p.status = 'pendente' THEN p.valor ELSE 0 END)
INTO p_total_sessoes, p_receita_total, p_receita_pendente
FROM sessao s
LEFT JOIN pagamento p ON p.ce_id_sessao = s.cp_id_sessao
WHERE s.ce_id_terapeuta = p_terapeuta_id
AND DATE(s.data_hora) BETWEEN p_data_inicio AND p_data_fim;
END;

$$
;

-- Procedure para verificar disponibilidade do terapeuta
CREATE OR REPLACE PROCEDURE sp_verificar_disponibilidade(
    p_terapeuta_id INTEGER,
    p_data_hora TIMESTAMP,
    p_duracao_min INTEGER,
    OUT p_disponivel BOOLEAN,
    OUT p_motivo VARCHAR
)
LANGUAGE plpgsql
AS
$$

BEGIN
-- Verifica se está dentro do horário de atendimento
IF NOT EXISTS (
SELECT 1 FROM disponibilidade d
WHERE d.ce_id_terapeuta = p_terapeuta_id
AND EXTRACT(DOW FROM p_data_hora) = d.dia_semana
AND CAST(p_data_hora AS TIME) >= d.hora_inicio
AND (CAST(p_data_hora AS TIME) + (p_duracao_min || ' minutes')::INTERVAL) <= d.hora_fim
) THEN
p_disponivel := FALSE;
p_motivo := 'Horário fora da disponibilidade do terapeuta';
RETURN;
END IF;

    -- Verifica se não há conflito com outras sessões
    IF EXISTS (
        SELECT 1 FROM sessao s
        WHERE s.ce_id_terapeuta = p_terapeuta_id
        AND s.status NOT IN ('cancelada', 'rejeitada')
        AND (p_data_hora, p_duracao_min) OVERLAPS (s.data_hora, s.duracao_min)
    ) THEN
        p_disponivel := FALSE;
        p_motivo := 'Conflito com outra sessão';
        RETURN;
    END IF;

    p_disponivel := TRUE;
    p_motivo := 'Horário disponível';

END;

$$
;
```

### 2.2 Relatório Financeiro

```sql
CREATE OR REPLACE PROCEDURE sp_relatorio_financeiro(
    p_terapeuta_id INTEGER,
    p_data_inicio DATE,
    p_data_fim DATE,
    OUT p_total_sessoes INTEGER,
    OUT p_receita_total DECIMAL(10,2),
    OUT p_receita_pendente DECIMAL(10,2)
)
LANGUAGE plpgsql AS
$$

BEGIN
SELECT
COUNT(*),
SUM(CASE WHEN p.status = 'confirmado' THEN p.valor ELSE 0 END),
SUM(CASE WHEN p.status = 'pendente' THEN p.valor ELSE 0 END)
INTO p_total_sessoes, p_receita_total, p_receita_pendente
FROM sessao s
LEFT JOIN pagamento p ON p.ce_id_sessao = s.cp_id_sessao
WHERE s.ce_id_terapeuta = p_terapeuta_id
AND DATE(s.data_hora) BETWEEN p_data_inicio AND p_data_fim;
END;

$$
;
```

### 2.3 Atualizar Views

```sql
CREATE OR REPLACE PROCEDURE sp_atualizar_views()
LANGUAGE plpgsql AS
$$

BEGIN
REFRESH MATERIALIZED VIEW CONCURRENTLY mvw_desempenho_terapeutas;
REFRESH MATERIALIZED VIEW CONCURRENTLY mvw_horarios_populares;
END;

$$
;
```

## 3. Comandos SQL

```sql
-- Comandos de Manipulação (DML)
-- 1. Atualizar valor da hora de um terapeuta
UPDATE terapeuta
SET valor_hora = valor_hora * 1.1
WHERE cp_id_terapeuta = 1;

-- 2. Cancelar uma sessão
UPDATE sessao
SET status = 'cancelada'
WHERE cp_id_sessao = 1;

-- 3. Marcar sessão como realizada
UPDATE sessao
SET status = 'realizada'
WHERE cp_id_sessao = 2;

-- 4. Adicionar nova especialidade a terapeuta (verificando duplicata)
INSERT INTO terapeuta_especialidade (ce_id_terapeuta, ce_id_especialidade, data_obtencao)
SELECT 1, 3, CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1
    FROM terapeuta_especialidade
    WHERE ce_id_terapeuta = 1
    AND ce_id_especialidade = 3
);

-- 5. Remover disponibilidade
DELETE FROM disponibilidade
WHERE cp_id_disponibilidade = 1;

-- 6. Atualizar dados do paciente
UPDATE paciente
SET telefone = '(71)99999-9999', email = 'novo@email.com'
WHERE cp_id_paciente = 1;

-- 7. Registrar novo pagamento
INSERT INTO pagamento (ce_id_sessao, valor, ce_id_metodo, status)
VALUES (3, 150.00, 1, 'confirmado');

-- 8. Atualizar método de pagamento
UPDATE metodo_pagamento
SET status = 'inativo'
WHERE nome = 'Dinheiro';

-- 9. Excluir avaliação
DELETE FROM avaliacao
WHERE cp_id_avaliacao = 1;

-- 10. Inserir histórico de status
INSERT INTO historico_status (ce_id_sessao, status_anterior, status_novo, motivo)
VALUES (1, 'agendada', 'cancelada', 'Solicitação do paciente');

-- Buscas Simples
-- 1. Listar terapeutas por cidade
SELECT nome, cidade, valor_hora
FROM terapeuta
WHERE cidade = 'Salvador';

-- 2. Buscar sessões futuras de um paciente
SELECT data_hora, t.nome as terapeuta, status
FROM sessao s
JOIN terapeuta t ON t.cp_id_terapeuta = s.ce_id_terapeuta
WHERE ce_id_paciente = 1 AND data_hora > CURRENT_TIMESTAMP;

-- 3. Listar pagamentos pendentes
SELECT s.data_hora, p.valor, t.nome as terapeuta
FROM pagamento p
JOIN sessao s ON s.cp_id_sessao = p.ce_id_sessao
JOIN terapeuta t ON t.cp_id_terapeuta = s.ce_id_terapeuta
WHERE p.status = 'pendente';

-- 4. Buscar avaliações por nota
SELECT s.data_hora, a.nota, a.comentario, t.nome as terapeuta
FROM avaliacao a
JOIN sessao s ON s.cp_id_sessao = a.ce_id_sessao
JOIN terapeuta t ON t.cp_id_terapeuta = s.ce_id_terapeuta
WHERE a.nota >= 4;

-- Buscas Intermediárias
-- 1. Média de avaliações por terapeuta
SELECT t.nome,
       COUNT(a.cp_id_avaliacao) as total_avaliacoes,
       AVG(a.nota)::DECIMAL(3,2) as media_nota
FROM terapeuta t
LEFT JOIN sessao s ON s.ce_id_terapeuta = t.cp_id_terapeuta
LEFT JOIN avaliacao a ON a.ce_id_sessao = s.cp_id_sessao
GROUP BY t.cp_id_terapeuta, t.nome
HAVING COUNT(a.cp_id_avaliacao) > 0;

-- 2. Terapeutas com mais sessões realizadas
SELECT t.nome,
       COUNT(s.cp_id_sessao) as total_sessoes,
       SUM(s.valor) as valor_total
FROM terapeuta t
JOIN sessao s ON s.ce_id_terapeuta = t.cp_id_terapeuta
WHERE s.status = 'realizada'
GROUP BY t.cp_id_terapeuta, t.nome
ORDER BY total_sessoes DESC
LIMIT 5;

-- 3. Pacientes que mais cancelaram sessões
SELECT p.nome,
       COUNT(s.cp_id_sessao) as cancelamentos
FROM paciente p
JOIN sessao s ON s.ce_id_paciente = p.cp_id_paciente
WHERE s.status = 'cancelada'
GROUP BY p.cp_id_paciente, p.nome
ORDER BY cancelamentos DESC
LIMIT 5;

-- Buscas Avançadas
-- 1. Relatório completo de sessões por terapeuta
SELECT
    t.nome as terapeuta,
    e.nome as especialidade,
    COUNT(s.cp_id_sessao) as total_sessoes,
    AVG(a.nota)::DECIMAL(3,2) as media_avaliacoes,
    SUM(CASE WHEN p.status = 'confirmado' THEN p.valor ELSE 0 END) as receita_total
FROM terapeuta t
JOIN terapeuta_especialidade te ON te.ce_id_terapeuta = t.cp_id_terapeuta
JOIN especialidade e ON e.cp_id_especialidade = te.ce_id_especialidade
LEFT JOIN sessao s ON s.ce_id_terapeuta = t.cp_id_terapeuta
LEFT JOIN avaliacao a ON a.ce_id_sessao = s.cp_id_sessao
LEFT JOIN pagamento p ON p.ce_id_sessao = s.cp_id_sessao
GROUP BY t.cp_id_terapeuta, t.nome, e.nome;

-- 2. Análise de horários mais populares
SELECT
    EXTRACT(DOW FROM s.data_hora) as dia_semana,
    EXTRACT(HOUR FROM s.data_hora) as hora,
    COUNT(*) as total_sessoes,
    AVG(a.nota)::DECIMAL(3,2) as media_avaliacoes
FROM sessao s
LEFT JOIN avaliacao a ON a.ce_id_sessao = s.cp_id_sessao
WHERE s.status = 'realizada'
GROUP BY dia_semana, hora
ORDER BY total_sessoes DESC;

-- 3. Dashboard financeiro por período
SELECT
    DATE_TRUNC('month', s.data_hora) as mes,
    t.nome as terapeuta,
    COUNT(s.cp_id_sessao) as total_sessoes,
    SUM(p.valor) as receita_total,
    AVG(p.valor)::DECIMAL(10,2) as ticket_medio,
    COUNT(DISTINCT s.ce_id_paciente) as pacientes_unicos
FROM terapeuta t
JOIN sessao s ON s.ce_id_terapeuta = t.cp_id_terapeuta
JOIN pagamento p ON p.ce_id_sessao = s.cp_id_sessao
WHERE p.status = 'confirmado'
GROUP BY mes, t.cp_id_terapeuta, t.nome
ORDER BY mes DESC, receita_total DESC;
```
