-- =============================================
-- 1. ESTRUTURAS DE DADOS PRINCIPAIS
-- =============================================

-- 1.1 Tabela de terapeutas
CREATE TABLE terapeuta (
    cp_id_terapeuta SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf VARCHAR(11) UNIQUE NOT NULL,
    crp VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    senha VARCHAR(255) NOT NULL,
    foto_perfil VARCHAR(255),
    valor_hora DECIMAL(10,2) NOT NULL,
    biografia VARCHAR(500),
    cep CHAR(8) NOT NULL,
    rua VARCHAR(100) NOT NULL,
    numero VARCHAR(10),
    complemento VARCHAR(50),
    bairro VARCHAR(50) NOT NULL,
    cidade VARCHAR(50) NOT NULL,
    estado CHAR(2) NOT NULL,
    salt VARCHAR(64) NOT NULL,
    ultimo_acesso TIMESTAMP,
    tentativas_login INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 1.2 Tabela de especialidades
CREATE TABLE especialidade (
    cp_id_especialidade SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao VARCHAR(500),
    requisitos VARCHAR(500),
    status VARCHAR(20) NOT NULL DEFAULT 'ativa' CHECK (status IN ('ativa', 'inativa')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 1.3 Tabela de relacionamento terapeuta-especialidade
CREATE TABLE terapeuta_especialidade (
    cp_id_terapeuta_esp SERIAL PRIMARY KEY,
    ce_id_terapeuta INTEGER REFERENCES terapeuta(cp_id_terapeuta),
    ce_id_especialidade INTEGER REFERENCES especialidade(cp_id_especialidade),
    certificacao VARCHAR(100),
    data_obtencao DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(ce_id_terapeuta, ce_id_especialidade)
);

-- 1.4 Tabela de disponibilidade
CREATE TABLE disponibilidade (
    cp_id_disponibilidade SERIAL PRIMARY KEY,
    ce_id_terapeuta INTEGER REFERENCES terapeuta(cp_id_terapeuta),
    dia_semana INTEGER CHECK (dia_semana BETWEEN 0 AND 6),
    hora_inicio TIME NOT NULL,
    hora_fim TIME NOT NULL,
    intervalo_min INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 1.5 Tabela de horários
CREATE TABLE horario (
    cp_id_horario SERIAL PRIMARY KEY,
    ce_id_disponibilidade INTEGER REFERENCES disponibilidade(cp_id_disponibilidade),
    data DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fim TIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT horario_nao_sobreposto UNIQUE (ce_id_disponibilidade, data, hora_inicio, hora_fim)
);

-- 1.6 Tabela de pacientes
CREATE TABLE paciente (
    cp_id_paciente SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cpf VARCHAR(11) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    data_nascimento DATE NOT NULL,
    senha VARCHAR(255) NOT NULL,
    cep CHAR(8) NOT NULL,
    rua VARCHAR(100) NOT NULL,
    numero VARCHAR(10),
    complemento VARCHAR(50),
    bairro VARCHAR(50) NOT NULL,
    cidade VARCHAR(50) NOT NULL,
    estado CHAR(2) NOT NULL,
    salt VARCHAR(64) NOT NULL,
    ultimo_acesso TIMESTAMP,
    tentativas_login INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 1.7 Tabela de sessões
CREATE TABLE sessao (
    cp_id_sessao SERIAL PRIMARY KEY,
    ce_id_paciente INTEGER REFERENCES paciente(cp_id_paciente),
    ce_id_terapeuta INTEGER REFERENCES terapeuta(cp_id_terapeuta),
    data_hora TIMESTAMP NOT NULL,
    duracao_min INTEGER DEFAULT 60,
    valor DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('agendada', 'confirmada', 'realizada', 'cancelada', 'rejeitada')),
    observacoes VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 1.8 Tabela de métodos de pagamento
CREATE TABLE metodo_pagamento (
    cp_id_metodo SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('ativo', 'inativo', 'em_manutencao')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 1.9 Tabela de pagamentos
CREATE TABLE pagamento (
    cp_id_pagamento SERIAL PRIMARY KEY,
    ce_id_sessao INTEGER REFERENCES sessao(cp_id_sessao),
    ce_id_metodo INTEGER REFERENCES metodo_pagamento(cp_id_metodo),
    valor DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('pendente', 'confirmado', 'cancelado', 'estornado')),
    data_pagamento TIMESTAMP,
    comprovante_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 1.10 Tabela de avaliações
CREATE TABLE avaliacao (
    cp_id_avaliacao SERIAL PRIMARY KEY,
    ce_id_sessao INTEGER REFERENCES sessao(cp_id_sessao),
    nota INTEGER CHECK (nota BETWEEN 1 AND 5),
    comentario VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(ce_id_sessao)
);

-- 1.11 Tabela de histórico de status
CREATE TABLE historico_status (
    cp_id_historico SERIAL PRIMARY KEY,
    ce_id_sessao INTEGER REFERENCES sessao(cp_id_sessao),
    status_anterior VARCHAR(20) NOT NULL,
    status_novo VARCHAR(20) NOT NULL,
    data_mudanca TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    motivo VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 2. TRIGGERS E FUNÇÕES
-- =============================================

-- 2.1 Atualização de Timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para cada tabela
CREATE TRIGGER update_terapeuta_updated_at
    BEFORE UPDATE ON terapeuta
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_especialidade_updated_at
    BEFORE UPDATE ON especialidade
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_terapeuta_especialidade_updated_at
    BEFORE UPDATE ON terapeuta_especialidade
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_disponibilidade_updated_at
    BEFORE UPDATE ON disponibilidade
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_horario_updated_at
    BEFORE UPDATE ON horario
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_paciente_updated_at
    BEFORE UPDATE ON paciente
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sessao_updated_at
    BEFORE UPDATE ON sessao
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_metodo_pagamento_updated_at
    BEFORE UPDATE ON metodo_pagamento
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pagamento_updated_at
    BEFORE UPDATE ON pagamento
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_avaliacao_updated_at
    BEFORE UPDATE ON avaliacao
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_historico_status_updated_at
    BEFORE UPDATE ON historico_status
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 2.2 Validação de Horários
CREATE OR REPLACE FUNCTION validate_sessao_horario()
RETURNS TRIGGER AS $$
BEGIN
    -- Verifica disponibilidade do terapeuta
    IF NOT EXISTS (
        SELECT 1 
        FROM disponibilidade d
        WHERE d.ce_id_terapeuta = NEW.ce_id_terapeuta
        AND d.dia_semana = EXTRACT(DOW FROM NEW.data_hora)::INTEGER
        AND NEW.data_hora::time BETWEEN d.hora_inicio AND d.hora_fim - interval '1 hour'
    ) THEN
        RAISE EXCEPTION 'Horário fora da disponibilidade do terapeuta';
    END IF;

    -- Verifica conflitos
    IF EXISTS (
        SELECT 1 
        FROM sessao s
        WHERE s.ce_id_terapeuta = NEW.ce_id_terapeuta
        AND s.cp_id_sessao != COALESCE(NEW.cp_id_sessao, -1)
        AND s.status NOT IN ('cancelada', 'rejeitada')
        AND NEW.data_hora BETWEEN s.data_hora
        AND s.data_hora + (s.duracao_min || ' minutes')::interval
    ) THEN
        RAISE EXCEPTION 'Conflito de horário com outra sessão';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_sessao_horario
    BEFORE INSERT OR UPDATE ON sessao
    FOR EACH ROW
    EXECUTE FUNCTION validate_sessao_horario();

-- 2.3 Atualização de Status
CREATE OR REPLACE FUNCTION update_sessao_status_on_payment()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'confirmado' THEN
        UPDATE sessao 
        SET status = 'confirmada'
        WHERE cp_id_sessao = NEW.ce_id_sessao
        AND status = 'agendada';
    ELSIF NEW.status = 'cancelado' THEN
        UPDATE sessao 
        SET status = 'cancelada'
        WHERE cp_id_sessao = NEW.ce_id_sessao
        AND status IN ('agendada', 'confirmada');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_sessao_status_payment
    AFTER UPDATE ON pagamento
    FOR EACH ROW
    EXECUTE FUNCTION update_sessao_status_on_payment();

-- 2.4 Validação de Avaliação
CREATE OR REPLACE FUNCTION validate_avaliacao()
RETURNS TRIGGER AS $$
BEGIN
    -- Verifica se a sessão foi realizada
    IF NOT EXISTS (
        SELECT 1 
        FROM sessao s
        WHERE s.cp_id_sessao = NEW.ce_id_sessao
        AND s.status = 'realizada'
    ) THEN
        RAISE EXCEPTION 'Só é possível avaliar sessões realizadas';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_avaliacao
    BEFORE INSERT OR UPDATE ON avaliacao
    FOR EACH ROW
    EXECUTE FUNCTION validate_avaliacao();
