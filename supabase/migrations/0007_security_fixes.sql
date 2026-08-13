-- MultiApp v0.25.4: Sicherheitskorrekturen aus der OWASP-/IDOR-Pruefung.
--
-- Behebt zwei Befunde aus docs/sicherheitspruefung-owasp-idor.md:
--
--   F1 (push_record): Beim Aktualisieren eines vorhandenen Datensatzes wurde
--      nur der vom Client MITGESCHICKTE Bereich geprueft, nie der gespeicherte.
--      Wer die id eines fremden Datensatzes kannte (z.B. ein ehemaliges
--      Haushaltsmitglied aus seiner lokalen Kopie), konnte ihn mit einem
--      eigenen Scope im Aufruf ueberschreiben oder als geloescht markieren.
--
--   F3 (upsert_device_token): Ein bereits vergebener FCM-Token wurde bei
--      Konflikt stillschweigend auf das aufrufende Konto umgebunden. Wer einen
--      fremden Token kannte, konnte Pushes auf ein fremdes Geraet umleiten.
--
--   F6 (push_record): Der JSON-Datenblock wurde ueberhaupt nicht geprueft.
--      Die Empfaenger uebernehmen daraus aber ALLE Felder in ihre lokale
--      Tabelle, auch id, scope_kind und scope_id. Ein Haushaltsmitglied konnte
--      so einen Datensatz in den privaten Bereich der anderen Mitglieder
--      einschleusen. Zusaetzlich sind jetzt nur noch bekannte Tabellennamen
--      erlaubt.
--
-- Beides sind reine Serveraenderungen, der Client bleibt unveraendert.
-- Einmal im Supabase SQL Editor ausfuehren (idempotent, gefahrlos wiederholbar).

-- =========================================================================
-- F1: push_record haerten
-- =========================================================================
--
-- Neu sind die Schritte 2 und 3. Der Rest der Funktion ist unveraendert:
-- Last-Write-Wins fuer normale Felder, additive Zaehler-Deltas.

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
  -- 1. Darf der Aufrufer im angegebenen Bereich ueberhaupt schreiben?
  if not public.can_access_scope(_scope_kind, _scope_id) then
    raise exception 'Kein Zugriff auf diesen Bereich';
  end if;

  -- 2. Nur bekannte Tabellen. Sonst liesse sich sync_records mit beliebigen
  --    Namen vollschreiben. Die Liste entspricht SyncEngine.tables in
  --    lib/features/sync/sync_engine.dart und muss mitgepflegt werden.
  if _table not in (
    'storage_locations', 'products', 'inventory_items', 'inventory_batches',
    'shopping_lists', 'shopping_items', 'notes', 'note_checklist_items',
    'medication_plans', 'medication_logs', 'pets', 'pet_tasks',
    'pet_task_logs', 'pet_health_entries', 'pet_weight_entries'
  ) then
    raise exception 'Unbekannte Tabelle: %', _table;
  end if;

  -- 3. Der Datenblock muss zu Kennung und Bereich passen (F6).
  --    Die Empfaenger uebernehmen beim Pull ALLE Felder aus _data in ihre
  --    lokale Tabelle (siehe LocalSyncStore.applyRemote), also auch id,
  --    scope_kind und scope_id. Ohne diese Pruefung koennte ein Mitglied einen
  --    Datensatz mit korrekter Spalte, aber abweichendem Inhalt schicken: auf
  --    den anderen Geraeten landet er dann unter fremder Kennung oder im
  --    privaten Bereich des Empfaengers. Fehlende Felder sind in Ordnung,
  --    abweichende nicht.
  if coalesce(_data ->> 'id', _id::text) is distinct from _id::text then
    raise exception 'Datenblock und Kennung passen nicht zusammen';
  end if;
  if coalesce(_data ->> 'scope_kind', _scope_kind) is distinct from _scope_kind
     or coalesce(_data ->> 'scope_id', _scope_id) is distinct from _scope_id then
    raise exception 'Datenblock und Bereich passen nicht zusammen';
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

  -- 4. Bei einem vorhandenen Datensatz zaehlt der GESPEICHERTE Bereich, nicht
  --    der mitgeschickte. Schritt 1 allein liesse sich sonst mit einem eigenen
  --    Scope erfuellen, waehrend das UPDATE unten die fremde Zeile ueber den
  --    Primaerschluessel (table_name, id) trifft.
  if not public.can_access_scope(_existing.scope_kind, _existing.scope_id) then
    raise exception 'Kein Zugriff auf diesen Datensatz';
  end if;

  -- 5. Ein Datensatz bleibt in seinem Bereich. Ein Wechsel waere sonst ein Weg,
  --    fremde Daten in den eigenen Bereich zu ziehen oder eigene Daten in einen
  --    fremden Haushalt zu schieben. Die App verschiebt Datensaetze nicht
  --    zwischen Bereichen; nur lokale Gastdaten werden beim ersten Login
  --    umgeschrieben, und die sind serverseitig noch gar nicht vorhanden
  --    (sie laufen oben in den Insert-Pfad).
  if _existing.scope_kind is distinct from _scope_kind
     or _existing.scope_id is distinct from _scope_id then
    raise exception 'Der Bereich eines Datensatzes kann nicht gewechselt werden';
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

grant execute on function
  public.push_record(text, uuid, text, text, timestamptz, timestamptz, jsonb, jsonb)
  to authenticated;

-- =========================================================================
-- F3: upsert_device_token haerten
-- =========================================================================
--
-- Beim regulaeren Abmelden loescht der Client den Token (delete_device_token)
-- UND laesst Firebase einen neuen ausstellen. Der Normalfall "Geraet wechselt
-- den Nutzer" kollidiert also gar nicht. Eine Kollision heisst entweder:
-- die Abmeldung kam nie durch (offline, Neuinstallation) oder jemand meldet
-- einen fremden Token an. Ersteres loest sich ueber die Veralterung, letzteres
-- wird abgewiesen.

create or replace function public.upsert_device_token(_token text, _platform text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  _uid     uuid := auth.uid();
  _owner   uuid;
  _touched timestamptz;
  -- Ab wann eine fremde Bindung als verwaist gilt und uebernommen werden darf.
  _stale_after constant interval := interval '60 days';
begin
  if _uid is null then
    raise exception 'Nicht angemeldet';
  end if;

  select user_id, updated_at into _owner, _touched
  from public.device_tokens
  where token = _token;

  -- Gehoert der Token einem anderen, noch aktiven Konto: nicht uebernehmen.
  if _owner is not null
     and _owner <> _uid
     and _touched > now() - _stale_after then
    raise exception 'Dieser Geraete-Token gehoert zu einem anderen Konto';
  end if;

  insert into public.device_tokens (token, user_id, platform, updated_at)
  values (_token, _uid, coalesce(nullif(_platform, ''), 'android'), now())
  on conflict (token) do update
    set user_id    = excluded.user_id,
        platform   = excluded.platform,
        updated_at = now();
end;
$$;

grant execute on function public.upsert_device_token(text, text) to authenticated;
