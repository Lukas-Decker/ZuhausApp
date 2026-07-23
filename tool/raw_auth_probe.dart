// Roher HTTP-Test gegen den Supabase-Auth-Endpunkt, ganz ohne Supabase-Client.
// Zeigt, ob der Schluessel serverseitig akzeptiert wird.
//   dart run tool/raw_auth_probe.dart
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final env = jsonDecode(File('env.json').readAsStringSync()) as Map;
  final u = Uri.parse((env['SUPABASE_URL'] as String).trim());
  final base = '${u.scheme}://${u.host}';
  final key =
      (env['SUPABASE_ANON_KEY'] ?? env['SUPABASE_PUBLISHABLE_KEY']) as String;

  print('Base: $base');
  print('Key-Format: ${key.startsWith("sb_") ? "neu (sb_...)" : key.startsWith("ey") ? "JWT (anon)" : "unbekannt"}');

  final email = 'diag.${DateTime.now().millisecondsSinceEpoch}@example.com';
  final client = HttpClient();

  Future<void> post(String path, Map<String, dynamic> body) async {
    final req = await client.postUrl(Uri.parse('$base$path'));
    req.headers.set('apikey', key);
    req.headers.set('Authorization', 'Bearer $key');
    req.headers.contentType = ContentType.json;
    req.add(utf8.encode(jsonEncode(body)));
    final res = await req.close();
    final text = await res.transform(utf8.decoder).join();
    print('\nPOST $path -> HTTP ${res.statusCode}');
    try {
      final j = jsonDecode(text);
      if (j is Map) {
        final masked = <String, dynamic>{};
        j.forEach((k, v) {
          if (k.toString().contains('token') || k == 'session') {
            masked[k] = '[verborgen]';
          } else {
            masked[k] = v;
          }
        });
        print(const JsonEncoder.withIndent('  ').convert(masked));
      } else {
        print(text);
      }
    } catch (_) {
      print(text.length > 500 ? '${text.substring(0, 500)}...' : text);
    }
  }

  // 1) Health-Check des Auth-Servers
  try {
    final req = await client.getUrl(Uri.parse('$base/auth/v1/health'));
    req.headers.set('apikey', key);
    final res = await req.close();
    final text = await res.transform(utf8.decoder).join();
    print('\nGET /auth/v1/health -> HTTP ${res.statusCode}: $text');
  } catch (e) {
    print('health FEHLER: $e');
  }

  // 2) Registrierung
  await post('/auth/v1/signup', {'email': email, 'password': 'DiagTest12345!'});

  // 3) Login-Versuch (Passwort-Grant)
  await post('/auth/v1/token?grant_type=password', {
    'email': email,
    'password': 'DiagTest12345!',
  });

  client.close();
  print('\nFertig.');
}
