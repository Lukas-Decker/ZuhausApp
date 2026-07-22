import 'package:flutter_test/flutter_test.dart';
import 'package:multiapp/core/identity/local_identity.dart';
import 'package:multiapp/core/scope/app_scope.dart';
import 'package:multiapp/core/widgets/scope_banner.dart';

void main() {
  group('AppScope', () {
    test('key ist stabil und unterscheidet die Kontextarten', () {
      expect(AppScope.personal('u1').key, 'personal:u1');
      expect(AppScope.household('h1', 'Familie').key, 'household:h1');
    });

    test('Gleichheit ignoriert das Label', () {
      expect(
        AppScope.household('h1', 'Familie Mueller'),
        AppScope.household('h1', 'Umbenannt'),
      );
      expect(
        AppScope.personal('u1') == AppScope.household('u1', 'x'),
        isFalse,
      );
    });

    test('tryParse findet nur verfuegbare Kontexte', () {
      final available = [
        AppScope.personal('u1'),
        AppScope.household('h1', 'Familie'),
      ];
      expect(AppScope.tryParse('household:h1', available)?.label, 'Familie');
      expect(AppScope.tryParse('household:weg', available), isNull);
      expect(AppScope.tryParse(null, available), isNull);
    });
  });

  group('scopeActionLabel', () {
    test('nennt das Ziel im Klartext', () {
      expect(
        scopeActionLabel(AppScope.personal('u1')),
        'Hinzufuegen (privat)',
      );
      expect(
        scopeActionLabel(AppScope.household('h1', 'Familie Mueller')),
        'Hinzufuegen zu Familie Mueller',
      );
      expect(
        scopeActionLabel(AppScope.household('h1', 'WG'), verb: 'Speichern'),
        'Speichern zu WG',
      );
    });
  });

  group('LocalIdentity', () {
    test('Initialen aus Vor- und Nachname', () {
      const identity = LocalIdentity(
        userId: 'u1',
        displayName: 'Lukas Mueller',
        isLinkedToAccount: false,
      );
      expect(identity.initials, 'LM');
    });

    test('Initialen bei einem einzelnen Namen', () {
      const identity = LocalIdentity(
        userId: 'u1',
        displayName: 'Ich',
        isLinkedToAccount: false,
      );
      expect(identity.initials, 'I');
    });

    test('Initialen bei leerem Namen', () {
      const identity = LocalIdentity(
        userId: 'u1',
        displayName: '   ',
        isLinkedToAccount: false,
      );
      expect(identity.initials, '?');
    });
  });
}
