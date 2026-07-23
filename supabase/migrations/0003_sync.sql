-- MultiApp v0.9: Sync-Backend fuer die Modul-Inhalte.
--
-- Ein generischer Ansatz: ALLE synchronisierten Tabellen der App landen als
-- JSON in einer einzigen Tabelle sync_records. Der Server ist reiner
-- Abgleichspartner + Rechte-Gate; abgefragt wird lokal (Drift bleibt die
-- Wahrheit fuer die Oberflaeche).
--
-- Konfliktloesung:
--   * Last-Write-Wins ueber updated_at (Client-Zeit) fuer normale Felder.
--   * Additive Zusammenfuehrung fuer Zaehler (z.B. Vorratsmenge): der Client
--     schickt Deltas, der Server addiert sie atomar. So geht bei gleichzeitigem
--     Verbrauch auf zwei Geraeten nichts verloren.
--
-- Einmal im Supabase SQL Editor ausfuehren (idempotent).

-- =========================================================================
-- Zugriffs-Hilfsfunktion (personal = eigener Nutzer, household = Mitglied)
-- =========================================================================

create or replace function public.can_access_scope(_kind text, _id text)
returns boolean
language plpgsql
security definer
stable
set search_path = public
as $$
begin
  if auth.uid() is null then
    return false;
  end if;
  if _kind = 'personal' then
    return _id = auth.uid()::text;
  elsif _kind = 'household' then
    return public.is_household_member(_id::uuid, auth.uid());
  end if;
  return false;
end;
$$;

-- =========================================================================
-- Tabelle
-- =========================================================================

create table if not exists public.sync_records (
  table_name  text not null,
  id          uuid not null,
  scope_kind  text not null,
  scope_id    text not null,
  updated_at  timestamptz not null,
  deleted_at  timestamptz,
  data        jsonb not null,
  updated_by  uuid,
  -- Server-Zeitstempel, robust gegen abweichende Geraeteuhren; danach wird
  -- beim Pull abgefragt.
  synced_at   timestamptz not null default now(),
  primary key (table_name, id)
);

create index if not exists sync_records_synced_idx
  on public.sync_records (synced_at);
create index if not exists sync_records_scope_idx
  on public.sync_records (scope_kind, scope_id);

alter table public.sync_records enable row level security;

drop policy if exists sync_select on public.sync_records;
create policy sync_select on public.sync_records
  for select using (public.can_access_scope(scope_kind, scope_id));

grant usage on schema public to authenticated;
grant select on public.sync_records to authenticated;

-- =========================================================================
-- RPC: einen Datensatz hochschieben (LWW + additive Zaehler)
-- =========================================================================
--
--  _counter_deltas: JSON-Objekt {feld: delta}, z.B. {"quantity": -2}. Diese
--  Felder werden serverseitig additiv angewendet, unabhaengig von LWW.

create or replace function public.push_record(
  _table text,
  _id uuid,
  _scope_kind text,
  _scope_id text,
  _updated_at timestamptz,
  _deleted_at timestamptz,
  _data jsonb,
  _counter_deltas jsonb default '{}'::jsonb
)
returns timestamptz
language plpgsql
security definer
set search_path = public
as $$
declare
  _existing public.sync_records;
  _merged   jsonb;
  _field    text;
  _now      timestamptz := now();
begin
  if not public.can_access_scope(_scope_kind, _scope_id) then
    raise exception 'Kein Zugriff auf diesen Bereich';
  end if;

  select * into _existing
  from public.sync_records
  where table_name = _table and id = _id;

  -- Neu: einfach anlegen (Zaehler stecken bereits in _data).
  if _existing.id is null then
    insert into public.sync_records
      (table_name, id, scope_kind, scope_id, updated_at, deleted_at, data,
       updated_by, synced_at)
    values
      (_table, _id, _scope_kind, _scope_id, _updated_at, _deleted_at, _data,
       auth.uid(), _now);
    return _now;
  end if;

  -- Basis der Nicht-Zaehler-Felder per LWW.
  if _updated_at >= _existing.updated_at then
    _merged := _data;
  else
    _merged := _existing.data;
  end if;

  -- Zaehler immer additiv: Server-Stand + Delta (unabhaengig von LWW).
  for _field in select jsonb_object_keys(_counter_deltas) loop
    _merged := jsonb_set(
      _merged,
      array[_field],
      to_jsonb(
        coalesce((_existing.data ->> _field)::numeric, 0)
        + coalesce((_counter_deltas ->> _field)::numeric, 0)
      )
    );
  end loop;

  update public.sync_records set
    data       = _merged,
    updated_at = greatest(_updated_at, _existing.updated_at),
    deleted_at = case when _updated_at >= _existing.updated_at
                      then _deleted_at else _existing.deleted_at end,
    updated_by = auth.uid(),
    synced_at  = _now
  where table_name = _table and id = _id;

  return _now;
end;
$$;

grant execute on function public.can_access_scope(text, text) to authenticated;
grant execute on function
  public.push_record(text, uuid, text, text, timestamptz, timestamptz, jsonb, jsonb)
  to authenticated;

-- =========================================================================
-- Realtime
-- =========================================================================

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public'
      and tablename = 'sync_records'
  ) then
    alter publication supabase_realtime add table public.sync_records;
  end if;
end $$;
