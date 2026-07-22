import 'package:drift/native.dart';
import 'package:multiapp/core/scope/app_scope.dart';
import 'package:multiapp/data/db/app_database.dart';

/// Frische In-Memory-Datenbank für einen Test.
AppDatabase createTestDatabase() => AppDatabase(NativeDatabase.memory());

/// Zwei getrennte Kontexte, um Abschottung zu prüfen.
final personalScope = AppScope.personal('user-1');
final householdScope = AppScope.household('household-1', 'Familie Test');

const testUserId = 'user-1';
