

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
drop policy if exists "Servos insert" on public.servos_cor_jovem;
drop policy if exists "Servos select" on public.servos_cor_jovem;
drop policy if exists "Servos update" on public.servos_cor_jovem;
drop policy if exists "Servos delete" on public.servos_cor_jovem;
drop policy if exists "Servos insert publico" on public.servos_cor_jovem;
drop policy if exists "Servos select equipe" on public.servos_cor_jovem;
drop policy if exists "Servos update equipe" on public.servos_cor_jovem;
drop policy if exists "Servos delete equipe" on public.servos_cor_jovem;

alter table public.inscricoes_cor_jovem enable row level security;
alter table public.decurias_cor_jovem enable row level security;
alter table public.servos_cor_jovem enable row level security;

create policy "Inscricoes insert publico"
  on public.inscricoes_cor_jovem for insert to anon, authenticated with check (true);
create policy "Inscricoes select equipe"
  on public.inscricoes_cor_jovem for select to authenticated using (true);
create policy "Inscricoes update equipe"
  on public.inscricoes_cor_jovem for update to authenticated using (true) with check (true);
create policy "Inscricoes delete equipe"
  on public.inscricoes_cor_jovem for delete to authenticated using (true);

create policy "Decurias select equipe"
  on public.decurias_cor_jovem for select to authenticated using (true);
create policy "Decurias insert equipe"
  on public.decurias_cor_jovem for insert to authenticated with check (true);
create policy "Decurias update equipe"
  on public.decurias_cor_jovem for update to authenticated using (true) with check (true);
create policy "Decurias delete equipe"
  on public.decurias_cor_jovem for delete to authenticated using (true);

create policy "Servos insert publico"
  on public.servos_cor_jovem for insert to anon, authenticated with check (true);
create policy "Servos select equipe"
  on public.servos_cor_jovem for select to authenticated using (true);
create policy "Servos update equipe"
  on public.servos_cor_jovem for update to authenticated using (true) with check (true);
create policy "Servos delete equipe"
  on public.servos_cor_jovem for delete to authenticated using (true);

alter table public.servos_cor_jovem alter column equipe drop not null;

alter table public.decurias_cor_jovem
  add column if not exists cor text;

create or replace function public.count_inscricoes_ativas()
returns bigint language sql security definer set search_path = public stable as $$
  select count(*)::bigint from public.inscricoes_cor_jovem
  where status is distinct from 'cancelada';
$$;

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

revoke all on function public.count_inscricoes_ativas() from public;
grant execute on function public.count_inscricoes_ativas() to anon, authenticated;

revoke all on function public.existe_inscricao_whatsapp(text) from public;
revoke all on function public.existe_servo_telefone(text) from public;
grant execute on function public.existe_inscricao_whatsapp(text) to anon, authenticated;
grant execute on function public.existe_servo_telefone(text) to anon, authenticated;

revoke all on function public.buscar_inscricao_whatsapp(text) from public;
revoke all on function public.buscar_inscricao_whatsapp(text) from anon, authenticated;
revoke all on function public.buscar_servo_telefone(text) from public;
revoke all on function public.buscar_servo_telefone(text) from anon, authenticated;

notify pgrst, 'reload schema';

