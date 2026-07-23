-- MultiApp v0.8.1: fehlende Tabellen-Berechtigungen nachziehen.
--
-- Row Level Security regelt nur, WELCHE Zeilen sichtbar sind. Die Rolle
-- 'authenticated' braucht zusaetzlich das SELECT-Recht auf die Tabellen, sonst
-- schlaegt jede Leseabfrage mit "permission denied ... code 42501" fehl.
--
-- Einmal im Supabase SQL Editor ausfuehren.

grant usage on schema public to authenticated;

grant select on public.households        to authenticated;
grant select on public.household_members to authenticated;
grant select on public.household_invites to authenticated;

grant execute on function public.create_household(text, text)          to authenticated;
grant execute on function public.rename_household(uuid, text)          to authenticated;
grant execute on function public.create_invite(uuid, text, timestamptz, integer) to authenticated;
grant execute on function public.revoke_invite(uuid)                   to authenticated;
grant execute on function public.join_with_code(text, text)            to authenticated;
grant execute on function public.set_member_role(uuid, uuid, text)     to authenticated;
grant execute on function public.remove_member(uuid, uuid)             to authenticated;
grant execute on function public.leave_household(uuid)                 to authenticated;
grant execute on function public.transfer_ownership(uuid, uuid)        to authenticated;
grant execute on function public.delete_household(uuid)                to authenticated;
