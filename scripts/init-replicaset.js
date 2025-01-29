// Inicializar replica set
rs.initiate({
  _id: 'rs0',
  members: [
    { _id: 0, host: 'mongodb-primary:27017', priority: 2 },
    { _id: 1, host: 'mongodb-secondary:27017', priority: 1 },
    { _id: 2, host: 'mongodb-arbiter:27017', arbiterOnly: true },
  ],
});

// Aguardar inicialização
sleep(1000);

// Validação de schema para terapeutas
db.createCollection('terapeutas', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['nome', 'cpf', 'crp', 'email', 'valor_hora'],
      properties: {
        nome: { bsonType: 'string' },
        cpf: { bsonType: 'string', pattern: '^[0-9]{11}$' },
        crp: { bsonType: 'string' },
        email: {
          bsonType: 'string',
          pattern: '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$',
        },
        valor_hora: { bsonType: 'decimal' },
      },
    },
  },
});

// Validação de schema para pacientes
db.createCollection('pacientes', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['nome', 'cpf', 'email', 'data_nascimento'],
      properties: {
        nome: { bsonType: 'string' },
        cpf: { bsonType: 'string', pattern: '^[0-9]{11}$' },
        email: { bsonType: 'string' },
        data_nascimento: { bsonType: 'date' },
      },
    },
  },
});

// Validação de schema para sessões
db.createCollection('sessoes', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['terapeuta_id', 'paciente_id', 'data_hora', 'valor', 'status'],
      properties: {
        terapeuta_id: { bsonType: 'objectId' },
        paciente_id: { bsonType: 'objectId' },
        data_hora: { bsonType: 'date' },
        valor: { bsonType: 'decimal' },
        status: { enum: ['agendada', 'confirmada', 'realizada', 'cancelada'] },
      },
    },
  },
});

// Verificar status
rs.status();
