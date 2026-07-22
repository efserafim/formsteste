-- XVI C.O.R Jovem — rode no Supabase SQL Editor (Run)
-- Seguro rodar de novo: cria o que falta e atualiza políticas.

create table if not exists public.inscricoes_cor_jovem (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  nome text not null,
  nascimento date not null,
  idade integer not null,
  whatsapp text not null,
  endereco text not null,
  bairro text not null,
  cidade text not null,
  uf text not null,
  rede_usuario text,
  rede_nome text,

  menor_idade boolean not null default false,
  responsavel_nome text,
  responsavel_telefone text,
  responsavel_cpf text,

  pais_catolicos text,
  eh_catolico text,
  sacramentos text[] default '{}',
  movimento_pastoral text,
  missas_dominicais text,
  missas_onde text,

  comorbidade text,
  comorbidade_qual text,
  medicamento text,
  medicamento_qual text,
  alergia text,
  alergia_qual text,
  urgencia_nome text not null,
  urgencia_parentesco text,
  urgencia_telefone text not null,

  como_soube text,
  expectativa text,
  camisa text,
  tamanho_camisa text,

  status text not null default 'nova'
    check (status in ('nova', 'confirmada', 'lista_espera', 'cancelada')),
  observacoes text
);

alter table public.inscricoes_cor_jovem
  add column if not exists updated_at timestamptz not null default now();
alter table public.inscricoes_cor_jovem
  add column if not exists status text not null default 'nova';
alter table public.inscricoes_cor_jovem
  add column if not exists observacoes text;
alter table public.inscricoes_cor_jovem
  add column if not exists urgencia_parentesco text;

-- Decúrias (equipes)
create table if not exists public.decurias_cor_jovem (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  nome text not null,
  idade_min integer not null default 15,
  idade_max integer not null default 24,
  decurista_nome text not null,
  observacoes text
);

alter table public.inscricoes_cor_jovem
  add column if not exists decuria_id uuid references public.decurias_cor_jovem(id) on delete set null;

create index if not exists inscricoes_cor_jovem_created_at_idx
  on public.inscricoes_cor_jovem (created_at desc);
create index if not exists inscricoes_cor_jovem_nome_idx
  on public.inscricoes_cor_jovem (nome);
create index if not exists inscricoes_cor_jovem_status_idx
  on public.inscricoes_cor_jovem (status);
create index if not exists inscricoes_cor_jovem_whatsapp_idx
  on public.inscricoes_cor_jovem (whatsapp);
create index if not exists inscricoes_cor_jovem_decuria_idx
  on public.inscricoes_cor_jovem (decuria_id);
create index if not exists decurias_cor_jovem_nome_idx
  on public.decurias_cor_jovem (nome);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_inscricoes_updated_at on public.inscricoes_cor_jovem;
create trigger trg_inscricoes_updated_at
  before update on public.inscricoes_cor_jovem
  for each row execute function public.set_updated_at();

drop trigger if exists trg_decurias_updated_at on public.decurias_cor_jovem;
create trigger trg_decurias_updated_at
  before update on public.decurias_cor_jovem
  for each row execute function public.set_updated_at();

alter table public.inscricoes_cor_jovem enable row level security;
alter table public.decurias_cor_jovem enable row level security;

drop policy if exists "Permitir inserção pública" on public.inscricoes_cor_jovem;
create policy "Permitir inserção pública"
  on public.inscricoes_cor_jovem
  for insert to anon, authenticated
  with check (true);

drop policy if exists "Permitir leitura pública" on public.inscricoes_cor_jovem;
create policy "Permitir leitura pública"
  on public.inscricoes_cor_jovem
  for select to anon, authenticated
  using (true);

drop policy if exists "Permitir update público" on public.inscricoes_cor_jovem;
create policy "Permitir update público"
  on public.inscricoes_cor_jovem
  for update to anon, authenticated
  using (true) with check (true);

drop policy if exists "Permitir exclusão pública" on public.inscricoes_cor_jovem;
create policy "Permitir exclusão pública"
  on public.inscricoes_cor_jovem
  for delete to anon, authenticated
  using (true);

drop policy if exists "Decurias leitura" on public.decurias_cor_jovem;
create policy "Decurias leitura"
  on public.decurias_cor_jovem for select to anon, authenticated using (true);

drop policy if exists "Decurias insert" on public.decurias_cor_jovem;
create policy "Decurias insert"
  on public.decurias_cor_jovem for insert to anon, authenticated with check (true);

drop policy if exists "Decurias update" on public.decurias_cor_jovem;
create policy "Decurias update"
  on public.decurias_cor_jovem for update to anon, authenticated using (true) with check (true);

drop policy if exists "Decurias delete" on public.decurias_cor_jovem;
create policy "Decurias delete"
  on public.decurias_cor_jovem for delete to anon, authenticated using (true);

grant select, insert, update, delete on public.inscricoes_cor_jovem to anon, authenticated;
grant select, insert, update, delete on public.decurias_cor_jovem to anon, authenticated;
grant usage on schema public to anon, authenticated;

notify pgrst, 'reload schema';
