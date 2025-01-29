-- Inserir especialidades
INSERT INTO especialidade (nome, descricao) VALUES
('Terapia Cognitivo-Comportamental', 'Abordagem focada em padrões de pensamento'),
('Psicanálise', 'Análise profunda do inconsciente'),
('Terapia Familiar', 'Atendimento voltado para famílias');

-- Inserir métodos de pagamento
INSERT INTO metodo_pagamento (nome, status) VALUES
('PIX', 'ativo'),
('Cartão de Crédito', 'ativo'),
('Cartão de Débito', 'ativo'),
('Dinheiro', 'ativo');

-- Funções auxiliares
CREATE OR REPLACE FUNCTION fn_gerar_cpf() RETURNS VARCHAR AS $$
BEGIN
    RETURN LPAD(FLOOR(RANDOM() * 99999999999)::TEXT, 11, '0');
END;
$$ LANGUAGE plpgsql;

-- Função para gerar CRP único
CREATE OR REPLACE FUNCTION fn_gerar_crp()
RETURNS VARCHAR AS $$
DECLARE
    v_crp VARCHAR;
    v_numero INTEGER;
BEGIN
    -- Gera um número aleatório de 5 dígitos entre 10000 e 99999
    SELECT floor(random() * (99999-10000+1) + 10000) INTO v_numero;
    
    -- Formata o CRP com o número gerado
    v_crp := 'CRP-03/' || v_numero::TEXT;
    
    -- Se já existe, tenta outro número até encontrar um único
    WHILE EXISTS (SELECT 1 FROM terapeuta WHERE crp = v_crp) LOOP
        SELECT floor(random() * (99999-10000+1) + 10000) INTO v_numero;
        v_crp := 'CRP-03/' || v_numero::TEXT;
    END LOOP;
    
    RETURN v_crp;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_gerar_cep() RETURNS CHAR(8) AS $$
BEGIN
    RETURN LPAD(FLOOR(RANDOM() * 99999999)::TEXT, 8, '0');
END;
$$ LANGUAGE plpgsql;

-- Função principal de geração de dados
DO $$
DECLARE
    v_id_terapeuta INTEGER;
    v_id_paciente INTEGER;
    v_id_sessao INTEGER;
    v_data_hora TIMESTAMP;
    v_status VARCHAR;
    v_cidades VARCHAR[] := ARRAY['Salvador', 'São Paulo', 'Rio de Janeiro', 'Belo Horizonte', 'Recife'];
    v_estados CHAR(2)[] := ARRAY['BA', 'SP', 'RJ', 'MG', 'PE'];
BEGIN
    FOR i IN 1..100 LOOP
        INSERT INTO terapeuta (
            nome, cpf, crp, email, telefone, senha, valor_hora, biografia,
            cep, rua, numero, bairro, cidade, estado, salt
        ) VALUES (
            'Terapeuta ' || i,
            fn_gerar_cpf(),
            fn_gerar_crp(),
            'terapeuta' || i || '@email.com',
            '7199999' || LPAD(i::TEXT, 4, '0'),
            md5('senha123'),
            100 + (random() * 200)::INTEGER,
            'Biografia do terapeuta ' || i,
            fn_gerar_cep(),
            'Rua ' || i,
            i::TEXT,
            'Bairro ' || i,
            v_cidades[1 + (i % 5)],
            v_estados[1 + (i % 5)],
            md5(random()::text)
        ) RETURNING cp_id_terapeuta INTO v_id_terapeuta;

        -- Gerar disponibilidades (1=segunda a 5=sexta)
        FOR dia IN 1..5 LOOP
            INSERT INTO disponibilidade (ce_id_terapeuta, dia_semana, hora_inicio, hora_fim)
            VALUES (v_id_terapeuta, dia % 7, '08:00'::TIME, '18:00'::TIME);
        END LOOP;

        -- Associar especialidades
        INSERT INTO terapeuta_especialidade (ce_id_terapeuta, ce_id_especialidade, data_obtencao)
        VALUES (v_id_terapeuta, 1 + (i % 3), CURRENT_DATE - (365 * (random() * 5)::INTEGER));
        
        -- Adicionar segunda especialidade para alguns terapeutas
        IF (i % 3 = 0) THEN
            INSERT INTO terapeuta_especialidade (ce_id_terapeuta, ce_id_especialidade, data_obtencao)
            VALUES (v_id_terapeuta, 1 + ((i + 1) % 3), CURRENT_DATE - (365 * (random() * 5)::INTEGER));
        END IF;
    END LOOP;

    -- Gerar 200 pacientes
    FOR i IN 1..200 LOOP
        INSERT INTO paciente (
            nome, cpf, email, telefone, data_nascimento,
            senha, cep, rua, numero, bairro, cidade, estado, salt
        ) VALUES (
            'Paciente ' || i,
            fn_gerar_cpf(),
            'paciente' || i || '@email.com',
            '7188888' || LPAD(i::TEXT, 4, '0'),
            CURRENT_DATE - ((18 + (random() * 50))::INTEGER || ' years')::INTERVAL,
            md5('senha123'),
            fn_gerar_cep(),
            'Rua Paciente ' || i,
            i::TEXT,
            'Bairro ' || i,
            v_cidades[1 + (i % 5)],
            v_estados[1 + (i % 5)],
            md5(random()::text)
        ) RETURNING cp_id_paciente INTO v_id_paciente;

        -- Gerar sessões para alguns pacientes
        IF i <= 100 THEN
            -- Pegar dia da semana entre 1 e 5 (dias úteis)
            v_data_hora := CURRENT_TIMESTAMP + (i || ' days')::INTERVAL;
            -- Ajustar para próximo dia útil se cair no fim de semana
            WHILE EXTRACT(DOW FROM v_data_hora) IN (0, 6) LOOP
                v_data_hora := v_data_hora + '1 day'::INTERVAL;
            END LOOP;
            -- Definir horário dentro do expediente (8h-17h)
            v_data_hora := date_trunc('day', v_data_hora) + 
                          ((8 + (i % 8))::text || ' hours')::INTERVAL + 
                          ((i % 4) * 15 || ' minutes')::INTERVAL;
            
            -- Primeiro definir o status da sessão
            v_status := (CASE 
                WHEN i <= 30 THEN 'cancelada'  
                WHEN i <= 60 THEN (ARRAY['agendada', 'confirmada', 'realizada'])[1 + (i % 3)]
                ELSE (ARRAY['agendada', 'confirmada', 'realizada', 'cancelada'])[1 + (i % 4)]
            END);

            INSERT INTO sessao (
                ce_id_paciente, ce_id_terapeuta, data_hora,
                duracao_min, valor, status
            ) VALUES (
                v_id_paciente,
                1 + (i % 50),
                v_data_hora,
                50,
                150.00,
                v_status
            ) RETURNING cp_id_sessao INTO v_id_sessao;

            -- Gerar avaliações APENAS para sessões realizadas
            IF v_status = 'realizada' THEN
                INSERT INTO avaliacao (
                    ce_id_sessao, nota, comentario
                ) VALUES (
                    v_id_sessao,
                    3 + (i % 3),
                    'Avaliação da sessão ' || i
                );
            END IF;

            -- Gerar pagamentos para todas as sessões
            INSERT INTO pagamento (
                ce_id_sessao, valor, ce_id_metodo, status, data_pagamento
            ) VALUES (
                v_id_sessao,
                150.00,
                1 + (i % 4), -- Referência ao ID do método de pagamento (1 a 4)
                CASE 
                    WHEN i <= 30 THEN 'pendente'
                    WHEN i <= 60 THEN 'confirmado'
                    ELSE (ARRAY['pendente', 'confirmado', 'cancelado'])[1 + (i % 3)]
                END,
                CASE 
                    WHEN i % 2 = 0 THEN CURRENT_TIMESTAMP
                    ELSE NULL
                END
            );
        END IF;
    END LOOP;
END $$;