-- Primeiro dropar todas as views na ordem correta (dependências primeiro)
DROP MATERIALIZED VIEW IF EXISTS mvw_horarios_pico CASCADE;
DROP MATERIALIZED VIEW IF EXISTS mvw_horarios_populares CASCADE;
DROP MATERIALIZED VIEW IF EXISTS mvw_taxa_conversao CASCADE;
DROP MATERIALIZED VIEW IF EXISTS mvw_receita_especialidade CASCADE;
DROP MATERIALIZED VIEW IF EXISTS mvw_retencao_pacientes CASCADE;
DROP MATERIALIZED VIEW IF EXISTS mvw_avaliacoes_especialidade CASCADE;
DROP MATERIALIZED VIEW IF EXISTS mvw_intervalo_sessoes CASCADE;
DROP MATERIALIZED VIEW IF EXISTS mvw_cancelamentos_periodo CASCADE;
DROP MATERIALIZED VIEW IF EXISTS mvw_crescimento_pacientes CASCADE;
DROP MATERIALIZED VIEW IF EXISTS mvw_metodos_pagamento CASCADE;
DROP MATERIALIZED VIEW IF EXISTS mvw_tempo_confirmacao CASCADE;
DROP MATERIALIZED VIEW IF EXISTS mvw_metodos_pagamento_analise CASCADE;

-- Agora criar as views na ordem correta (base primeiro)
-- 1. Horários populares (base para outras análises)
CREATE MATERIALIZED VIEW mvw_horarios_populares AS
SELECT 
    EXTRACT(DOW FROM data_hora) as dia_semana,
    EXTRACT(HOUR FROM data_hora) as hora,
    COUNT(*) as total_agendamentos
FROM sessao s
GROUP BY dia_semana, hora
ORDER BY total_agendamentos DESC;

-- 2. Taxa de conversão por terapeuta
DROP MATERIALIZED VIEW IF EXISTS mvw_taxa_conversao;
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

-- 3. Receita por especialidade
DROP MATERIALIZED VIEW IF EXISTS mvw_receita_especialidade;
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

-- 4. Horários de pico (depende de mvw_horarios_populares)
DROP MATERIALIZED VIEW IF EXISTS mvw_horarios_pico;
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

-- 5. Retenção de pacientes
DROP MATERIALIZED VIEW IF EXISTS mvw_retencao_pacientes;
CREATE MATERIALIZED VIEW mvw_retencao_pacientes AS
SELECT 
    t.nome as terapeuta,
    COUNT(DISTINCT s.ce_id_paciente) as total_pacientes,
    COUNT(DISTINCT CASE WHEN s2.sessoes_paciente > 1 THEN s.ce_id_paciente END) as pacientes_retorno,
    ROUND((COUNT(DISTINCT CASE WHEN s2.sessoes_paciente > 1 THEN s.ce_id_paciente END)::decimal / 
           NULLIF(COUNT(DISTINCT s.ce_id_paciente), 0) * 100), 2) as taxa_retencao
FROM terapeuta t
JOIN sessao s ON s.ce_id_terapeuta = t.cp_id_terapeuta
JOIN (
    SELECT ce_id_paciente, ce_id_terapeuta, COUNT(*) as sessoes_paciente
    FROM sessao
    GROUP BY ce_id_paciente, ce_id_terapeuta
) s2 ON s2.ce_id_paciente = s.ce_id_paciente AND s2.ce_id_terapeuta = t.cp_id_terapeuta
GROUP BY t.cp_id_terapeuta, t.nome;

-- 6. Avaliações por especialidade
DROP MATERIALIZED VIEW IF EXISTS mvw_avaliacoes_especialidade;
CREATE MATERIALIZED VIEW mvw_avaliacoes_especialidade AS
SELECT 
    e.nome as especialidade,
    COUNT(a.cp_id_avaliacao) as total_avaliacoes,
    ROUND(AVG(a.nota)::decimal, 2) as media_avaliacoes,
    COUNT(CASE WHEN a.nota >= 4 THEN 1 END) as avaliacoes_positivas
FROM especialidade e
JOIN terapeuta_especialidade te ON te.ce_id_especialidade = e.cp_id_especialidade
JOIN sessao s ON s.ce_id_terapeuta = te.ce_id_terapeuta
LEFT JOIN avaliacao a ON a.ce_id_sessao = s.cp_id_sessao
GROUP BY e.cp_id_especialidade, e.nome;

-- 7. Intervalo entre sessões
DROP MATERIALIZED VIEW IF EXISTS mvw_intervalo_sessoes;
CREATE MATERIALIZED VIEW mvw_intervalo_sessoes AS
WITH sessoes_ordenadas AS (
    SELECT 
        p.cp_id_paciente,
        p.nome,
        s.data_hora,
        s.data_hora - LAG(s.data_hora) OVER (
            PARTITION BY s.ce_id_paciente 
            ORDER BY s.data_hora
        ) as intervalo
    FROM paciente p
    JOIN sessao s ON s.ce_id_paciente = p.cp_id_paciente
    WHERE s.status = 'realizada'
)
SELECT 
    nome as paciente,
    COUNT(*) as total_sessoes,
    ROUND(AVG(EXTRACT(EPOCH FROM intervalo)/86400)::decimal, 2) as media_dias_entre_sessoes
FROM sessoes_ordenadas
WHERE intervalo IS NOT NULL
GROUP BY cp_id_paciente, nome
HAVING COUNT(*) > 1;

-- 8. Cancelamentos por período
DROP MATERIALIZED VIEW IF EXISTS mvw_cancelamentos_periodo;
CREATE MATERIALIZED VIEW mvw_cancelamentos_periodo AS
SELECT 
    CASE 
        WHEN EXTRACT(HOUR FROM data_hora) BETWEEN 6 AND 11 THEN 'Manhã'
        WHEN EXTRACT(HOUR FROM data_hora) BETWEEN 12 AND 17 THEN 'Tarde'
        ELSE 'Noite'
    END as periodo,
    COUNT(*) as total_sessoes,
    COUNT(CASE WHEN status = 'cancelada' THEN 1 END) as cancelamentos,
    ROUND((COUNT(CASE WHEN status = 'cancelada' THEN 1 END)::decimal / NULLIF(COUNT(*), 0) * 100), 2) as taxa_cancelamento
FROM sessao
GROUP BY periodo;

-- 9. Crescimento de pacientes
DROP MATERIALIZED VIEW IF EXISTS mvw_crescimento_pacientes;
CREATE MATERIALIZED VIEW mvw_crescimento_pacientes AS
SELECT 
    t.nome as terapeuta,
    DATE_TRUNC('month', s.data_hora) as mes,
    COUNT(DISTINCT s.ce_id_paciente) as novos_pacientes,
    LAG(COUNT(DISTINCT s.ce_id_paciente)) OVER (PARTITION BY t.cp_id_terapeuta ORDER BY DATE_TRUNC('month', s.data_hora)) as mes_anterior,
    CASE 
        WHEN LAG(COUNT(DISTINCT s.ce_id_paciente)) OVER (PARTITION BY t.cp_id_terapeuta ORDER BY DATE_TRUNC('month', s.data_hora)) = 0 THEN 0
        ELSE ROUND((COUNT(DISTINCT s.ce_id_paciente) - LAG(COUNT(DISTINCT s.ce_id_paciente)) OVER (PARTITION BY t.cp_id_terapeuta ORDER BY DATE_TRUNC('month', s.data_hora)))::decimal /
            NULLIF(LAG(COUNT(DISTINCT s.ce_id_paciente)) OVER (PARTITION BY t.cp_id_terapeuta ORDER BY DATE_TRUNC('month', s.data_hora)), 0) * 100, 2)
    END as taxa_crescimento
FROM terapeuta t
JOIN sessao s ON s.ce_id_terapeuta = t.cp_id_terapeuta
GROUP BY t.cp_id_terapeuta, t.nome, DATE_TRUNC('month', s.data_hora);

-- 10. Métodos de pagamento por faixa
DROP MATERIALIZED VIEW IF EXISTS mvw_metodos_pagamento;
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

-- 11. Tempo médio de confirmação
DROP MATERIALIZED VIEW IF EXISTS mvw_tempo_confirmacao;
CREATE MATERIALIZED VIEW mvw_tempo_confirmacao AS
WITH tempos_confirmacao AS (
    SELECT 
        t.cp_id_terapeuta,
        t.nome,
        MIN(CASE WHEN h.status_novo = 'confirmada' THEN h.data_mudanca END) - 
        MIN(CASE WHEN h.status_novo = 'agendada' THEN h.data_mudanca END) as tempo_confirmacao
    FROM terapeuta t
    JOIN sessao s ON s.ce_id_terapeuta = t.cp_id_terapeuta
    JOIN historico_status h ON h.ce_id_sessao = s.cp_id_sessao
    WHERE s.status IN ('confirmada', 'realizada')
    GROUP BY t.cp_id_terapeuta, t.nome
)
SELECT 
    nome as terapeuta,
    ROUND(AVG(EXTRACT(EPOCH FROM tempo_confirmacao)/3600)::decimal, 2) as media_horas_confirmacao
FROM tempos_confirmacao
WHERE tempo_confirmacao IS NOT NULL
GROUP BY cp_id_terapeuta, nome;

-- 12. Análise de métodos de pagamento
DROP MATERIALIZED VIEW IF EXISTS mvw_metodos_pagamento_analise;
CREATE MATERIALIZED VIEW mvw_metodos_pagamento_analise AS
SELECT 
    mp.nome as metodo,
    mp.status,
    COUNT(*) as total_utilizacoes,
    SUM(p.valor) as valor_total
FROM metodo_pagamento mp
JOIN pagamento p ON p.ce_id_metodo = mp.cp_id_metodo
GROUP BY mp.cp_id_metodo, mp.nome, mp.status;

-- Refresh de todas as views materializadas
REFRESH MATERIALIZED VIEW mvw_horarios_populares;
REFRESH MATERIALIZED VIEW mvw_taxa_conversao;
REFRESH MATERIALIZED VIEW mvw_receita_especialidade;
REFRESH MATERIALIZED VIEW mvw_horarios_pico;
REFRESH MATERIALIZED VIEW mvw_retencao_pacientes;
REFRESH MATERIALIZED VIEW mvw_avaliacoes_especialidade;
REFRESH MATERIALIZED VIEW mvw_intervalo_sessoes;
REFRESH MATERIALIZED VIEW mvw_cancelamentos_periodo;
REFRESH MATERIALIZED VIEW mvw_crescimento_pacientes;
REFRESH MATERIALIZED VIEW mvw_metodos_pagamento;
REFRESH MATERIALIZED VIEW mvw_tempo_confirmacao;
REFRESH MATERIALIZED VIEW mvw_metodos_pagamento_analise; 