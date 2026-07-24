-- MultiApp v0.13: Geraete-Tokens fuer FCM-Push (echter Push bei geschlossener
-- App, nur Android).
--
-- Der Client meldet nach dem Login seinen FCM-Token hier an. Eine Edge Function
-- (notify-fcm) liest die Tokens der Zielpersonen, sobald ein household_event
-- entsteht, und schickt den Push ueber Firebase.
--
-- Einmal im Supabase SQL Editor ausfuehren (idempotent).

create table if not exists public.device_tokens (
  token       text primary key,
  user_id     uuid not null references auth.users (id) on delete cascade,
  platform    text not null default 'android',
  updated_at  timestamptz not null default now()
);

create index if not exists device_tokens_user_idx
  on public.device_tokens (user_id);

alter table public.device_tokens enable row level security;

-- Der Client liest nur seine eigenen Tokens; geschrieben wird ueber die RPCs.
drop policy if exists device_tokens_select on public.device_tokens;
create policy device_tokens_select on public.device_tokens
  for select using (user_id = auth.uid());

grant usage on schema public to authenticated;
grant select on public.device_tokens to authenticated;

-- =========================================================================
-- RPC: Token anmelden (an den aktuellen Nutzer binden)
-- =========================================================================

create or replace function public.upsert_device_token(_token text, _platform text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  _uid uuid := auth.uid();
begin
  if _uid is null then
    raise exception 'Nicht angemeldet';
  end if;
  insert into public.device_tokens (token, user_id, platform, updated_at)
  values (_token, _uid, coalesce(nullif(_platform, ''), 'android'), now())
  on conflict (token) do update
    set user_id = excluded.user_id,
        platform = excluded.platform,
        updated_at = now();
end;
$$;

-- =========================================================================
-- RPC: Token abmelden
-- =========================================================================

create or replace function public.delete_device_token(_token text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.device_tokens
  where token = _token and user_id = auth.uid();
end;
$$;

grant execute on function public.upsert_device_token(text, text) to authenticated;
grant execute on function public.delete_device_token(text)        to authenticated;
