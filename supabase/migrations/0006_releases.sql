-- MultiApp v0.21: eigener Update-Kanal.
--
-- Die App fragt beim Start ein Manifest ab und laedt bei Bedarf das passende
-- Paket (APK bzw. Windows-ZIP). Beides liegt in einem oeffentlichen
-- Storage-Bucket: lesen darf jeder (auch ohne Konto), hochladen nur der
-- Service-Role-Key vom eigenen Rechner (tool/publish_update.ps1).
--
-- Einmal im Supabase SQL Editor ausfuehren (idempotent).

insert into storage.buckets (id, name, public)
values ('releases', 'releases', true)
on conflict (id) do update set public = true;

-- Oeffentlich lesbar. Der Bucket ist bereits public, die Policy macht das
-- zusaetzlich fuer die normale Storage-API explizit.
drop policy if exists releases_public_read on storage.objects;
create policy releases_public_read on storage.objects
  for select using (bucket_id = 'releases');

-- Kein insert/update/delete fuer anon oder authenticated: Veroeffentlichen
-- geht ausschliesslich mit dem Service-Role-Key, der die RLS umgeht.
drop policy if exists releases_no_write on storage.objects;
