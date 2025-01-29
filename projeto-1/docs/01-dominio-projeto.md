---

# Descrição do Minimundo - Sistema de Agendamento Terapêutico

## 1. Visão Geral

O sistema gerencia o agendamento e acompanhamento de consultas terapêuticas, facilitando a conexão entre terapeutas e pacientes, com controle de pagamentos e avaliações.

## 2. Atores e Responsabilidades

### 2.1 Terapeutas

- Profissionais com CRP ativo
- Podem ter múltiplas especialidades
- Definem sua disponibilidade de horários
- Estabelecem valor por hora de atendimento
- Gerenciam seus agendamentos
- Confirmam pagamentos recebidos

### 2.2 Pacientes

- Pessoas que buscam atendimento terapêutico
- Podem agendar sessões com diferentes terapeutas
- Realizam pagamentos das sessões
- Avaliam os atendimentos recebidos

## 3. Processos Principais

### 3.1 Agendamento de Sessões

- Paciente consulta terapeutas disponíveis
- Verifica disponibilidade de horários
- Seleciona horário desejado
- Sistema verifica conflitos
- Sessão é registrada como "agendada"

### 3.2 Confirmação de Sessões

- Terapeuta recebe notificação de agendamento
- Confirma disponibilidade
- Sistema atualiza status para "confirmada"
- Paciente recebe notificação

### 3.3 Pagamentos

- Sistema registra valor da sessão
- Paciente seleciona método de pagamento
- Realiza pagamento
- Sistema atualiza status do pagamento
- Terapeuta confirma recebimento

### 3.4 Avaliações

- Após sessão realizada
- Paciente pode avaliar atendimento
- Nota de 1 a 5 estrelas
- Comentários opcionais
- Histórico mantido no sistema

## 4. Regras de Negócio

### 4.1 Agendamentos

- Sessões não podem ter horários sobrepostos
- Mínimo de 24h de antecedência
- Cancelamentos com até 12h de antecedência
- Status possíveis: agendada, confirmada, realizada, cancelada

### 4.2 Pagamentos

- Valor definido por terapeuta
- Múltiplos métodos aceitos
- Confirmação necessária
- Status possíveis: pendente, confirmado, cancelado, estornado

### 4.3 Avaliações

- Somente após sessão realizada
- Uma avaliação por sessão
- Notas de 1 a 5
- Comentários até 500 caracteres

### 4.4 Especialidades

- Terapeuta deve ter certificação
- Data de obtenção registrada
- Documentação comprobatória
- Status ativo/inativo

## 5. Requisitos de Dados

### 5.1 Dados Pessoais

- Nome completo
- CPF/CRP
- Email (único)
- Telefone
- Endereço completo

### 5.2 Dados Profissionais

- Especialidades
- Certificações
- Valor/hora
- Biografia
- Foto perfil

### 5.3 Dados Operacionais

- Datas e horários
- Status de sessões
- Registros de pagamento
- Histórico de alterações
- Avaliações e comentários

## 6. Controles e Auditoria

### 6.1 Registro de Alterações

- Data/hora da mudança
- Usuário responsável
- Status anterior/novo
- Motivo da alteração

### 6.2 Segurança

- Autenticação obrigatória
- Senhas criptografadas
- Controle de tentativas de login
- Registro de acessos

### 6.3 Backup

- Dados pessoais: 5 anos
- Registros financeiros: 7 anos
- Logs de sistema: 1 ano
- Documentos: permanente

# Requisitos Funcionais

## 1. Gestão de Usuários

### 1.1 Terapeutas [RF01]

- Cadastro completo com dados profissionais
- Upload de documentos (CRP, certificações)
- Definição de valor/hora
- Gerenciamento de especialidades
- Configuração de disponibilidade
- Visualização de agenda
- Relatórios de atendimento

### 1.2 Pacientes [RF02]

- Cadastro com dados pessoais
- Busca de terapeutas
- Histórico de sessões
- Gestão de pagamentos
- Sistema de avaliações
- Notificações de agendamentos

## 2. Gestão de Agendamentos

### 2.1 Disponibilidade [RF03]

- Configuração de dias/horários
- Definição de recorrência
- Bloqueio de horários
- Períodos de férias
- Exceções de atendimento

### 2.2 Sessões [RF04]

- Agendamento online
- Confirmação automática/manual
- Cancelamento com regras
- Remarcação de horários
- Registro de comparecimento
- Observações e anotações

### 2.3 Notificações [RF05]

- Confirmação de agendamento
- Lembretes de sessão
- Avisos de cancelamento
- Solicitações de pagamento
- Confirmações de alterações

## 3. Gestão Financeira

### 3.1 Pagamentos [RF06]

- Múltiplos métodos
- Registro de transações
- Confirmação automática
- Comprovantes digitais
- Estornos e cancelamentos
- Relatórios financeiros

### 3.2 Valores e Taxas [RF07]

- Definição por terapeuta
- Valores diferentes por tipo
- Descontos e pacotes
- Multas por cancelamento
- Ajustes automáticos

## 4. Avaliações e Feedback

### 4.1 Sistema de Avaliação [RF08]

- Notas por sessão
- Comentários opcionais
- Moderação de conteúdo
- Métricas de satisfação
- Respostas do terapeuta

### 4.2 Relatórios [RF09]

- Média de avaliações
- Histórico por terapeuta
- Análise de comentários
- Tendências temporais
- Indicadores de qualidade

## 5. Administração do Sistema

### 5.1 Gestão de Especialidades [RF10]

- Cadastro e manutenção
- Vinculação com terapeutas
- Requisitos e certificações
- Status e validações
- Histórico de alterações

### 5.2 Auditoria e Logs [RF11]

- Registro de ações
- Histórico de mudanças
- Trilha de auditoria
- Backup de dados
- Recuperação de informações

### 5.3 Configurações [RF12]

- Parâmetros do sistema
- Regras de negócio
- Textos e mensagens
- Integrações externas
- Manutenção preventiva

## 6. Relatórios e Analytics

### 6.1 Relatórios Operacionais [RF13]

- Agendamentos por período
- Taxa de ocupação
- Cancelamentos e faltas
- Pagamentos pendentes
- Avaliações recentes

### 6.2 Relatórios Gerenciais [RF14]

- Performance financeira
- Satisfação dos pacientes
- Análise de demanda
- Tendências de mercado
- Indicadores chave

### 6.3 Dashboards [RF15]

- Visão geral do sistema
- Métricas em tempo real
- Gráficos interativos
- Alertas e notificações
- Exportação de dados

# Delimitação do Minimundo para o Banco de dados

## 1. Estruturas de Dados Principais

### 1.1 TERAPEUTA

```sql
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
```

### 1.2 ESPECIALIDADE

```sql
CREATE TABLE especialidade (
    cp_id_especialidade SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao VARCHAR(500),
    requisitos VARCHAR(500),
    status VARCHAR(20) NOT NULL DEFAULT 'ativa' CHECK (status IN ('ativa', 'inativa')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 1.3 TERAPEUTA_ESPECIALIDADE

```sql
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
```

### 1.4 DISPONIBILIDADE

```sql
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
```

### 1.5 PACIENTE

```sql
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
```

### 1.6 SESSAO

```sql
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
```

### 1.7 PAGAMENTO

```sql
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
```

### 1.8 AVALIACAO

```sql
CREATE TABLE avaliacao (
    cp_id_avaliacao SERIAL PRIMARY KEY,
    ce_id_sessao INTEGER REFERENCES sessao(cp_id_sessao),
    nota INTEGER CHECK (nota BETWEEN 1 AND 5),
    comentario VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(ce_id_sessao)
);
```

### 1.9 HISTORICO_STATUS

```sql
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
```

### 1.10 METODO_PAGAMENTO

```sql
CREATE TABLE metodo_pagamento (
    cp_id_metodo SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('ativo', 'inativo', 'em_manutencao')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 1.11 HORARIO

```sql
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
```

## 2. Triggers e Funções

### 2.1 Atualização de Timestamps

```sql
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

CREATE TRIGGER update_paciente_updated_at
    BEFORE UPDATE ON paciente
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sessao_updated_at
    BEFORE UPDATE ON sessao
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

CREATE TRIGGER update_horario_updated_at
    BEFORE UPDATE ON horario
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_historico_status_updated_at
    BEFORE UPDATE ON historico_status
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_metodo_pagamento_updated_at
    BEFORE UPDATE ON metodo_pagamento
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

### 2.2 Validação de Horários

```sql
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
```

### 2.3 Atualização de Status

```sql
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
```

### 2.4 Validação de Avaliação

```sql
CREATE OR REPLACE FUNCTION validate_avaliacao()
RETURNS TRIGGER AS $$
BEGIN
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
```

## 2. Características Comuns

### 2.1 Campos de Auditoria

- created_at: Data de criação
- updated_at: Data de última atualização

### 2.2 Nomenclatura

- cp\_: Prefixo para chaves primárias
- ce\_: Prefixo para chaves estrangeiras
- Nomes em português
- Snake case para campos

### 2.3 Tipos de Dados

- SERIAL: Identificadores
- VARCHAR: Textos com limite
- TEXT: Textos sem limite
- TIMESTAMP: Datas com hora
- DECIMAL: Valores monetários
- INTEGER: Números inteiros
- BOOLEAN: Verdadeiro/Falso
- DATE: Datas sem hora

### 2.4 Constraints

- PRIMARY KEY
- FOREIGN KEY
- UNIQUE
- CHECK
- NOT NULL
- DEFAULT

## 3. Modelo Conceitual:

![CleanShot 2025-01-12 at 12.03.34.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/3e36e6e5-7b8f-4c9f-b1d0-f9bf091a0fe0/f4585a24-636a-49e6-bbbb-1d75fa648ef1/CleanShot_2025-01-12_at_12.03.34.png)

## 4. Modelo Logico:

![CleanShot 2025-01-12 at 12.04.52.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/3e36e6e5-7b8f-4c9f-b1d0-f9bf091a0fe0/9f3b7e20-08a7-42f6-96d6-34c819bdad57/CleanShot_2025-01-12_at_12.04.52.png)

# Documentação do Sistema de Agendamento Terapêutico

## 1. Visão Geral

Este projeto implementa um banco de dados PostgreSQL para um sistema de agendamento de consultas terapêuticas, utilizando Docker para facilitar a implantação e testes.

## 2. Requisitos

- Docker
- Docker Compose
- DBeaver (ou outro cliente SQL)
- Git

## 3. Estrutura do Projeto

```markdown
projeto-terapia/
├── docker/
│ ├── docker-compose.yml # Configuração do container
│ └── init/
│ ├── 00-tuning.sql # Ajustes de performance
│ ├── 01-schema.sql # Schema e extensões
│ ├── 02-tables.sql # Estrutura das tabelas
│ ├── 03-indexes.sql # Índices para otimização
│ ├── 04-views.sql # Views para consultas
│ ├── 05-functions.sql # Funções do sistema
│ ├── 06-procedures.sql # Procedures para manipulação de dados
│ ├── 07-data.sql # Dados iniciais
│ └── 08-queries.sql # Comandos de manipulação
│ └── 09-analytics.sql # Registros de auditoria
└── .env # Variáveis de ambiente
```

## 4. Configuração e Instalação

### 4.1. Processo de Inicialização

Quando você executa `docker-compose up -d`, o seguinte processo ocorre:

1. **Construção do Container**

   - Cria volume persistente `pgdata`
   - Configura ambiente PostgreSQL com variáveis do `.env`
   - Aloca 128MB de shared memory

2. **Execução dos Scripts (em ordem)**

   ```bash
   /docker-entrypoint-initdb.d/
   ├── 00-tuning.sql     # ~1s  - Otimizações do PostgreSQL
   ├── 01-schema.sql     # ~1s  - Cria schema 'terapia'
   ├── 02-tables.sql     # ~2s  - Cria estrutura das tabelas
   ├── 03-indexes.sql    # ~2s  - Cria índices otimizados
   ├── 04-views.sql      # ~2s  - Views para análises
   ├── 05-functions.sql  # ~1s  - Funções auxiliares
   ├── 06-procedures.sql # ~1s  - Procedures de negócio
   ├── 07-data.sql       # ~30s - Popula dados iniciais
   ├── 08-queries.sql    # ~1s  - Queries úteis
   └── 09-analytics.sql  # ~5s  - Views analíticas
   ```

3. **População de Dados**

   - 100 terapeutas com dados aleatórios
   - 200 pacientes com perfis diversos
   - ~500 sessões distribuídas
   - ~300 avaliações
   - ~1000 registros de pagamento
   - Especialidades e métodos de pagamento padrão

4. **Verificação**

   ```bash
   # Ver status do container
   docker ps

   # Ver logs em tempo real
   docker logs -f terapia_db

   # Verificar tabelas criadas
   docker exec -it terapia_db psql -U admin -d terapia_db -c "\dt"

   # Contar registros
   docker exec -it terapia_db psql -U admin -d terapia_db -c "
     SELECT
       (SELECT COUNT(*) FROM terapeuta) as terapeutas,
       (SELECT COUNT(*) FROM paciente) as pacientes,
       (SELECT COUNT(*) FROM sessao) as sessoes;
   "
   ```

5. **Possíveis Erros**

   - Se o container falhar: `docker-compose down && docker-compose up -d`
   - Se dados não popularem: `docker logs terapia_db | grep ERROR`
   - Problemas de permissão: `sudo chown -R 999:999 ./pgdata`

6. **Métricas Esperadas**
   - Tempo total de inicialização: ~45s
   - Uso de disco inicial: ~200MB
   - Uso de RAM: ~400MB
   - Conexões máximas: 100

### 4.2. Inicialização do Banco

```bash
cd docker
docker-compose up -d

```

### 4.3. Verificação da Instalação

```bash
# Verificar se o container está rodando
docker ps

# Verificar logs
docker logs terapia_db

```

### 4.4. Conexão com DBeaver (ou outro cliente SQL)

1. Abra o DBeaver
2. Crie uma nova conexão
3. Configure as informações:
   - Host: localhost
   - Porta: 5432
   - Database: terapia_db
   - Username: admin
   - Password: admin123

### 4.5. Problemas Comuns

Se encontrar erros:

- Verifique se o container está rodando: `docker ps`
- Verifique logs do container: `docker logs terapia_db`
- Verifique se o banco de dados está rodando: `docker exec -it terapia_db psql -U admin -d terapia_db`
- remova o container e o volume: `docker rm -f terapia_db && docker volume rm docker_pgdata`
- Rode novamente: `docker-compose up -d`

## 5. Comandos de Manipulação

Para executar os comandos de manipulação, você pode usar o comando `docker exec -it terapia_db psql -U admin -d terapia_db`.

Para executar um comando SQL, você pode usar o comando `docker exec -it terapia_db psql -U admin -d terapia_db -c "comando SQL"`.

## Validação dos Requisitos do Projeto

### Relações N:M Implementadas

- Terapeuta-Especialidade (via terapeuta_especialidade)
- Terapeuta-Paciente (via sessao)
- Terapeuta-Disponibilidade (via disponibilidade)

### Contagem de Tabelas Principais

1. Terapeuta
2. Paciente
3. Sessao
4. Especialidade
5. Terapeuta_Especialidade
6. Disponibilidade
7. Pagamento
8. Metodo_Pagamento
9. Avaliacao
10. Historico_Status
11. Horario

### Tipos de Atributos por Tabela

Cada tabela contém:

- Atributos numéricos (ids, valores)
- Atributos categóricos (status, tipos)
- Atributos textuais (nomes, descrições)

### Volume de Dados

O script de população gera automaticamente:

- 100 terapeutas
- 200 pacientes
- Múltiplas sessões e registros relacionados

## 5. Otimizações (Tuning)

### 5.1 Configurações do PostgreSQL

- **max_connections = 100**

  - Limite de conexões simultâneas
  - Balanceado para ambiente de desenvolvimento

- **shared_buffers = 1GB**

  - Cache principal do PostgreSQL
  - ~25% da RAM total disponível
  - Melhora performance de queries repetitivas

- **effective_cache_size = 3GB**

  - Estimativa de cache do SO
  - ~75% da RAM total disponível
  - Ajuda o planejador de queries

- **maintenance_work_mem = 256MB**

  - Memória para operações de manutenção
  - Usado em VACUUM, CREATE INDEX, etc
  - Valor maior acelera estas operações

- **work_mem = 5242kB**
  - Memória por operação de ordenação
  - Valor conservador para evitar swap
  - (work_mem \* max_connections < RAM total)

### 5.2 Write-Ahead Log (WAL)

- **wal_buffers = 16MB**

  - Buffer para logs de transação
  - 16MB é suficiente para alta concorrência

- **min_wal_size = 1GB**
- **max_wal_size = 4GB**
  - Controle de espaço em disco
  - Checkpoints mais espaçados
  - Melhor performance de escrita

### 5.3 Query Planner

- **random_page_cost = 1.1**

  - Custo de leitura não sequencial
  - Valor baixo para SSDs

- **effective_io_concurrency = 200**

  - IO concurrent para SSDs
  - Aumenta paralelismo de leitura

- **default_statistics_target = 100**
  - Nível de estatísticas coletadas
  - Balanceado entre precisão e overhead

### 5.4 Índices Otimizados

- Índices B-tree para chaves primárias
- Índices parciais para filtros comuns
- Índices compostos para joins frequentes
- BRIN para dados sequenciais (timestamps)

### 5.2 Estratégia de Indexação

```sql
-- Busca de Terapeutas
CREATE INDEX CONCURRENTLY idx_terapeuta_cidade_valor
    ON terapeuta (cidade, valor_hora);             -- Busca por localidade e faixa de preço

CREATE INDEX CONCURRENTLY idx_terapeuta_especialidade
    ON terapeuta_especialidade USING HASH (ce_id_especialidade); -- Join com especialidades

CREATE INDEX CONCURRENTLY idx_terapeuta_valor
    ON terapeuta USING btree (valor_hora);         -- Range queries de valor

-- Otimização de Sessões
CREATE INDEX CONCURRENTLY idx_sessao_data_terapeuta
    ON sessao (ce_id_terapeuta, data_hora);        -- Agenda do terapeuta

CREATE INDEX CONCURRENTLY idx_sessao_status
    ON sessao USING HASH (status);                 -- Filtros por status

-- Pagamentos
CREATE INDEX CONCURRENTLY idx_pagamento_data
    ON pagamento USING btree (data_pagamento);     -- Range queries temporais

```

### 5.3 Justificativa dos Índices

1. **idx_terapeuta_cidade_valor**:

   - Otimiza busca de terapeutas por região
   - Suporta filtros de faixa de preço
   - Índice composto para queries frequentes

2. **idx_terapeuta_especialidade**:

   - Hash index para joins exatos
   - Melhora performance de busca por especialidade

3. **idx_terapeuta_valor**:

   - B-tree para range queries de valor
   - Suporta ordenação por preço

4. **idx_sessao_data_terapeuta**:

   - Otimiza visualização de agenda
   - Composto para filtros combinados

5. **idx_sessao_status**:

   - Hash para filtros de status exatos
   - Melhora performance de dashboards

6. **idx_pagamento_data**:
   - B-tree para relatórios temporais
   - Suporta range queries de data
