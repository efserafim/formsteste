

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

create table if not exists public.decurias_cor_jovem (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  nome text not null,
  idade_min integer not null default 15,
  idade_max integer not null default 24,
  decurista_nome text not null,
  cor text,
  observacoes text
);

alter table public.decurias_cor_jovem
  add column if not exists cor text;

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

revoke all on function public.count_inscricoes_ativas() from public;
grant execute on function public.count_inscricoes_ativas() to anon, authenticated;

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

alter table public.servos_cor_jovem alter column equipe drop not null;

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

create or replace function public.enforce_inscricoes_limit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  lim constant int := 70;
  n bigint;
begin
  if tg_op = 'UPDATE'
     and old.status is distinct from 'cancelada'
     and new.status is not distinct from 'cancelada' then
    return new;
  end if;
  if tg_op = 'UPDATE' and old.status is not distinct from new.status then
    return new;
  end if;
  if new.status is not distinct from 'cancelada' then
    return new;
  end if;

  perform pg_advisory_xact_lock(872014001);

  select count(*) into n
  from public.inscricoes_cor_jovem
  where status is distinct from 'cancelada'
    and (tg_op = 'INSERT' or id is distinct from new.id);

  if n >= lim then
    raise exception 'VAGAS_ESGOTADAS'
      using errcode = 'P0001',
            hint = 'Limite de inscricoes ativas atingido';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_inscricoes_limit_ins on public.inscricoes_cor_jovem;
create trigger trg_inscricoes_limit_ins
  before insert on public.inscricoes_cor_jovem
  for each row execute function public.enforce_inscricoes_limit();

drop trigger if exists trg_inscricoes_limit_upd on public.inscricoes_cor_jovem;
create trigger trg_inscricoes_limit_upd
  before update of status on public.inscricoes_cor_jovem
  for each row execute function public.enforce_inscricoes_limit();

create table if not exists public.rpc_throttle (
  bucket text not null,
  attempted_at timestamptz not null default now()
);
create index if not exists rpc_throttle_bucket_time_idx
  on public.rpc_throttle (bucket, attempted_at desc);

alter table public.rpc_throttle enable row level security;
revoke all on table public.rpc_throttle from public, anon, authenticated;

create or replace function public.normalize_phone_br(p_raw text)
returns text
language plpgsql
immutable
set search_path = public
as $$
declare
  d text;
begin
  d := regexp_replace(coalesce(p_raw, ''), '\D', '', 'g');
  if left(d, 2) = '55' and length(d) >= 12 then
    d := substr(d, 3);
  end if;
  if length(d) < 10 or length(d) > 11 then
    return null;
  end if;
  return d;
end;
$$;

revoke all on function public.normalize_phone_br(text) from public, anon, authenticated;

create or replace function public.assert_rpc_throttle(
  p_rpc text,
  p_norm text,
  p_max_num int default 5,
  p_max_ip int default 20,
  p_window_sec int default 600
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  hdrs jsonb;
  xf text;
  fp text;
  bucket_num text;
  bucket_ip text;
  n bigint;
  use_ip boolean := false;
begin
  begin
    hdrs := nullif(current_setting('request.headers', true), '')::jsonb;
  exception when others then
    hdrs := null;
  end;

  if hdrs is not null then
    xf := nullif(trim(split_part(coalesce(
      hdrs->>'cf-connecting-ip',
      hdrs->>'x-real-ip',
      hdrs->>'x-forwarded-for',
      ''
    ), ',', 1)), '');
  end if;

  fp := coalesce(nullif(xf, ''), host(inet_client_addr()), 'unknown');
  use_ip := fp is distinct from 'unknown'
    and fp is distinct from '127.0.0.1'
    and fp is distinct from '::1'
    and fp !~ '^(10\.|127\.|172\.(1[6-9]|2\d|3[01])\.|192\.168\.|100\.)';

  bucket_num := p_rpc || ':num:' || md5(p_norm);
  bucket_ip := p_rpc || ':ip:' || md5(fp);

  delete from public.rpc_throttle
  where bucket in (bucket_num, bucket_ip)
    and attempted_at < now() - make_interval(secs => greatest(p_window_sec, 60));

  select count(*) into n
  from public.rpc_throttle
  where bucket = bucket_num
    and attempted_at >= now() - make_interval(secs => p_window_sec);
  if n >= p_max_num then
    raise exception 'RATE_LIMITED'
      using errcode = 'P0001',
            hint = 'Muitas tentativas. Aguarde alguns minutos.';
  end if;

  if use_ip then
    select count(*) into n
    from public.rpc_throttle
    where bucket = bucket_ip
      and attempted_at >= now() - make_interval(secs => p_window_sec);
    if n >= p_max_ip then
      raise exception 'RATE_LIMITED'
        using errcode = 'P0001',
              hint = 'Muitas tentativas. Aguarde alguns minutos.';
    end if;
    insert into public.rpc_throttle (bucket) values (bucket_num), (bucket_ip);
  else
    insert into public.rpc_throttle (bucket) values (bucket_num);
  end if;
end;
$$;

revoke all on function public.assert_rpc_throttle(text, text, int, int, int) from public, anon, authenticated;

create or replace function public.existe_inscricao_whatsapp(p_digits text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  norm text;
begin
  norm := public.normalize_phone_br(p_digits);
  if norm is null then
    return false;
  end if;
  perform public.assert_rpc_throttle('existe_inscricao_whatsapp', norm);
  return exists (
    select 1
    from public.inscricoes_cor_jovem i
    where i.status is distinct from 'cancelada'
      and public.normalize_phone_br(i.whatsapp) = norm
  );
end;
$$;

create or replace function public.existe_servo_telefone(p_digits text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  norm text;
begin
  norm := public.normalize_phone_br(p_digits);
  if norm is null then
    return false;
  end if;
  perform public.assert_rpc_throttle('existe_servo_telefone', norm);
  return exists (
    select 1
    from public.servos_cor_jovem s
    where s.status is distinct from 'cancelada'
      and public.normalize_phone_br(s.telefone) = norm
  );
end;
$$;

drop function if exists public.buscar_inscricao_whatsapp(text);
create function public.buscar_inscricao_whatsapp(p_digits text)
returns table (id uuid, primeiro_nome text, status text)
language plpgsql
security definer
set search_path = public
as $$
declare
  norm text;
begin
  norm := public.normalize_phone_br(p_digits);
  if norm is null then
    return;
  end if;
  perform public.assert_rpc_throttle('buscar_inscricao_whatsapp', norm);
  return query
    select i.id,
           split_part(btrim(i.nome), ' ', 1)::text,
           i.status
    from public.inscricoes_cor_jovem i
    where i.status is distinct from 'cancelada'
      and public.normalize_phone_br(i.whatsapp) = norm;
end;
$$;

drop function if exists public.buscar_servo_telefone(text);
create function public.buscar_servo_telefone(p_digits text)
returns table (id uuid, primeiro_nome text, status text)
language plpgsql
security definer
set search_path = public
as $$
declare
  norm text;
begin
  norm := public.normalize_phone_br(p_digits);
  if norm is null then
    return;
  end if;
  perform public.assert_rpc_throttle('buscar_servo_telefone', norm);
  return query
    select s.id,
           split_part(btrim(s.nome), ' ', 1)::text,
           s.status
    from public.servos_cor_jovem s
    where s.status is distinct from 'cancelada'
      and public.normalize_phone_br(s.telefone) = norm;
end;
$$;

revoke all on function public.existe_inscricao_whatsapp(text) from public;
revoke all on function public.existe_servo_telefone(text) from public;
grant execute on function public.existe_inscricao_whatsapp(text) to anon, authenticated;
grant execute on function public.existe_servo_telefone(text) to anon, authenticated;

revoke all on function public.buscar_inscricao_whatsapp(text) from public;
revoke all on function public.buscar_inscricao_whatsapp(text) from anon, authenticated;
revoke all on function public.buscar_servo_telefone(text) from public;
revoke all on function public.buscar_servo_telefone(text) from anon, authenticated;

drop policy if exists "Servos fotos upload" on storage.objects;
create policy "Servos fotos upload"
  on storage.objects for insert to anon, authenticated
  with check (
    bucket_id = 'fotos-servos'
    and (storage.extension(name) = any (array['jpg','jpeg','png','webp','gif']))
    and (
      coalesce((metadata->>'size')::bigint, 0) = 0
      or (metadata->>'size')::bigint <= 2621440
    )
    and (
      metadata->>'mimetype' is null
      or metadata->>'mimetype' like 'image/%'
    )
  );

create table if not exists public.auditoria_cor_jovem (
  id bigserial primary key,
  created_at timestamptz not null default now(),
  actor uuid,
  action text not null,
  table_name text not null,
  row_id uuid,
  detail jsonb
);
alter table public.auditoria_cor_jovem enable row level security;
drop policy if exists "Auditoria select equipe" on public.auditoria_cor_jovem;
create policy "Auditoria select equipe"
  on public.auditoria_cor_jovem for select to authenticated using (true);
revoke all on public.auditoria_cor_jovem from anon;
grant select on public.auditoria_cor_jovem to authenticated;

create or replace function public.log_auditoria_row()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'DELETE' then
    insert into public.auditoria_cor_jovem (actor, action, table_name, row_id, detail)
    values (auth.uid(), 'DELETE', tg_table_name, old.id, to_jsonb(old));
    return old;
  elsif tg_op = 'UPDATE' then
    insert into public.auditoria_cor_jovem (actor, action, table_name, row_id, detail)
    values (auth.uid(), 'UPDATE', tg_table_name, new.id,
      jsonb_build_object('old', to_jsonb(old), 'new', to_jsonb(new)));
    return new;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_audit_inscricoes on public.inscricoes_cor_jovem;
create trigger trg_audit_inscricoes
  after update or delete on public.inscricoes_cor_jovem
  for each row execute function public.log_auditoria_row();

drop trigger if exists trg_audit_servos on public.servos_cor_jovem;
create trigger trg_audit_servos
  after update or delete on public.servos_cor_jovem
  for each row execute function public.log_auditoria_row();

notify pgrst, 'reload schema';
