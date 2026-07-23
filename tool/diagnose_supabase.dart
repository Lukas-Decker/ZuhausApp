// Headless-Diagnose gegen das echte Supabase-Projekt.
//
// Liest env.json, testet Registrierung/Login und die Haushalts-RPCs.
// Aufruf:  dart run tool/diagnose_supabase.dart
//
// Legt einen Wegwerf-Testnutzer an (test+<zufall>@multiapp-test.invalid).
import 'dart:convert';
import 'dart:io';

import 'package:supabase/supabase.dart';

Future<void> main() async {
  final env = jsonDecode(File('env.json').readAsStringSync()) as Map;
  var url = (env['SUPABASE_URL'] as String).trim();
  final uri = Uri.parse(url);
  url = '${uri.scheme}://${uri.host}';
  final key =
      (env['SUPABASE_ANON_KEY'] ?? env['SUPABASE_PUBLISHABLE_KEY']) as String;

  print('URL: $url');
  print('Key-Praefix: ${key.substring(0, 14)}...');

  final client = SupabaseClient(url, key);
  final rnd = DateTime.now().millisecondsSinceEpoch;
  final email = 'diag.$rnd@example.com';
  const password = 'DiagTest12345!';

  // 1) Registrierung
  print('\n== 1) Registrierung ==');
  AuthResponse signUp;
  try {
    signUp = await client.auth.signUp(email: email, password: password);
    print('signUp ok. session != null: ${signUp.session != null}');
    print('user.emailConfirmedAt: ${signUp.user?.emailConfirmedAt}');
    if (signUp.session == null) {
      print(
        '=> E-Mail-Bestaetigung ist AKTIV. Ohne Bestaetigung gibt es keine '
        'Session; Login schlaegt bis zur Bestaetigung mit '
        '"Email not confirmed" fehl.',
      );
    } else {
      print('=> E-Mail-Bestaetigung ist AUS. Login sollte sofort gehen.');
    }
  } catch (e) {
    print('signUp FEHLER: $e');
    exit(1);
  }

  // 2) Login-Versuch
  print('\n== 2) Login ==');
  try {
    final signIn = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    print('signIn ok. session != null: ${signIn.session != null}');
  } catch (e) {
    print('signIn FEHLER: $e');
  }

  // 3) RPC-Test (nur sinnvoll mit Session)
  print('\n== 3) RPC create_household + fetch ==');
  if (client.auth.currentSession == null) {
    print('Keine Session -> RPC-Test uebersprungen (E-Mail-Bestaetigung aktiv).');
  } else {
    try {
      final id = await client.rpc(
        'create_household',
        params: {'_name': 'Diagnose', '_display_name': 'Diag'},
      );
      print('create_household ok, id: $id');
      final rows = await client
          .from('household_members')
          .select('household_id, role')
          .eq('user_id', client.auth.currentUser!.id);
      print('Mitgliedschaften: ${(rows as List).length}');
      final hh = await client
          .from('households')
          .select('id, name')
          .inFilter('id', [id]);
      print('Haushalte sichtbar: ${(hh as List).length} -> $hh');
    } catch (e) {
      print('RPC/Fetch FEHLER: $e');
    }
  }

  print('\nFertig. (Testnutzer $email bleibt unbestaetigt im Projekt.)');
  await client.dispose();
  exit(0);
}
