-- ADR-022: retencao de 90 dias para o registro anonimo de falhas.
create extension if not exists pg_cron with schema extensions;

select cron.schedule(
  'limpar_fichas_falhas_antigas',
  '0 3 * * *',
  $$ delete from public.fichas_falhas where criado_em < now() - interval '90 days'; $$
);

-- Aproveita para limpar o contador de limite tambem (so precisa do ultimo minuto).
select cron.schedule(
  'limpar_limite_conjuracao_antigo',
  '*/15 * * * *',
  $$ delete from public.limite_conjuracao where criado_em < now() - interval '10 minutes'; $$
);
