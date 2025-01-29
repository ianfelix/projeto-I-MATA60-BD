# Governança de Dados - Sistema de Agendamento Terapêutico

## 1. Política de Backup

### 1.1 Retenção de Dados [RF11]

- Dados pessoais: 5 anos após última atualização
- Registros financeiros: 7 anos após criação
- Logs de sistema: 1 ano após geração
- Documentos: permanente

### 1.2 Plano de Backup [RF11]

- Backup diário incremental (WAL)
- Backup semanal completo
- Retenção de 30 dias para backups diários
- Retenção de 12 meses para backups semanais
- Verificação de integridade após cada backup
- Logs de todas as operações de backup
- Monitoramento de espaço em disco
- Notificação automática de erros

### 1.3 Medidas de Retorno [RF11]

1. Verificação pré-restauração:

   - Espaço em disco suficiente
   - Integridade do backup
   - Dependências do sistema

2. Processo de restauração:

   - Parada controlada da aplicação
   - Restauração do backup mais recente
   - Aplicação de WAL logs
   - Verificação de integridade
   - Testes de consistência
   - Reinício da aplicação

3. Validação pós-restauração:
   - Contagem de registros
   - Verificação de relacionamentos
   - Teste de funcionalidades críticas
   - Confirmação de dados sensíveis

## 2. Modelo de Acesso e Dados (MAD) [RF01, RF02]

### 2.1 Classificação de Dados

1. Dados Sensíveis:

   - CPF (identificador único)
   - CRP (identificador profissional)
   - Email (contato direto)
   - Telefone (contato direto)
   - Endereço completo
   - Dados financeiros

2. Dados Operacionais:

   - IDs de sistema
   - Horários
   - Status
   - Configurações

3. Dados Estatísticos:
   - Contadores
   - Médias
   - Indicadores

### 2.2 Níveis de Acesso [RF10]

1. Administrador:

   - Acesso total
   - Visualização de logs
   - Gestão de usuários
   - Configurações do sistema

2. Terapeuta:

   - Dados próprios
   - Dados dos pacientes vinculados
   - Agenda e horários
   - Pagamentos recebidos

3. Paciente:
   - Dados próprios
   - Sessões agendadas
   - Pagamentos realizados
   - Avaliações feitas

### 2.3 Controles de Acesso [RF11]

1. Autenticação:

   - Senha forte obrigatória
   - Bloqueio após 3 tentativas
   - Renovação a cada 90 dias
   - 2FA para dados sensíveis

2. Autorização:
   - Baseada em papéis (RBAC)
   - Verificação por recurso
   - Logs de acesso
   - Revisão periódica

### 2.1 Funções de Geração

```sql
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
```

## 3. Política de Privacidade [RF01, RF02, RF11]

### 3.1 Proteção de Dados

1. Mascaramento:

   - CPF: xxx.**_._**-xx
   - Email: xx\*\*\*@dominio
   - Telefone: (xx)\*\*\*\*-xxxx
   - CRP: CRP-**.**.\*\*

2. Criptografia:
   - Dados em repouso
   - Dados em trânsito
   - Backups
   - Logs

### 3.2 Auditoria [RF11]

1. Logs de Acesso:

   - Data/hora
   - Usuário
   - Ação
   - Recurso
   - IP

2. Monitoramento:
   - Tentativas de acesso
   - Violações de política
   - Dados sensíveis
   - Performance

### 3.3 Conformidade

1. Relatórios:

   - Acessos negados
   - Dados mascarados
   - Retenção
   - Violações

2. Verificações:
   - Diária: logs e acessos
   - Semanal: backups
   - Mensal: conformidade
   - Trimestral: políticas

## 4. Implementação Técnica

### 4.1 Views de Análise [RF10]

```sql
-- View para análise de horários populares
CREATE MATERIALIZED VIEW mvw_horarios_populares AS
SELECT
    DATE(data_hora) as data,
    EXTRACT(DOW FROM data_hora) as dia_semana,
    EXTRACT(HOUR FROM data_hora) as hora,
    COUNT(*) as total_agendamentos
FROM sessao s
GROUP BY data, dia_semana, hora
ORDER BY total_agendamentos DESC;

-- View para análise de pagamentos
CREATE MATERIALIZED VIEW mvw_metodos_pagamento_analise AS
SELECT
    mp.nome as metodo,
    mp.status,
    COUNT(*) as total_utilizacoes,
    SUM(p.valor) as valor_total
FROM metodo_pagamento mp
JOIN pagamento p ON p.ce_id_metodo = mp.cp_id_metodo
GROUP BY mp.cp_id_metodo, mp.nome, mp.status;

-- View para análise de desempenho
CREATE MATERIALIZED VIEW mvw_taxa_conversao AS
SELECT
    t.nome as terapeuta,
    COUNT(s.cp_id_sessao) as total_agendamentos,
    COUNT(CASE WHEN s.status = 'realizada' THEN 1 END) as sessoes_realizadas,
    CASE
        WHEN COUNT(s.cp_id_sessao) = 0 THEN 0
        ELSE ROUND((COUNT(CASE WHEN s.status = 'realizada' THEN 1 END)::decimal /
               COUNT(s.cp_id_sessao) * 100), 2)
    END as taxa_conversao
FROM terapeuta t
LEFT JOIN sessao s ON s.ce_id_terapeuta = t.cp_id_terapeuta
GROUP BY t.cp_id_terapeuta, t.nome;
```

### 4.2 Funções de Controle [RF11]

```sql
-- Verificação de permissões
CREATE FUNCTION fn_check_access_permission();

-- Mascaramento de dados
CREATE FUNCTION fn_mask_sensitive_data();

-- Log de acessos sensíveis
CREATE FUNCTION fn_log_sensitive_access();

-- Verificação de retenção
CREATE FUNCTION fn_check_retention_policy();
```

### 4.3 Backup e Restauração [RF11]

```bash
# Backup incremental diário
./backup.sh incremental

# Backup completo semanal
./backup.sh full

# Restauração com validação
./restore.sh [data_backup]
```

## 5. Monitoramento e Alertas

### 5.1 Métricas de Backup [RF11]

- Taxa de sucesso
- Tempo de execução
- Tamanho dos backups
- Espaço disponível
- Integridade

### 5.2 Métricas de Acesso [RF10]

- Tentativas de login
- Acessos negados
- Dados sensíveis
- Performance
- Violações

### 5.3 Alertas [RF11]

- Falha de backup
- Espaço insuficiente
- Violação de acesso
- Dados não conformes
- Erros críticos

## 6. Instruções de Backup e Restauração

### 6.1 Pré-requisitos

- Docker e Docker Compose instalados
- Permissões de execução nos scripts
- Mínimo de 5GB de espaço livre

### 6.2 Estrutura de Diretórios

```
backups/
├── full/           # Backups completos semanais
├── incremental/    # Backups incrementais diários
├── wal/            # Write-Ahead Logs
└── logs/           # Logs de operações
```

### 6.3 Comandos de Backup [RF11]

1. Backup Completo:

```bash
# Executar backup completo
./scripts/backup.sh full

# Verificar logs
tail -f backups/backup_*.log
```

2. Backup Incremental:

```bash
# Executar backup incremental
./scripts/backup.sh incremental

# Verificar status
ls -lh backups/incremental/
```

3. Configuração WAL:

```bash
# Configurar Write-Ahead Logging
./scripts/backup.sh setup-wal

# Verificar configuração
docker exec terapia_db psql -U admin -d terapia_db -c "SHOW wal_level;"
```

4. Limpeza de Backups:

```bash
# Limpar backups antigos
./scripts/backup.sh cleanup

# Verificar espaço liberado
du -sh backups/*
```

5. Execução Completa:

```bash
# Executar todas as operações
./scripts/backup.sh

# Monitorar progresso
tail -f backups/backup_*.log
```

### 6.4 Processo de Restauração [RF11]

1. Localizar Backup:

```bash
# Listar backups disponíveis
ls -l backups/full/
```

2. Executar Restauração:

```bash
# Restaurar backup específico
./backups/restore_YYYYMMDD_HHMMSS.sh

# Monitorar progresso
tail -f backups/backup_*.log
```

3. Verificar Restauração:

```bash
# Verificar integridade
docker exec terapia_db psql -U admin -d terapia_db -c "SELECT count(*) FROM pg_tables;"

# Verificar dados
docker exec terapia_db psql -U admin -d terapia_db -c "SELECT count(*) FROM terapeuta;"
```

### 6.5 Monitoramento [RF11]

1. Verificar Status:

```bash
# Status dos backups
ls -lh backups/full/ backups/incremental/

# Verificar logs
grep ERROR backups/logs/errors.log
```

2. Espaço em Disco:

```bash
# Verificar espaço
df -h backups/

# Tamanho dos backups
du -sh backups/*
```

3. Integridade:

```bash
# Testar backup completo
docker exec terapia_db pg_restore -l backups/full/full_*.backup

# Verificar WAL
ls -l backups/wal/
```

### 6.6 Troubleshooting

1. Erros Comuns:

- Espaço insuficiente: Liberar espaço ou ajustar retenção
- Permissões: Verificar permissões do usuário
- Container parado: Iniciar container do banco
- WAL corrompido: Usar backup completo mais recente

2. Recuperação de Falhas:

```bash
# Reverter para último backup válido
./backups/restore_[ultima_data_valida].sh

# Verificar logs de erro
cat backups/logs/errors.log
```

3. Suporte:

- Verificar logs detalhados em `backups/backup_*.log`
- Consultar documentação do PostgreSQL
- Contatar equipe de suporte se necessário

### 6.7 Boas Práticas

1. Verificações Regulares:

- Testar restauração mensalmente
- Validar integridade dos backups
- Monitorar espaço em disco
- Revisar logs de erro

2. Segurança:

- Manter backups em local seguro
- Criptografar dados sensíveis
- Controlar acesso aos scripts
- Documentar procedimentos

3. Manutenção:

- Limpar backups antigos regularmente
- Atualizar scripts conforme necessário
- Ajustar parâmetros de performance
- Manter documentação atualizada
