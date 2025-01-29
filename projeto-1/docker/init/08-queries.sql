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