# Sistema de Terapia - MongoDB (Projeto II)

Este projeto é uma migração do sistema de terapia do PostgreSQL (Projeto I) para MongoDB, implementando features avançadas e melhorias de performance.

## Pré-requisitos

- Docker Desktop
- Docker Compose
- Git (opcional)

## Guia Completo de Execução

### 1. Preparação do Ambiente

1. Clone ou baixe este repositório
2. Abra o terminal
3. Navegue até a pasta do projeto:
   ```bash
   cd projeto-2
   ```
4. Certifique-se que o Docker Desktop está rodando

### 2. Inicialização do Sistema

1. **Iniciar os containers**:

   ```bash
   docker-compose up -d
   ```

   Este comando inicia:

   - MongoDB Primary (porta 27017)
   - MongoDB Secondary (porta 27018)
   - MongoDB Arbiter (porta 27019)
   - Mongo Express (porta 8081)

2. **Inicializar o Replica Set**:

   ```bash
   docker exec mongodb-primary mongosh --eval "load('/scripts/init-replicaset.js')"
   ```

   Isso configura:

   - Replicação automática
   - Alta disponibilidade
   - Failover automático

3. **Criar índices otimizados**:

   ```bash
   docker exec mongodb-primary mongosh --eval "load('/scripts/indexes.js')"
   ```

   Cria índices para:

   - Busca por CPF/CRP (únicos)
   - Busca textual em biografias
   - Performance em consultas de sessões
   - Análises e relatórios

4. **Popular o banco com dados de exemplo**:

   ```bash
   docker exec mongodb-primary mongosh --eval "load('/scripts/populate.js')"
   ```

   Insere:

   - 200 terapeutas
   - 200 pacientes
   - 200 sessões
   - Especialidades e métodos de pagamento

5. **Iniciar monitoramento**:
   ```bash
   docker exec mongodb-primary mongosh --eval "load('/scripts/monitor.js')"
   ```
   Monitora em tempo real:
   - Status do replica set
   - Métricas de operações
   - Mudanças nas sessões

### 3. Acessando e Testando o Sistema

#### Interface Web (Mongo Express)

1. Abra no navegador: http://localhost:8081
2. Credenciais:
   - Usuário: admin
   - Senha: pass

#### Features para Testar

1. **Alta Disponibilidade**:

   - Visualize o status do replica set no Mongo Express
   - Teste failover parando o container primário:
     ```bash
     docker stop mongodb-primary
     ```

2. **Busca Textual**:
   No Mongo Express, execute:

   ```javascript
   db.terapeutas.find({
     $text: { $search: 'terapia comportamental' },
   });
   ```

3. **Agregações e Relatórios**:

   ```javascript
   // Desempenho dos terapeutas
   db.sessoes.aggregate([
     { $match: { status: 'realizada' } },
     {
       $group: {
         _id: '$terapeuta_id',
         total_sessoes: { $sum: 1 },
         media_avaliacao: { $avg: '$avaliacao.nota' },
       },
     },
   ]);
   ```

4. **Monitoramento em Tempo Real**:
   - Faça alterações nas sessões e observe o log do monitor
   - Teste diferentes status: agendada, confirmada, realizada

### 4. Explorando Melhorias

1. **Performance**:

   - Compare tempos de resposta com índices
   - Teste agregações complexas
   - Verifique uso de memória e CPU

2. **Flexibilidade**:

   - Adicione novos campos sem migração
   - Teste documentos com estruturas diferentes
   - Use arrays e documentos aninhados

3. **Escalabilidade**:
   - Observe replicação em tempo real
   - Teste leituras do secundário
   - Verifique distribuição de carga

### 5. Parando o Sistema

1. **Parar o monitoramento**:
   Pressione Ctrl+C no terminal onde o monitor está rodando

2. **Parar todos os containers**:

   ```bash
   docker-compose down
   ```

3. **Remover volumes** (opcional, apaga todos os dados):
   ```bash
   docker-compose down -v
   ```

## Documentação Adicional

Para uma documentação detalhada sobre:

- Migração do PostgreSQL
- Melhorias implementadas
- Métricas de performance
- Features do MongoDB utilizadas

Consulte o arquivo [RELATORIO_COMPLETO.md](RELATORIO_COMPLETO.md)

## Troubleshooting

1. **Erro de conexão com Docker**:

   - Verifique se o Docker Desktop está rodando
   - Reinicie o Docker Desktop

2. **Erro no Replica Set**:

   ```bash
   docker-compose down -v
   docker-compose up -d
   ```

   E repita os passos de inicialização

3. **Mongo Express não abre**:

   - Aguarde 30 segundos após iniciar os containers
   - Verifique se a porta 8081 está livre

4. **Erros de autenticação**:
   - Verifique as credenciais no docker-compose.yml
   - Reinicie os containers
