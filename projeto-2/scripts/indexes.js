// Índices para terapeutas
db.terapeutas.createIndex({ cpf: 1 }, { unique: true });
db.terapeutas.createIndex({ crp: 1 }, { unique: true });
db.terapeutas.createIndex({ email: 1 }, { unique: true });
db.terapeutas.createIndex({ 'especialidades.nome': 1 });

// Índice de texto para busca
db.terapeutas.createIndex(
  { nome: 'text', biografia: 'text', 'especialidades.nome': 'text' },
  {
    weights: {
      nome: 10,
      'especialidades.nome': 5,
      biografia: 1,
    },
    name: 'idx_busca_terapeuta',
    default_language: 'portuguese',
  }
);

// Índices para pacientes
db.pacientes.createIndex({ cpf: 1 }, { unique: true });
db.pacientes.createIndex({ email: 1 }, { unique: true });

// Índices para sessões
db.sessoes.createIndex(
  { terapeuta_id: 1, data_hora: 1, status: 1 },
  { name: 'idx_agenda_terapeuta' }
);

db.sessoes.createIndex(
  { paciente_id: 1, data_hora: 1, status: 1 },
  { name: 'idx_agenda_paciente' }
);

db.sessoes.createIndex(
  { status: 1, 'pagamento.status': 1 },
  { name: 'idx_status_pagamento' }
);

// Índice para geolocalização (caso implementemos busca por proximidade)
db.terapeutas.createIndex(
  {
    localizacao: '2dsphere',
  },
  {
    name: 'idx_localizacao_terapeuta',
    sparse: true,
  }
);

// Índices para análises e relatórios
db.sessoes.createIndexes([
  {
    key: {
      terapeuta_id: 1,
      status: 1,
      data_hora: 1,
      'pagamento.valor': 1,
      'avaliacao.nota': 1,
    },
    name: 'idx_analise_terapeuta',
  },
  {
    key: {
      'pagamento.metodo': 1,
      'pagamento.status': 1,
      data_hora: 1,
    },
    name: 'idx_analise_pagamentos',
  },
]);

// Índice de texto para busca em biografias
db.terapeutas.createIndex(
  { biografia: 'text' },
  { default_language: 'portuguese' }
);

// Índices para horários
db.horarios.createIndex({
  terapeuta_id: 1,
  data: 1,
});

// Índices para histórico de status
db.historico_status.createIndex({
  sessao_id: 1,
  data_mudanca: -1,
});
