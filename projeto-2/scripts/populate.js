// Funções auxiliares
function gerarCPF() {
  return Math.floor(Math.random() * 99999999999)
    .toString()
    .padStart(11, '0');
}

function gerarCRP() {
  return `CRP-03/${Math.floor(Math.random() * 89999 + 10000)}`;
}

function gerarTelefone() {
  return `71${Math.floor(Math.random() * 899999999 + 100000000)}`;
}

// Dados iniciais
const cidades = [
  'Salvador',
  'São Paulo',
  'Rio de Janeiro',
  'Belo Horizonte',
  'Recife',
];
const estados = ['BA', 'SP', 'RJ', 'MG', 'PE'];

// Especialidades
const especialidades = [
  {
    nome: 'Terapia Cognitivo-Comportamental',
    descricao:
      'Abordagem que trabalha a relação entre pensamentos, emoções e comportamentos',
    status: 'ativa',
  },
  {
    nome: 'Psicanálise',
    descricao:
      'Método terapêutico baseado nas teorias de Freud e seus sucessores',
    status: 'ativa',
  },
  {
    nome: 'Terapia Familiar',
    descricao: 'Abordagem que trabalha com a dinâmica familiar',
    status: 'ativa',
  },
];

db.especialidades.insertMany(especialidades);

// Métodos de pagamento
const metodosPagamento = [
  { nome: 'PIX', status: 'ativo' },
  { nome: 'Cartão de Crédito', status: 'ativo' },
  { nome: 'Cartão de Débito', status: 'ativo' },
  { nome: 'Dinheiro', status: 'ativo' },
];

db.metodos_pagamento.insertMany(metodosPagamento);

// Terapeutas (200 registros)
const terapeutas = [];
for (let i = 1; i <= 200; i++) {
  const cidadeIndex = i % 5;
  const terapeuta = {
    nome: `Dr. Terapeuta ${i}`,
    cpf: gerarCPF(),
    crp: gerarCRP(),
    email: `terapeuta${i}@email.com`,
    telefone: gerarTelefone(),
    valor_hora: NumberDecimal((150 + Math.random() * 200).toFixed(2)),
    biografia: `Biografia do terapeuta ${i}`,
    endereco: {
      cidade: cidades[cidadeIndex],
      estado: estados[cidadeIndex],
    },
    especialidades: [
      {
        nome: especialidades[i % 3].nome,
        data_obtencao: new Date(),
      },
    ],
    created_at: new Date(),
  };
  terapeutas.push(terapeuta);
}

db.terapeutas.insertMany(terapeutas);

// Pacientes (200 registros)
const pacientes = [];
for (let i = 1; i <= 200; i++) {
  const cidadeIndex = i % 5;
  const paciente = {
    nome: `Paciente ${i}`,
    cpf: gerarCPF(),
    email: `paciente${i}@email.com`,
    telefone: gerarTelefone(),
    data_nascimento: new Date(
      Date.now() - (18 + Math.random() * 50) * 365 * 24 * 60 * 60 * 1000
    ),
    endereco: {
      cidade: cidades[cidadeIndex],
      estado: estados[cidadeIndex],
    },
    created_at: new Date(),
  };
  pacientes.push(paciente);
}

db.pacientes.insertMany(pacientes);

// Sessões (200 registros)
const sessoes = [];
for (let i = 1; i <= 200; i++) {
  const dataHora = new Date();
  dataHora.setDate(dataHora.getDate() + (i % 30));
  dataHora.setHours(8 + (i % 8), 0, 0);

  const status = ['agendada', 'confirmada', 'realizada', 'cancelada'][i % 4];
  const sessao = {
    terapeuta_id: terapeutas[i % terapeutas.length]._id,
    paciente_id: pacientes[i % pacientes.length]._id,
    data_hora: dataHora,
    duracao_min: 50,
    valor: NumberDecimal('150.00'),
    status: status,
    created_at: new Date(),
  };

  if (status === 'realizada') {
    sessao.avaliacao = {
      nota: 3 + (i % 3),
      comentario: `Avaliação da sessão ${i}`,
    };
    sessao.pagamento = {
      valor: NumberDecimal('150.00'),
      metodo: metodosPagamento[i % 4].nome,
      status: 'confirmado',
    };
  }

  sessoes.push(sessao);
}

db.sessoes.insertMany(sessoes);
