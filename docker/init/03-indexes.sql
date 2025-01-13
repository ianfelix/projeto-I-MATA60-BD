-- Busca de Terapeutas
CREATE INDEX idx_terapeuta_cidade_valor ON terapeuta (cidade, valor_hora);
CREATE INDEX idx_terapeuta_especialidade ON terapeuta_especialidade USING HASH (ce_id_especialidade);
CREATE INDEX idx_terapeuta_valor ON terapeuta USING btree (valor_hora);

-- Otimização de Sessões
CREATE INDEX idx_sessao_data_terapeuta ON sessao (ce_id_terapeuta, data_hora);
CREATE INDEX idx_sessao_status ON sessao USING HASH (status);

-- Pagamentos
CREATE INDEX idx_pagamento_data ON pagamento USING btree (data_pagamento);
