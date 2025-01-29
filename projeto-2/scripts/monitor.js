// Monitoramento de métricas essenciais
function checkMetrics() {
  print('\n=== Métricas do Sistema ===');

  // Status do Replica Set
  const rsStatus = rs.status();
  print('\nStatus do Replica Set:');
  print(`Primary: ${rsStatus.members.find((m) => m.state === 1)?.name}`);
  print(`Secondary: ${rsStatus.members.find((m) => m.state === 2)?.name}`);

  // Estatísticas de operações
  const serverStatus = db.serverStatus();
  print('\nOperações:');
  print(`Inserções: ${serverStatus.opcounters.insert}`);
  print(`Consultas: ${serverStatus.opcounters.query}`);
  print(`Atualizações: ${serverStatus.opcounters.update}`);
  print(`Remoções: ${serverStatus.opcounters.delete}`);
}

// Pipeline para monitorar mudanças
const pipeline = [
  {
    $match: {
      $or: [
        {
          'fullDocument.status': {
            $in: ['confirmada', 'realizada', 'cancelada'],
          },
        },
        { 'updateDescription.updatedFields.status': { $exists: true } },
        {
          'updateDescription.updatedFields.pagamento.status': { $exists: true },
        },
      ],
    },
  },
];

// Handler de eventos
function handleEvent(change) {
  const timestamp = new Date().toISOString();

  switch (change.operationType) {
    case 'insert':
      print(`[${timestamp}] Nova sessão: ${change.fullDocument.status}`);
      break;
    case 'update':
      if (change.updateDescription.updatedFields.status) {
        print(
          `[${timestamp}] Status atualizado: ${change.updateDescription.updatedFields.status}`
        );
      }
      if (change.updateDescription.updatedFields['pagamento.status']) {
        print(
          `[${timestamp}] Pagamento: ${change.updateDescription.updatedFields['pagamento.status']}`
        );
      }
      break;
    case 'delete':
      print(`[${timestamp}] Sessão removida: ${change.documentKey._id}`);
      break;
  }
}

// Iniciar monitoramento
print('=== Iniciando Monitoramento ===');
checkMetrics();

const changeStream = db.sessoes.watch(pipeline);
print('\nMonitorando mudanças em sessões...');

while (!changeStream.isExhausted()) {
  if (changeStream.hasNext()) {
    handleEvent(changeStream.next());
  }
}
