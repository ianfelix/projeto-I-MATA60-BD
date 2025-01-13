-- Criação do schema
CREATE SCHEMA IF NOT EXISTS terapia;

-- Define o schema padrão
SET search_path TO terapia;

-- Extensões necessárias (devem ser criadas no schema public)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" SCHEMA public;
CREATE EXTENSION IF NOT EXISTS "pgcrypto" SCHEMA public;

-- Ajusta o search_path para incluir public
ALTER DATABASE terapia_db SET search_path TO terapia, public;