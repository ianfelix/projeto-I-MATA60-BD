-- Funções essenciais para o sistema

-- Função para buscar horários disponíveis de um terapeuta
CREATE OR REPLACE FUNCTION fn_horarios_disponiveis(
    p_terapeuta_id INTEGER,
    p_data DATE
)
RETURNS TABLE (
    horario TIME,
    disponivel BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    WITH horarios AS (
        SELECT hora_inicio + (interval '1 hour' * generate_series(0, 
            EXTRACT(HOUR FROM hora_fim)::integer - 
            EXTRACT(HOUR FROM hora_inicio)::integer - 1
        )) as horario
        FROM disponibilidade
        WHERE ce_id_terapeuta = p_terapeuta_id
        AND dia_semana = EXTRACT(DOW FROM p_data)
    )
    SELECT 
        h.horario,
        NOT EXISTS (
            SELECT 1 FROM sessao s
            WHERE s.ce_id_terapeuta = p_terapeuta_id
            AND s.data_hora::date = p_data
            AND s.data_hora::time = h.horario
            AND s.status NOT IN ('cancelada', 'rejeitada')
        ) as disponivel
    FROM horarios h;
END;
$$ LANGUAGE plpgsql;

-- Função para buscar terapeutas por especialidade e cidade
CREATE OR REPLACE FUNCTION fn_buscar_terapeutas(
    p_especialidade VARCHAR DEFAULT NULL,
    p_cidade VARCHAR DEFAULT NULL,
    p_valor_max DECIMAL DEFAULT NULL
)
RETURNS TABLE (
    id_terapeuta INTEGER,
    nome VARCHAR,
    especialidades TEXT,
    valor_hora DECIMAL,
    cidade VARCHAR,
    media_avaliacoes DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.cp_id_terapeuta,
        t.nome,
        string_agg(DISTINCT esp.nome, ', ') as especialidades,
        t.valor_hora,
        t.cidade,
        COALESCE(AVG(a.nota), 0) as media_avaliacoes
    FROM terapeuta t
    LEFT JOIN terapeuta_especialidade te ON t.cp_id_terapeuta = te.ce_id_terapeuta
    LEFT JOIN especialidade esp ON te.ce_id_especialidade = esp.cp_id_especialidade
    LEFT JOIN sessao s ON t.cp_id_terapeuta = s.ce_id_terapeuta
    LEFT JOIN avaliacao a ON s.cp_id_sessao = a.ce_id_sessao
    WHERE (p_especialidade IS NULL OR esp.nome ILIKE '%' || p_especialidade || '%')
    AND (p_cidade IS NULL OR t.cidade ILIKE '%' || p_cidade || '%')
    AND (p_valor_max IS NULL OR t.valor_hora <= p_valor_max)
    GROUP BY t.cp_id_terapeuta, t.nome, t.valor_hora, t.cidade;
END;
$$ LANGUAGE plpgsql;

-- Função para verificar permissões
CREATE OR REPLACE FUNCTION check_access_permission(
    p_user_id INTEGER,
    p_role VARCHAR,
    p_resource VARCHAR
) RETURNS BOOLEAN AS $$
BEGIN
    -- Verifica papel do usuário
    IF p_role = 'ADMIN' THEN
        RETURN TRUE;
    ELSIF p_role = 'TERAPEUTA' THEN
        -- Terapeuta só acessa seus próprios dados
        RETURN EXISTS (
            SELECT 1 FROM terapeuta 
            WHERE cp_id_terapeuta = p_user_id
        );
    ELSIF p_role = 'PACIENTE' THEN
        -- Paciente acessa apenas suas sessões
        RETURN EXISTS (
            SELECT 1 FROM sessao 
            WHERE ce_id_paciente = p_user_id
        );
    END IF;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- Função para verificar disponibilidade de horário
CREATE OR REPLACE FUNCTION fn_verificar_disponibilidade(
    p_terapeuta_id INTEGER,
    p_data DATE,
    p_hora_inicio TIME,
    p_hora_fim TIME
) RETURNS BOOLEAN AS $$
BEGIN
    RETURN NOT EXISTS (
        SELECT 1 
        FROM horario h
        JOIN disponibilidade d ON d.cp_id_disponibilidade = h.ce_id_disponibilidade
        WHERE d.ce_id_terapeuta = p_terapeuta_id
        AND h.data = p_data
        AND (h.hora_inicio, h.hora_fim) OVERLAPS (p_hora_inicio, p_hora_fim)
    );
END;
$$ LANGUAGE plpgsql;

-- Função para validar método de pagamento
CREATE OR REPLACE FUNCTION fn_validar_metodo_pagamento(
    p_metodo_id INTEGER
) RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM metodo_pagamento
        WHERE cp_id_metodo = p_metodo_id
        AND status = 'ativo'
    );
END;
$$ LANGUAGE plpgsql;

-- Função para verificar permissões de acesso
CREATE OR REPLACE FUNCTION fn_check_access_permission(
    p_user_id INTEGER,
    p_role VARCHAR,
    p_resource VARCHAR,
    p_action VARCHAR
) RETURNS BOOLEAN AS $$
BEGIN
    -- Verifica papel do usuário
    IF p_role = 'ADMIN' THEN
        RETURN TRUE;
    ELSIF p_role = 'TERAPEUTA' THEN
        -- Terapeuta só acessa seus próprios dados e dados dos seus pacientes
        IF p_resource = 'TERAPEUTA' THEN
            RETURN p_user_id = (SELECT cp_id_terapeuta FROM terapeuta WHERE cp_id_terapeuta = p_user_id);
        ELSIF p_resource = 'PACIENTE' THEN
            RETURN EXISTS (
                SELECT 1 FROM sessao 
                WHERE ce_id_terapeuta = p_user_id 
                AND ce_id_paciente = p_user_id
            );
        ELSIF p_resource = 'SESSAO' THEN
            RETURN EXISTS (
                SELECT 1 FROM sessao 
                WHERE ce_id_terapeuta = p_user_id
            );
        END IF;
    ELSIF p_role = 'PACIENTE' THEN
        -- Paciente acessa apenas suas próprias sessões e dados
        IF p_resource = 'PACIENTE' THEN
            RETURN p_user_id = (SELECT cp_id_paciente FROM paciente WHERE cp_id_paciente = p_user_id);
        ELSIF p_resource = 'SESSAO' THEN
            RETURN EXISTS (
                SELECT 1 FROM sessao 
                WHERE ce_id_paciente = p_user_id
            );
        END IF;
    END IF;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- Função para mascarar dados sensíveis
CREATE OR REPLACE FUNCTION fn_mask_sensitive_data(
    p_data TEXT,
    p_type VARCHAR
) RETURNS TEXT AS $$
BEGIN
    CASE p_type
        WHEN 'CPF' THEN
            RETURN substring(p_data, 1, 3) || '.***.***-' || right(p_data, 2);
        WHEN 'EMAIL' THEN
            RETURN substring(p_data, 1, 2) || '***@' || split_part(p_data, '@', 2);
        WHEN 'PHONE' THEN
            RETURN substring(p_data, 1, 4) || '****' || right(p_data, 4);
        WHEN 'CRP' THEN
            RETURN 'CRP-**.**.**';
        ELSE
            RETURN '***';
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- Função para registrar acesso a dados sensíveis
CREATE OR REPLACE FUNCTION fn_log_sensitive_access(
    p_user_id INTEGER,
    p_role VARCHAR,
    p_resource VARCHAR,
    p_action VARCHAR,
    p_details TEXT
) RETURNS VOID AS $$
BEGIN
    INSERT INTO log_acesso_sensivel (
        id_usuario,
        papel,
        recurso,
        acao,
        detalhes,
        data_acesso,
        ip_address
    ) VALUES (
        p_user_id,
        p_role,
        p_resource,
        p_action,
        p_details,
        CURRENT_TIMESTAMP,
        inet_client_addr()
    );
END;
$$ LANGUAGE plpgsql;

-- Função para verificar e atualizar políticas de retenção
CREATE OR REPLACE FUNCTION fn_check_retention_policy() RETURNS VOID AS $$
DECLARE
    v_retention_personal INTERVAL := '5 years';
    v_retention_financial INTERVAL := '7 years';
    v_retention_logs INTERVAL := '1 year';
BEGIN
    -- Anonimizar dados pessoais antigos
    UPDATE terapeuta 
    SET cpf = fn_mask_sensitive_data(cpf, 'CPF'),
        email = fn_mask_sensitive_data(email, 'EMAIL'),
        telefone = fn_mask_sensitive_data(telefone, 'PHONE')
    WHERE updated_at < (CURRENT_TIMESTAMP - v_retention_personal);

    UPDATE paciente 
    SET cpf = fn_mask_sensitive_data(cpf, 'CPF'),
        email = fn_mask_sensitive_data(email, 'EMAIL'),
        telefone = fn_mask_sensitive_data(telefone, 'PHONE')
    WHERE updated_at < (CURRENT_TIMESTAMP - v_retention_personal);

    -- Arquivar registros financeiros antigos
    INSERT INTO pagamento_arquivo (SELECT * FROM pagamento WHERE created_at < (CURRENT_TIMESTAMP - v_retention_financial));
    DELETE FROM pagamento WHERE created_at < (CURRENT_TIMESTAMP - v_retention_financial);

    -- Limpar logs antigos
    DELETE FROM log_acesso_sensivel WHERE data_acesso < (CURRENT_TIMESTAMP - v_retention_logs);
END;
$$ LANGUAGE plpgsql;

-- Função para verificar violações de privacidade
CREATE OR REPLACE FUNCTION fn_check_privacy_violations() RETURNS TABLE (
    violation_type TEXT,
    violation_count INTEGER,
    last_occurrence TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'Tentativas de Login Excedidas' as violation_type,
        COUNT(*) as violation_count,
        MAX(ultimo_acesso) as last_occurrence
    FROM terapeuta
    WHERE tentativas_login >= 3
    UNION ALL
    SELECT 
        'Acessos Não Autorizados' as violation_type,
        COUNT(*) as violation_count,
        MAX(data_acesso) as last_occurrence
    FROM log_acesso_sensivel
    WHERE acao = 'NEGADO'
    UNION ALL
    SELECT 
        'Dados Sensíveis Expostos' as violation_type,
        COUNT(*) as violation_count,
        MAX(data_acesso) as last_occurrence
    FROM log_acesso_sensivel
    WHERE recurso IN ('CPF', 'EMAIL', 'TELEFONE')
    AND papel != 'ADMIN';
END;
$$ LANGUAGE plpgsql;

-- Função para gerar relatório de conformidade
CREATE OR REPLACE FUNCTION fn_generate_compliance_report() RETURNS TABLE (
    metric_name TEXT,
    metric_value INTEGER,
    compliance_status TEXT
) AS $$
BEGIN
    RETURN QUERY
    -- Verificar dados mascarados
    SELECT 
        'Dados Pessoais Mascarados' as metric_name,
        COUNT(*) as metric_value,
        CASE 
            WHEN COUNT(*) = 0 THEN 'Conforme'
            ELSE 'Não Conforme'
        END as compliance_status
    FROM terapeuta 
    WHERE cpf NOT LIKE '___.***.***-__'
    UNION ALL
    -- Verificar retenção de dados
    SELECT 
        'Dados Retidos Além do Prazo' as metric_name,
        COUNT(*) as metric_value,
        CASE 
            WHEN COUNT(*) = 0 THEN 'Conforme'
            ELSE 'Não Conforme'
        END as compliance_status
    FROM paciente
    WHERE updated_at < (CURRENT_TIMESTAMP - INTERVAL '5 years')
    UNION ALL
    -- Verificar logs de auditoria
    SELECT 
        'Logs de Auditoria Mantidos' as metric_name,
        COUNT(*) as metric_value,
        CASE 
            WHEN COUNT(*) > 0 THEN 'Conforme'
            ELSE 'Não Conforme'
        END as compliance_status
    FROM log_acesso_sensivel
    WHERE data_acesso > (CURRENT_TIMESTAMP - INTERVAL '1 year');
END;
$$ LANGUAGE plpgsql;