-- Limite de conjuracoes por IA por sala (proposta tecnica, secao 5: 20/min/sala).
-- So a Edge Function (chave service_role) escreve e le aqui; RLS fechado para
-- o publishable key nao conseguir ler nem escrever direto.
create table if not exists public.limite_conjuracao (
  id bigint generated always as identity primary key,
  sala_id text not null,
  criado_em timestamptz not null default now()
);
create index if not exists limite_conjuracao_sala_tempo_idx
  on public.limite_conjuracao (sala_id, criado_em);
alter table public.limite_conjuracao enable row level security;

-- Registro anonimo de magias mal interpretadas (ADR-022). Sem nome, sem
-- identificador pessoal: so a frase, a ficha (ou erro) e a versao do sistema.
create table if not exists public.fichas_falhas (
  id bigint generated always as identity primary key,
  frase text not null,
  resposta_bruta text,
  motivo text not null,
  versao_sistema int not null default 1,
  criado_em timestamptz not null default now()
);
alter table public.fichas_falhas enable row level security;
