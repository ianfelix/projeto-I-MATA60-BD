#!/bin/bash

# Configurações
CONTAINER="terapia_db"
DB_NAME="terapia_db"
DB_USER="admin"
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$BACKUP_DIR/backup_$DATE.log"

# Criar estrutura de diretórios
mkdir -p $BACKUP_DIR/{full,incremental,wal,logs}

# Função de logging
log() {
    echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

# Função de verificação de erro
check_error() {
    if [ $? -ne 0 ]; then
        log "ERRO: $1"
        notify_error "$1"
        exit 1
    else
        log "SUCESSO: $1"
    fi
}

# Notificação de erro (pode ser integrado com sistemas de monitoramento)
notify_error() {
    echo "ERRO NO BACKUP: $1" >> "$BACKUP_DIR/logs/errors.log"
    # Aqui pode adicionar integração com sistemas de monitoramento
}

# 1. Full Backup com verificação
full_backup() {
    log "Iniciando Full Backup..."
    
    # Verifica espaço em disco
    SPACE_NEEDED=5000000 # 5GB em KB
    SPACE_AVAILABLE=$(df -k "$BACKUP_DIR" | tail -1 | awk '{print $4}')
    
    if [ $SPACE_AVAILABLE -lt $SPACE_NEEDED ]; then
        log "ERRO: Espaço insuficiente para backup"
        return 1
    fi
    
    # Executa backup
    docker exec $CONTAINER pg_dump -U $DB_USER -d $DB_NAME -F c -f /tmp/full_$DATE.backup
    check_error "Criação do backup completo"
    
    # Copia para diretório local
    docker cp $CONTAINER:/tmp/full_$DATE.backup $BACKUP_DIR/full/
    check_error "Cópia do backup para storage local"
    
    # Backup de globals
    docker exec $CONTAINER pg_dumpall -U $DB_USER --globals-only > $BACKUP_DIR/full/globals_$DATE.sql
    check_error "Backup de configurações globais"
    
    # Verifica integridade
    docker exec $CONTAINER pg_restore -l /tmp/full_$DATE.backup > /dev/null 2>&1
    check_error "Verificação de integridade do backup"
}

# 2. Backup Incremental com verificação
incremental_backup() {
    log "Iniciando Backup Incremental..."
    
    # Verifica último backup completo
    LAST_FULL=$(ls -t $BACKUP_DIR/full/full_*.backup 2>/dev/null | head -1)
    if [ -z "$LAST_FULL" ]; then
        log "ERRO: Nenhum backup completo encontrado. Execute backup completo primeiro."
        return 1
    fi
    
    # Executa backup incremental
    docker exec $CONTAINER pg_basebackup -U $DB_USER -D /tmp/inc_$DATE -Ft -Xs
    check_error "Criação do backup incremental"
    
    docker cp $CONTAINER:/tmp/inc_$DATE $BACKUP_DIR/incremental/
    check_error "Cópia do backup incremental"
}

# 3. Configurar WAL Archiving com verificação
setup_wal() {
    log "Configurando WAL Archiving..."
    
    # Verifica se WAL já está configurado
    WAL_LEVEL=$(docker exec $CONTAINER psql -U $DB_USER -d $DB_NAME -tAc "SHOW wal_level;")
    if [ "$WAL_LEVEL" = "replica" ]; then
        log "WAL já configurado corretamente"
        return 0
    fi
    
    # Configura WAL
    docker exec $CONTAINER psql -U $DB_USER -d $DB_NAME -c "ALTER SYSTEM SET wal_level = replica;"
    docker exec $CONTAINER psql -U $DB_USER -d $DB_NAME -c "ALTER SYSTEM SET archive_mode = on;"
    docker exec $CONTAINER psql -U $DB_USER -d $DB_NAME -c "ALTER SYSTEM SET archive_command = 'test ! -f /var/lib/postgresql/data/wal/%f && cp %p /var/lib/postgresql/data/wal/%f';"
    check_error "Configuração de parâmetros WAL"
    
    # Configura diretório
    docker exec $CONTAINER mkdir -p /var/lib/postgresql/data/wal
    docker exec $CONTAINER chown postgres:postgres /var/lib/postgresql/data/wal
    check_error "Configuração do diretório WAL"
    
    # Reload
    docker exec -u postgres $CONTAINER pg_ctl reload -D /var/lib/postgresql/data
    check_error "Reload das configurações"
}

# Rotação de Backups com verificação
cleanup() {
    log "Iniciando limpeza de backups antigos..."
    
    # Mantém pelo menos um backup completo
    FULL_COUNT=$(ls $BACKUP_DIR/full/full_*.backup 2>/dev/null | wc -l)
    if [ $FULL_COUNT -le 1 ]; then
        log "Mantendo último backup completo"
        return 0
    fi
    
    # Remove backups antigos
    find $BACKUP_DIR/full -name "full_*.backup" -mtime +30 -delete
    find $BACKUP_DIR/full -name "globals_*.sql" -mtime +30 -delete
    find $BACKUP_DIR/incremental -mtime +7 -delete
    find $BACKUP_DIR/wal -mtime +7 -delete
    check_error "Limpeza de backups antigos"
}

# Script de Restauração Melhorado
create_restore_script() {
    log "Criando script de restauração..."
    
    cat > $BACKUP_DIR/restore_$DATE.sh << EOF
#!/bin/bash
# Script de restauração gerado em $DATE

# Configurações
CONTAINER="$CONTAINER"
DB_NAME="$DB_NAME"
DB_USER="$DB_USER"
BACKUP_DATE="$DATE"

# Função de log
log() {
    echo "[$(date +%Y-%m-%d\ %H:%M:%S)] \$1"
}

# 1. Parar aplicação
log "Parando aplicação..."
docker stop app_container || true

# 2. Restaurar backup completo
log "Restaurando backup completo..."
docker exec \$CONTAINER pg_restore -U \$DB_USER -d \$DB_NAME -c $BACKUP_DIR/full/full_\$BACKUP_DATE.backup
if [ \$? -ne 0 ]; then
    log "ERRO: Falha na restauração do backup completo"
    exit 1
fi

# 3. Restaurar configurações globais
log "Restaurando configurações globais..."
docker exec \$CONTAINER psql -U \$DB_USER -d \$DB_NAME -f $BACKUP_DIR/full/globals_\$BACKUP_DATE.sql
if [ \$? -ne 0 ]; then
    log "ERRO: Falha na restauração das configurações globais"
    exit 1
fi

# 4. Aplicar WAL (se necessário)
if [ -d "$BACKUP_DIR/wal" ]; then
    log "Aplicando WAL logs..."
    docker exec \$CONTAINER pg_ctl -D /var/lib/postgresql/data promote
    if [ \$? -ne 0 ]; then
        log "ERRO: Falha na aplicação dos WAL logs"
        exit 1
    fi
fi

# 5. Verificar integridade
log "Verificando integridade..."
docker exec \$CONTAINER psql -U \$DB_USER -d \$DB_NAME -c "SELECT count(*) FROM pg_tables;"
if [ \$? -ne 0 ]; then
    log "ERRO: Verificação de integridade falhou"
    exit 1
fi

# 6. Reiniciar aplicação
log "Reiniciando aplicação..."
docker start app_container || true

log "Restauração concluída com sucesso!"
EOF
    chmod +x $BACKUP_DIR/restore_$DATE.sh
    check_error "Criação do script de restauração"
}

# Execução Principal com tratamento de erros
main() {
    log "Iniciando processo de backup..."
    
    case "$1" in
        "full")
            full_backup
            ;;
        "incremental")
            incremental_backup
            ;;
        "setup-wal")
            setup_wal
            ;;
        "cleanup")
            cleanup
            ;;
        *)
            setup_wal
            full_backup
            incremental_backup
            cleanup
            create_restore_script
            ;;
    esac
    
    FINAL_STATUS=$?
    if [ $FINAL_STATUS -eq 0 ]; then
        log "Processo de backup concluído com sucesso"
    else
        log "Processo de backup concluído com erros"
        exit $FINAL_STATUS
    fi
}

# Executa o script principal com tratamento de erros
main "$@"