-- MultiApp v0.8: Haushalte, Mitglieder, Einladungen
--
-- Ausfuehren im Supabase-Dashboard unter "SQL Editor" (einmal komplett).
-- Idempotent genug fuer wiederholtes Ausfuehren waehrend der Entwicklung.
--
-- Sicherheitsmodell:
--   * Row Level Security regelt das LESEN (nur eigene Haushalte/Mitglieder).
--   * Alle Aenderungen laufen ueber SECURITY-DEFINER-Funktionen (RPC), die die
--     Rollenlogik zentral und atomar durchsetzen. Direkte INSERT/UPDATE/DELETE
--     vom Client sind durch RLS gesperrt.

-- =========================================================================
-- Tabellen
-- =========================================================================

create table if not exists public.households (
  id            uuid primary key default gen_random_uuid(),
  name          text not null check (char_length(name) between 1 and 80),
  owner_user_id uuid not null references auth.users (id) on delete cascade,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create table if not exists public.household_members (
  id            uuid primary key default gen_random_uuid(),
  household_id  uuid not null references public.households (id) on delete cascade,
  user_id       uuid not null references auth.users (id) on delete cascade,
  display_name  text not null default '',
  role          text not null default 'member'
                  check (role in ('owner', 'admin', 'member', 'guest')),
  joined_at     timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  unique (household_id, user_id)
);

create index if not exists household_members_user_idx
  on public.household_members (user_id);

create table if not exists public.household_invites (
  id            uuid primary key default gen_random_uuid(),
  household_id  uuid not null references public.households (id) on delete cascade,
  code          text not null unique,
  role          text not null default 'member'
                  check (role in ('admin', 'member', 'guest')),
  created_by    uuid not null references auth.users (id) on delete cascade,
  created_at    timestamptz not null default now(),
  expires_at    timestamptz,
  max_uses      integer,
  uses          integer not null default 0,
  active        boolean not null default true
);

create index if not exists household_invites_household_idx
  on public.household_invites (household_id);

-- =========================================================================
-- Hilfsfunktionen (SECURITY DEFINER, umgehen RLS -> keine Rekursion)
-- =========================================================================

create or replace function public.is_household_member(_household uuid, _user uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists(
    select 1 from public.household_members m
    where m.household_id = _household and m.user_id = _user
  );
$$;

create or replace function public.my_role(_household uuid)
returns text
language sql
security definer
stable
set search_path = public
as $$
  select role from public.household_members
  where household_id = _household and user_id = auth.uid();
$$;

-- Rangfolge einer Rolle (owner > admin > member > guest).
create or replace function public.role_rank(_role text)
returns integer
language sql
immutable
as $$
  select case _role
    when 'owner'  then 300
    when 'admin'  then 200
    when 'member' then 100
    when 'guest'  then 10
    else 0 end;
$$;

-- =========================================================================
-- Row Level Security
-- =========================================================================

alter table public.households        enable row level security;
alter table public.household_members enable row level security;
alter table public.household_invites enable row level security;

-- Haushalte: sichtbar fuer Mitglieder.
drop policy if exists households_select on public.households;
create policy households_select on public.households
  for select using (public.is_household_member(id, auth.uid()));

-- Mitglieder: sichtbar fuer Mitglieder desselben Haushalts.
drop policy if exists members_select on public.household_members;
create policy members_select on public.household_members
  for select using (public.is_household_member(household_id, auth.uid()));

-- Einladungen: nur Owner/Admin sehen die Liste.
drop policy if exists invites_select on public.household_invites;
create policy invites_select on public.household_invites
  for select using (public.my_role(household_id) in ('owner', 'admin'));

-- Keine direkten Schreib-Policies: Aenderungen nur ueber die RPCs unten.

-- =========================================================================
-- RPC: Haushalt erstellen
-- =========================================================================

create or replace function public.create_household(_name text, _display_name text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  _uid uuid := auth.uid();
  _id  uuid;
begin
  if _uid is null then
    raise exception 'Nicht angemeldet';
  end if;

  insert into public.households (name, owner_user_id)
  values (_name, _uid)
  returning id into _id;

  insert into public.household_members (household_id, user_id, display_name, role)
  values (_id, _uid, coalesce(nullif(_display_name, ''), 'Ich'), 'owner');

  return _id;
end;
$$;

-- =========================================================================
-- RPC: Haushalt umbenennen (Owner/Admin)
-- =========================================================================

create or replace function public.rename_household(_household uuid, _name text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.my_role(_household) not in ('owner', 'admin') then
    raise exception 'Keine Berechtigung';
  end if;
  update public.households
  set name = _name, updated_at = now()
  where id = _household;
end;
$$;

-- =========================================================================
-- RPC: Einladung erstellen (Owner/Admin)
-- =========================================================================

create or replace function public.create_invite(
  _household uuid,
  _role text default 'member',
  _expires_at timestamptz default null,
  _max_uses integer default null
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  _my_role text := public.my_role(_household);
  _code    text;
  _alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  i int;
begin
  if _my_role not in ('owner', 'admin') then
    raise exception 'Keine Berechtigung';
  end if;
  if _role not in ('admin', 'member', 'guest') then
    raise exception 'Ungueltige Rolle';
  end if;
  -- Nur der Owner darf zum Admin einladen.
  if _role = 'admin' and _my_role <> 'owner' then
    raise exception 'Nur der Eigentuemer darf Admins einladen';
  end if;

  -- Achtstelligen, gut vorlesbaren Code erzeugen (ohne O/0/I/1).
  loop
    _code := '';
    for i in 1..8 loop
      _code := _code || substr(_alphabet, 1 + floor(random() * length(_alphabet))::int, 1);
    end loop;
    exit when not exists (select 1 from public.household_invites where code = _code);
  end loop;

  insert into public.household_invites
    (household_id, code, role, created_by, expires_at, max_uses)
  values
    (_household, _code, _role, auth.uid(), _expires_at, _max_uses);

  return _code;
end;
$$;

-- =========================================================================
-- RPC: Einladung widerrufen (Owner/Admin)
-- =========================================================================

create or replace function public.revoke_invite(_invite uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  _household uuid;
begin
  select household_id into _household from public.household_invites where id = _invite;
  if _household is null then
    return;
  end if;
  if public.my_role(_household) not in ('owner', 'admin') then
    raise exception 'Keine Berechtigung';
  end if;
  update public.household_invites set active = false where id = _invite;
end;
$$;

-- =========================================================================
-- RPC: Mit Code beitreten
-- =========================================================================

create or replace function public.join_with_code(_code text, _display_name text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  _uid uuid := auth.uid();
  _inv public.household_invites;
begin
  if _uid is null then
    raise exception 'Nicht angemeldet';
  end if;

  select * into _inv from public.household_invites
  where upper(code) = upper(_code) and active
  limit 1;

  if _inv.id is null then
    raise exception 'Code ungueltig';
  end if;
  if _inv.expires_at is not null and _inv.expires_at < now() then
    raise exception 'Code abgelaufen';
  end if;
  if _inv.max_uses is not null and _inv.uses >= _inv.max_uses then
    raise exception 'Code aufgebraucht';
  end if;

  -- Schon Mitglied? Dann einfach die Haushalts-ID zurueckgeben.
  if public.is_household_member(_inv.household_id, _uid) then
    return _inv.household_id;
  end if;

  insert into public.household_members (household_id, user_id, display_name, role)
  values (_inv.household_id, _uid, coalesce(nullif(_display_name, ''), 'Ich'), _inv.role);

  update public.household_invites set uses = uses + 1 where id = _inv.id;

  return _inv.household_id;
end;
$$;

-- =========================================================================
-- RPC: Rolle aendern
-- =========================================================================

create or replace function public.set_member_role(
  _household uuid, _user uuid, _role text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  _my_role     text := public.my_role(_household);
  _target_role text;
begin
  if _role not in ('admin', 'member', 'guest') then
    raise exception 'Ungueltige Rolle';
  end if;
  select role into _target_role from public.household_members
  where household_id = _household and user_id = _user;
  if _target_role is null then
    raise exception 'Mitglied nicht gefunden';
  end if;
  if _target_role = 'owner' then
    raise exception 'Die Rolle des Eigentuemers kann nicht geaendert werden';
  end if;

  -- Owner darf alles (ausser owner vergeben). Admin darf nur Nicht-Admins
  -- verwalten und niemanden zum Admin machen.
  if _my_role = 'owner' then
    null;
  elsif _my_role = 'admin' then
    if _role = 'admin' or public.role_rank(_target_role) >= public.role_rank('admin') then
      raise exception 'Admins duerfen keine Admins ernennen oder aendern';
    end if;
  else
    raise exception 'Keine Berechtigung';
  end if;

  update public.household_members
  set role = _role, updated_at = now()
  where household_id = _household and user_id = _user;
end;
$$;

-- =========================================================================
-- RPC: Mitglied entfernen
-- =========================================================================

create or replace function public.remove_member(_household uuid, _user uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  _my_role     text := public.my_role(_household);
  _target_role text;
begin
  select role into _target_role from public.household_members
  where household_id = _household and user_id = _user;
  if _target_role is null then
    return;
  end if;
  if _target_role = 'owner' then
    raise exception 'Der Eigentuemer kann nicht entfernt werden';
  end if;
  if _my_role = 'owner' then
    null;
  elsif _my_role = 'admin' and public.role_rank(_target_role) < public.role_rank('admin') then
    null;
  else
    raise exception 'Keine Berechtigung';
  end if;

  delete from public.household_members
  where household_id = _household and user_id = _user;
end;
$$;

-- =========================================================================
-- RPC: Haushalt verlassen
-- =========================================================================

create or replace function public.leave_household(_household uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  _uid uuid := auth.uid();
  _my_role text := public.my_role(_household);
  _member_count int;
begin
  if _my_role is null then
    return;
  end if;
  if _my_role = 'owner' then
    select count(*) into _member_count from public.household_members
    where household_id = _household;
    if _member_count > 1 then
      raise exception 'Bitte zuerst die Eigentuemerschaft uebergeben oder den Haushalt aufloesen';
    end if;
    -- Letztes Mitglied: Haushalt komplett aufloesen.
    delete from public.households where id = _household;
    return;
  end if;

  delete from public.household_members
  where household_id = _household and user_id = _uid;
end;
$$;

-- =========================================================================
-- RPC: Eigentuemerschaft uebergeben (nur Owner)
-- =========================================================================

create or replace function public.transfer_ownership(_household uuid, _new_owner uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.my_role(_household) <> 'owner' then
    raise exception 'Nur der Eigentuemer kann uebergeben';
  end if;
  if not public.is_household_member(_household, _new_owner) then
    raise exception 'Neuer Eigentuemer ist kein Mitglied';
  end if;

  update public.household_members set role = 'admin', updated_at = now()
  where household_id = _household and user_id = auth.uid();

  update public.household_members set role = 'owner', updated_at = now()
  where household_id = _household and user_id = _new_owner;

  update public.households set owner_user_id = _new_owner, updated_at = now()
  where id = _household;
end;
$$;

-- =========================================================================
-- RPC: Haushalt aufloesen (nur Owner)
-- =========================================================================

create or replace function public.delete_household(_household uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.my_role(_household) <> 'owner' then
    raise exception 'Nur der Eigentuemer kann den Haushalt aufloesen';
  end if;
  delete from public.households where id = _household;
end;
$$;

-- =========================================================================
-- Realtime aktivieren (fuer Live-Updates von Mitgliedern/Haushalten)
-- =========================================================================

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public'
      and tablename = 'household_members'
  ) then
    alter publication supabase_realtime add table public.household_members;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public'
      and tablename = 'households'
  ) then
    alter publication supabase_realtime add table public.households;
  end if;
end $$;
