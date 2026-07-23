-- MultiApp v0.10: Familien-Ereignisse (Realtime-Push ohne Firebase).
--
-- Ein laufendes Geraet erkennt eine Situation (z.B. verpasste Pille, Tier nicht
-- gefuettert) und legt hier ein Ereignis an. Alle verbundenen Geraete des
-- Haushalts bekommen es per Realtime und zeigen eine lokale Benachrichtigung.
--
-- Einmal im Supabase SQL Editor ausfuehren (idempotent).

create table if not exists public.household_events (
  id             uuid primary key default gen_random_uuid(),
  household_id   uuid not null references public.households (id) on delete cascade,
  kind           text not null,
  title          text not null,
  body           text not null default '',
  -- Ziel: NULL = an alle Mitglieder, sonst gezielt an eine Person.
  target_user_id uuid references auth.users (id) on delete cascade,
  created_by     uuid not null references auth.users (id) on delete cascade,
  -- Verhindert Doppel-Ereignisse (mehrere Geraete melden dasselbe).
  dedup_key      text,
  created_at     timestamptz not null default now()
);

create index if not exists household_events_household_idx
  on public.household_events (household_id, created_at);

alter table public.household_events enable row level security;

drop policy if exists events_select on public.household_events;
create policy events_select on public.household_events
  for select using (
    public.is_household_member(household_id, auth.uid())
    and (target_user_id is null or target_user_id = auth.uid())
  );

grant usage on schema public to authenticated;
grant select on public.household_events to authenticated;

-- =========================================================================
-- RPC: Ereignis anlegen (Mitglied), mit Doppel-Schutz
-- =========================================================================

create or replace function public.post_household_event(
  _household uuid,
  _kind text,
  _title text,
  _body text default '',
  _target_user uuid default null,
  _dedup_key text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  _id uuid;
begin
  if public.my_role(_household) is null then
    raise exception 'Kein Mitglied dieses Haushalts';
  end if;

  -- Innerhalb von 12 Stunden dasselbe Ereignis nur einmal.
  if _dedup_key is not null and exists (
    select 1 from public.household_events
    where household_id = _household
      and dedup_key = _dedup_key
      and created_at > now() - interval '12 hours'
  ) then
    return null;
  end if;

  insert into public.household_events
    (household_id, kind, title, body, target_user_id, created_by, dedup_key)
  values
    (_household, _kind, _title, _body, _target_user, auth.uid(), _dedup_key)
  returning id into _id;

  return _id;
end;
$$;

grant execute on function
  public.post_household_event(uuid, text, text, text, uuid, text)
  to authenticated;

-- =========================================================================
-- Realtime
-- =========================================================================

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public'
      and tablename = 'household_events'
  ) then
    alter publication supabase_realtime add table public.household_events;
  end if;
end $$;
