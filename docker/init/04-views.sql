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

-- Refresh das materialized views
REFRESH MATERIALIZED VIEW mvw_desempenho_terapeutas;
REFRESH MATERIALIZED VIEW mvw_horarios_populares;