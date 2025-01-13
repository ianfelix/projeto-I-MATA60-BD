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

### 4.1. Configuração do Ambiente

1. Clone o repositório

```bash
git clone https://github.com/terapia-app/terapia-app.git
cd terapia-app
```

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
