-- XVI C.O.R Jovem — sql/auth-rls.sql
-- Use se as tabelas já existem e só precisa endurecer Auth/RLS
-- 1) Authentication → Users → Add user (e-mail + senha da equipe)
-- 2) Authentication → Providers → Email → desative "Enable sign ups" (opcional, recomendado)
-- 3) Rode este SQL (ou sql/setup.sql completo)

-- Remover políticas abertas antigas
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

-- Equipe opcional: preenchida depois no dashboard
alter table public.servos_cor_jovem alter column equipe drop not null;

create or replace function public.count_inscricoes_ativas()
returns bigint language sql security definer set search_path = public stable as $$
  select count(*)::bigint from public.inscricoes_cor_jovem
  where status is distinct from 'cancelada';
$$;

create or replace function public.buscar_inscricao_whatsapp(p_digits text)
returns table (id uuid, nome text, status text)
language sql security definer set search_path = public stable as $$
  select i.id, i.nome, i.status
  from public.inscricoes_cor_jovem i
  where length(regexp_replace(coalesce(p_digits, ''), '\D', '', 'g')) >= 8
    and right(regexp_replace(coalesce(i.whatsapp, ''), '\D', '', 'g'), 8)
      = right(regexp_replace(coalesce(p_digits, ''), '\D', '', 'g'), 8);
$$;

create or replace function public.buscar_servo_telefone(p_digits text)
returns table (id uuid, nome text, status text)
language sql security definer set search_path = public stable as $$
  select s.id, s.nome, s.status
  from public.servos_cor_jovem s
  where length(regexp_replace(coalesce(p_digits, ''), '\D', '', 'g')) >= 8
    and right(regexp_replace(coalesce(s.telefone, ''), '\D', '', 'g'), 8)
      = right(regexp_replace(coalesce(p_digits, ''), '\D', '', 'g'), 8);
$$;

revoke all on function public.count_inscricoes_ativas() from public;
revoke all on function public.buscar_inscricao_whatsapp(text) from public;
revoke all on function public.buscar_servo_telefone(text) from public;
grant execute on function public.count_inscricoes_ativas() to anon, authenticated;
grant execute on function public.buscar_inscricao_whatsapp(text) to anon, authenticated;
grant execute on function public.buscar_servo_telefone(text) to anon, authenticated;

notify pgrst, 'reload schema';
