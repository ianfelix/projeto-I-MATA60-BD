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
$$;

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
AS $$
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
$$;

-- Procedure para verificar disponibilidade do terapeuta
CREATE OR REPLACE PROCEDURE sp_verificar_disponibilidade(
    p_terapeuta_id INTEGER,
    p_data_hora TIMESTAMP,
    p_duracao_min INTEGER,
    OUT p_disponivel BOOLEAN,
    OUT p_motivo VARCHAR
)
LANGUAGE plpgsql
AS $$
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
$$;