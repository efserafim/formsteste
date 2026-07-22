-- XVI C.O.R Jovem — sql/setup.sql
-- Rode no Supabase SQL Editor (Run)
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

-- Políticas antigas (remover)
drop policy if exists "Permitir inserção pública" on public.inscricoes_cor_jovem;
drop policy if exists "Permitir leitura pública" on public.inscricoes_cor_jovem;
drop policy if exists "Permitir update público" on public.inscricoes_cor_jovem;
drop policy if exists "Permitir exclusão pública" on public.inscricoes_cor_jovem;
drop policy if exists "Inscricoes insert publico" on public.inscricoes_cor_jovem;
drop policy if exists "Inscricoes select equipe" on public.inscricoes_cor_jovem;
drop policy if exists "Inscricoes update equipe" on public.inscricoes_cor_jovem;
drop policy if exists "Inscricoes delete equipe" on public.inscricoes_cor_jovem;
drop policy if exists "Decurias leitura" on public.decurias_cor_jovem;
drop policy if exists "Decurias insert" on public.decurias_cor_jovem;
drop policy if exists "Decurias update" on public.decurias_cor_jovem;
drop policy if exists "Decurias delete" on public.decurias_cor_jovem;
drop policy if exists "Decurias select equipe" on public.decurias_cor_jovem;
drop policy if exists "Decurias insert equipe" on public.decurias_cor_jovem;
drop policy if exists "Decurias update equipe" on public.decurias_cor_jovem;
drop policy if exists "Decurias delete equipe" on public.decurias_cor_jovem;

-- Público: só inserir ficha. Equipe autenticada: ler/editar/apagar.
create policy "Inscricoes insert publico"
  on public.inscricoes_cor_jovem
  for insert to anon, authenticated
  with check (true);

create policy "Inscricoes select equipe"
  on public.inscricoes_cor_jovem
  for select to authenticated
  using (true);

create policy "Inscricoes update equipe"
  on public.inscricoes_cor_jovem
  for update to authenticated
  using (true) with check (true);

create policy "Inscricoes delete equipe"
  on public.inscricoes_cor_jovem
  for delete to authenticated
  using (true);

create policy "Decurias select equipe"
  on public.decurias_cor_jovem for select to authenticated using (true);

create policy "Decurias insert equipe"
  on public.decurias_cor_jovem for insert to authenticated with check (true);

create policy "Decurias update equipe"
  on public.decurias_cor_jovem for update to authenticated using (true) with check (true);

create policy "Decurias delete equipe"
  on public.decurias_cor_jovem for delete to authenticated using (true);

grant select, insert, update, delete on public.inscricoes_cor_jovem to anon, authenticated;
grant select, insert, update, delete on public.decurias_cor_jovem to anon, authenticated;
grant usage on schema public to anon, authenticated;

-- RPCs públicas (não expõem a tabela inteira)
create or replace function public.count_inscricoes_ativas()
returns bigint
language sql
security definer
set search_path = public
stable
as $$
  select count(*)::bigint
  from public.inscricoes_cor_jovem
  where status is distinct from 'cancelada';
$$;

create or replace function public.buscar_inscricao_whatsapp(p_digits text)
returns table (id uuid, nome text, status text)
language sql
security definer
set search_path = public
stable
as $$
  select i.id, i.nome, i.status
  from public.inscricoes_cor_jovem i
  where length(regexp_replace(coalesce(p_digits, ''), '\D', '', 'g')) >= 8
    and right(regexp_replace(coalesce(i.whatsapp, ''), '\D', '', 'g'), 8)
      = right(regexp_replace(coalesce(p_digits, ''), '\D', '', 'g'), 8);
$$;

revoke all on function public.count_inscricoes_ativas() from public;
revoke all on function public.buscar_inscricao_whatsapp(text) from public;
grant execute on function public.count_inscricoes_ativas() to anon, authenticated;
grant execute on function public.buscar_inscricao_whatsapp(text) to anon, authenticated;

-- Servos (equipe)
create table if not exists public.servos_cor_jovem (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  nome text not null,
  idade integer not null,
  nascimento date not null,
  endereco text not null,
  telefone text not null,

  camisa text,
  tamanho_camisa text,
  equipe text,
  ano_cor_jovem text not null,
  marco_cor text not null,
  oracao_sacramentos text not null,
  sacramentos text[] default '{}',
  foto_url text,

  status text not null default 'nova'
    check (status in ('nova', 'confirmada', 'lista_espera', 'cancelada')),
  observacoes text
);

drop trigger if exists trg_servos_updated_at on public.servos_cor_jovem;
create trigger trg_servos_updated_at
  before update on public.servos_cor_jovem
  for each row execute function public.set_updated_at();

create index if not exists servos_cor_jovem_created_at_idx
  on public.servos_cor_jovem (created_at desc);
create index if not exists servos_cor_jovem_status_idx
  on public.servos_cor_jovem (status);
create index if not exists servos_cor_jovem_telefone_idx
  on public.servos_cor_jovem (telefone);

alter table public.servos_cor_jovem enable row level security;

drop policy if exists "Servos insert" on public.servos_cor_jovem;
drop policy if exists "Servos select" on public.servos_cor_jovem;
drop policy if exists "Servos update" on public.servos_cor_jovem;
drop policy if exists "Servos delete" on public.servos_cor_jovem;
drop policy if exists "Servos insert publico" on public.servos_cor_jovem;
drop policy if exists "Servos select equipe" on public.servos_cor_jovem;
drop policy if exists "Servos update equipe" on public.servos_cor_jovem;
drop policy if exists "Servos delete equipe" on public.servos_cor_jovem;

create policy "Servos insert publico"
  on public.servos_cor_jovem for insert to anon, authenticated with check (true);

create policy "Servos select equipe"
  on public.servos_cor_jovem for select to authenticated using (true);

create policy "Servos update equipe"
  on public.servos_cor_jovem for update to authenticated using (true) with check (true);

create policy "Servos delete equipe"
  on public.servos_cor_jovem for delete to authenticated using (true);

grant select, insert, update, delete on public.servos_cor_jovem to anon, authenticated;

-- Equipe passa a ser opcional (definida pela organização no painel)
alter table public.servos_cor_jovem alter column equipe drop not null;

create or replace function public.buscar_servo_telefone(p_digits text)
returns table (id uuid, nome text, status text)
language sql
security definer
set search_path = public
stable
as $$
  select s.id, s.nome, s.status
  from public.servos_cor_jovem s
  where length(regexp_replace(coalesce(p_digits, ''), '\D', '', 'g')) >= 8
    and right(regexp_replace(coalesce(s.telefone, ''), '\D', '', 'g'), 8)
      = right(regexp_replace(coalesce(p_digits, ''), '\D', '', 'g'), 8);
$$;

revoke all on function public.buscar_servo_telefone(text) from public;
grant execute on function public.buscar_servo_telefone(text) to anon, authenticated;

-- Storage de fotos (rode no SQL; se o bucket já existir, ignore o erro)
insert into storage.buckets (id, name, public)
values ('fotos-servos', 'fotos-servos', true)
on conflict (id) do nothing;

drop policy if exists "Servos fotos upload" on storage.objects;
create policy "Servos fotos upload"
  on storage.objects for insert to anon, authenticated
  with check (bucket_id = 'fotos-servos');

drop policy if exists "Servos fotos leitura" on storage.objects;
create policy "Servos fotos leitura"
  on storage.objects for select to anon, authenticated
  using (bucket_id = 'fotos-servos');

notify pgrst, 'reload schema';
