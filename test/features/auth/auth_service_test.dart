import 'package:flutter_test/flutter_test.dart';
import 'package:multiapp/features/auth/data/auth_service.dart';

void main() {
  group('AuthService im Gastmodus (ohne Supabase)', () {
    // Ohne SUPABASE_URL/-KEY im Environment ist kein Server konfiguriert.
    final service = AuthService.resolve();

    test('ist nicht konfiguriert', () {
      expect(service.isConfigured, isFalse);
      expect(service.currentSession, isNull);
      expect(service.currentUser, isNull);
    });

    test('Anmeldung meldet den Gastmodus statt zu crashen', () async {
      final result = await service.signIn(
        email: 'a@b.de',
        password: 'geheim123',
      );
      expect(result, isA<AuthFailure>());
      expect((result as AuthFailure).message, contains('Gastmodus'));
    });

    test('Registrierung meldet den Gastmodus', () async {
      final result = await service.signUp(
        email: 'a@b.de',
        password: 'geheim123',
        displayName: 'Test',
      );
      expect(result, isA<AuthFailure>());
    });

    test('onAuthStateChange ist ein leerer Strom', () async {
      expect(await service.onAuthStateChange.isEmpty, isTrue);
    });

    test('signOut wirft nicht', () async {
      await service.signOut();
    });
  });
}
