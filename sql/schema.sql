-- ═══════════════════════════════════════════════════════════
--  CONTROLE DE INTEGRAÇÃO — esquema consolidado
--
--  Reúne a criação inicial e todas as colunas adicionadas depois.
--  É idempotente: pode rodar de novo sem estragar nada.
--  Referência de como o banco está hoje; não é preciso rodar no
--  projeto atual, que já tem tudo isso.
-- ═══════════════════════════════════════════════════════════


-- ─── Participantes ────────────────────────────────────────
create table if not exists public.participantes (
  id          bigint generated always as identity primary key,
  numero      integer not null,
  nome        text    not null,
  celular     text    default '',
  retiro      date,
  modulos     jsonb   not null default '{}'::jsonb,   -- {"Perdão":"2026-09-13", ...}
  created_at  timestamptz default now()
);

create unique index if not exists participantes_numero_key
  on public.participantes(numero);


-- ─── Colunas adicionadas depois (detectadas pelo front) ───
alter table public.participantes add column if not exists turma      text    not null default '';
alter table public.participantes add column if not exists familia    boolean not null default false;
alter table public.participantes add column if not exists obs        text;
alter table public.participantes add column if not exists nascimento date;

create index if not exists participantes_turma_idx   on public.participantes(turma);
create index if not exists participantes_familia_idx on public.participantes(familia);


-- ─── Perfis de usuário ────────────────────────────────────
create table if not exists public.profiles (
  id        uuid primary key references auth.users(id) on delete cascade,
  email     text,
  nome      text,
  role      text not null default 'viewer' check (role in ('admin','editor','viewer')),
  aprovado  boolean not null default false,
  created_at timestamptz default now()
);


-- ─── Histórico de alterações ──────────────────────────────
create table if not exists public.historico (
  id            bigint generated always as identity primary key,
  participante  integer,
  nome          text,
  acao          text not null,
  detalhe       text,
  usuario       text,
  created_at    timestamptz default now()
);


-- ─── Segurança (RLS) ──────────────────────────────────────
-- As políticas reais estão no supabase_setup.sql original.
-- Resumo: só usuários aprovados leem; editor/admin escrevem;
-- só admin gerencia profiles.
alter table public.participantes enable row level security;
alter table public.profiles      enable row level security;
alter table public.historico     enable row level security;
