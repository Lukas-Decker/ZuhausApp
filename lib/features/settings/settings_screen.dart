import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_info.dart';
import '../../core/diagnostics/debug_log.dart';
import '../../core/notifications/notification_providers.dart';
import '../../core/providers.dart';
import '../../core/security/app_lock.dart';
import '../../core/settings/app_settings.dart';
import '../../core/widgets/scope_switcher_sheet.dart';
import '../auth/auth_providers.dart';
import '../auth/data/auth_service.dart';
import '../auth/ui/auth_screen.dart';
import '../household/household_actions.dart';
import '../household/ui/household_screen.dart';
import '../privacy/privacy_providers.dart';
import '../privacy/ui/audit_log_screen.dart';
import '../privacy/ui/privacy_info_screen.dart';
import '../push/push_providers.dart';
import '../sync/sync_providers.dart';
import '../update/ui/update_sheet.dart';
import '../update/update_providers.dart';
import 'debug_log_screen.dart';
import 'notification_debug_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(identityProvider);
    final households = ref.watch(householdsProvider);
    final scope = ref.watch(activeScopeProvider);
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        // Ohne diesen Abstand sitzt der letzte Eintrag unter der Systemleiste
        // (Gestenbalken bzw. Zurueck-Knoepfe) und bleibt halb verdeckt.
        padding: EdgeInsets.only(bottom: MediaQuery.viewPaddingOf(context).bottom),
        children: [
          const _SectionHeader('Diagnose (Testphase)'),
          const _DebugLogTile(),
          ListTile(
            leading: const Icon(Icons.troubleshoot_rounded),
            title: const Text('Erinnerungen prüfen'),
            subtitle: const Text(
              'Testmeldung senden und geplante Erinnerungen ansehen.',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => NotificationDebugScreen.show(context),
          ),
          const Divider(),
          const _SectionHeader('Konto'),
          ListTile(
            leading: CircleAvatar(child: Text(identity.initials)),
            title: Text(identity.displayName),
            subtitle: Text(
              identity.isLinkedToAccount
                  ? 'Mit Konto verbunden'
                  : 'Lokal auf diesem Gerät, noch kein Konto',
            ),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _editDisplayName(context, ref, identity.displayName),
          ),
          if (identity.isLinkedToAccount) ...[
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Abmelden'),
              subtitle: const Text(
                'Lokale Daten bleiben auf diesem Gerät erhalten.',
              ),
              onTap: () => _signOut(context, ref),
            ),
            const _SyncTile(),
          ] else
            ListTile(
              leading: const Icon(Icons.login_rounded),
              title: const Text('Anmelden oder Konto erstellen'),
              subtitle: Text(
                ref.watch(authConfiguredProvider)
                    ? 'Für Familie und Synchronisierung zwischen Geräten.'
                    : 'In dieser Version nicht verfügbar (Gastmodus).',
              ),
              onTap: () => AuthScreen.show(context),
            ),
          const Divider(),
          const _SectionHeader('Kontext'),
          ListTile(
            leading: const Icon(Icons.swap_horiz_rounded),
            title: const Text('Aktiver Kontext'),
            subtitle: Text(scope.isPersonal ? 'Privat' : scope.label),
            onTap: () => ScopeSwitcherSheet.show(context),
          ),
          const Divider(),
          const _SectionHeader('Haushalte'),
          households.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
            error: (error, _) => ListTile(
              leading: const Icon(Icons.error_outline),
              title: Text('Fehler: $error'),
            ),
            data: (list) => list.isEmpty
                ? const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Noch kein Haushalt'),
                    subtitle: Text(
                      'Über den Kontext-Umschalter kannst du einen erstellen '
                      'oder beitreten.',
                    ),
                  )
                : Column(
                    children: [
                      for (final entry in list)
                        ListTile(
                          leading: Icon(entry.role.icon),
                          title: Text(entry.household.name),
                          subtitle: Text(entry.role.label),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => HouseholdScreen.show(
                            context,
                            entry.household.id,
                          ),
                        ),
                    ],
                  ),
          ),
          if (ref.watch(currentUserProvider) != null)
            ListTile(
              leading: const Icon(Icons.group_add_rounded),
              title: const Text('Haushalt beitreten'),
              subtitle: const Text('Mit Einladungscode'),
              onTap: () => showJoinHouseholdDialog(context, ref),
            ),
          const Divider(),
          const _SectionHeader('Erinnerungen'),
          const _NotificationPermissionTile(),
          const _WakeScreenTile(),
          const _WakeTimeoutTile(),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up_rounded),
            value: settings.reminderSoundEnabled,
            onChanged: ref
                .read(appSettingsProvider.notifier)
                .setReminderSoundEnabled,
            title: const Text('Ton'),
            subtitle: const Text('Erinnerungen mit Klang ankündigen.'),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.vibration_rounded),
            value: settings.reminderVibrationEnabled,
            onChanged: ref
                .read(appSettingsProvider.notifier)
                .setReminderVibrationEnabled,
            title: const Text('Vibration'),
            subtitle: Text(
              settings.wakeScreenEnabled
                  ? 'Im Wecker-Modus mit kräftigem, langem Muster.'
                  : 'Erinnerungen spürbar machen.',
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.medication_rounded),
            value: settings.medicationRemindersEnabled,
            onChanged: ref
                .read(appSettingsProvider.notifier)
                .setMedicationRemindersEnabled,
            title: const Text('Medikamenten-Erinnerungen'),
            subtitle: const Text(
              'Pro Plan zusätzlich einzeln abschaltbar.',
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.pets_rounded),
            value: settings.petRemindersEnabled,
            onChanged: ref
                .read(appSettingsProvider.notifier)
                .setPetRemindersEnabled,
            title: const Text('Tier-Erinnerungen'),
            subtitle: const Text('Fütterung, Arznei und Termine.'),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.event_busy_rounded),
            value: settings.expiryWarningsEnabled,
            onChanged: ref
                .read(appSettingsProvider.notifier)
                .setExpiryWarningsEnabled,
            title: const Text('Ablaufwarnungen'),
            subtitle: Text(
              'Tägliche Sammelmeldung, ${settings.expiryWarningDays} Tage '
              'vorher. Pro Artikel zusätzlich abschaltbar.',
            ),
          ),
          const Divider(),
          const _SectionHeader('Familie'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            value: settings.familyPushEnabled,
            onChanged: ref
                .read(appSettingsProvider.notifier)
                .setFamilyPushEnabled,
            title: const Text('Familien-Benachrichtigungen'),
            subtitle: const Text(
              'Ereignisse aus dem Haushalt auf diesem Gerät anzeigen.',
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.escalator_warning_rounded),
            value: settings.medEscalationEnabled,
            onChanged: ref
                .read(appSettingsProvider.notifier)
                .setMedEscalationEnabled,
            title: const Text('Pillen-Eskalation'),
            subtitle: const Text(
              'Nicht bestätigte Einnahmen (geteilt/mit Betreuer) an die '
              'Familie melden.',
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.pets_outlined),
            value: settings.petOverdueEnabled,
            onChanged: ref
                .read(appSettingsProvider.notifier)
                .setPetOverdueEnabled,
            title: const Text('Fütterung überfällig'),
            subtitle: const Text(
              'Meldet abends offene Fütterungen an den Haushalt.',
            ),
          ),
          const Divider(),
          const _SectionHeader('Sicherheit'),
          const _AppLockTile(),
          const Divider(),
          const _SectionHeader('Datenschutz'),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('Produktdaten von Open Food Facts'),
            subtitle: Text(
              switch (settings.openFoodFactsConsent) {
                true =>
                  'Erlaubt. Beim Scan wird nur der Barcode übertragen.',
                false => 'Abgelehnt. Produkte werden selbst angelegt.',
                null => 'Noch nicht entschieden.',
              },
            ),
            trailing: Switch(
              value: settings.openFoodFactsConsent ?? false,
              onChanged: ref
                  .read(appSettingsProvider.notifier)
                  .setOpenFoodFactsConsent,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.health_and_safety_outlined),
            title: const Text('Gesundheitsdaten (Pillen-Tracker)'),
            subtitle: Text(
              switch (settings.healthDataConsent) {
                true => 'Einwilligung erteilt (DSGVO Art. 9).',
                false || null => 'Noch nicht eingewilligt.',
              },
            ),
            trailing: Switch(
              value: settings.healthDataConsent ?? false,
              onChanged: (value) {
                ref
                    .read(appSettingsProvider.notifier)
                    .setHealthDataConsent(value);
                _logConsent(ref, 'Gesundheitsdaten', value);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Datenschutz-Info'),
            subtitle: Text('Wie $appName mit deinen Daten umgeht.'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => PrivacyInfoScreen.show(context),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Meine Daten exportieren'),
            subtitle: const Text('Alle lokalen Daten als JSON-Datei.'),
            onTap: () => _exportData(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.history_rounded),
            title: const Text('Aktivitätsprotokoll'),
            subtitle: const Text('Datenschutzrelevante Aktionen auf diesem Gerät.'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => AuditLogScreen.show(context),
          ),
          ListTile(
            leading: const Icon(Icons.auto_delete_outlined),
            title: const Text('Aufbewahrung'),
            subtitle: Text(
              settings.retentionDays == 0
                  ? 'Gelöschtes wird nicht automatisch entfernt.'
                  : 'Gelöschtes und alte Protokolle nach '
                        '${settings.retentionDays} Tagen entfernen.',
            ),
            onTap: () => _editRetention(context, ref, settings.retentionDays),
          ),
          if (identity.isLinkedToAccount)
            ListTile(
              leading: Icon(
                Icons.no_accounts_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Konto und Daten löschen',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              subtitle: const Text('Endgültig, kann nicht rückgängig gemacht werden.'),
              onTap: () => _deleteAccount(context, ref),
            ),
          const Divider(),
          const _SectionHeader('Updates'),
          const _UpdateTile(),
          SwitchListTile(
            secondary: const Icon(Icons.update_rounded),
            value: settings.updateCheckEnabled,
            onChanged: ref
                .read(appSettingsProvider.notifier)
                .setUpdateCheckEnabled,
            title: const Text('Automatisch nach Updates suchen'),
            subtitle: const Text('Beim Start und danach alle sechs Stunden.'),
          ),
          const Divider(),
          const _SectionHeader('Über'),
          const _AboutTile(),
        ],
      ),
    );
  }

  void _logConsent(WidgetRef ref, String what, bool granted) {
    ref
        .read(auditServiceProvider)
        .log(
          scope: ref.read(activeScopeProvider),
          entityType: 'consent',
          action: granted ? 'accept' : 'update',
          summary: '$what: ${granted ? 'erteilt' : 'widerrufen'}',
          actorName: ref.read(identityProvider).displayName,
        );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(dataExportServiceProvider)
          .exportAndShare(appVersion: appVersion);
      await ref
          .read(auditServiceProvider)
          .log(
            scope: ref.read(activeScopeProvider),
            entityType: 'data',
            action: 'export',
            summary: 'Datenexport erstellt',
            actorName: ref.read(identityProvider).displayName,
          );
    } catch (error) {
      if (!context.mounted) return;
      messenger.showSnackBar(_errorSnackBar(context, 'Export fehlgeschlagen: $error'));
    }
  }

  /// Fehler-Toasts in Rot, damit sie sich von den normalen abheben.
  SnackBar _errorSnackBar(BuildContext context, String message) {
    final scheme = Theme.of(context).colorScheme;
    return SnackBar(
      backgroundColor: scheme.error,
      content: Text(message, style: TextStyle(color: scheme.onError)),
    );
  }

  Future<void> _editRetention(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) async {
    const options = {
      0: 'Nie automatisch löschen',
      30: 'Nach 30 Tagen',
      90: 'Nach 90 Tagen',
      180: 'Nach 180 Tagen',
      365: 'Nach 365 Tagen',
    };
    final choice = await showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Aufbewahrung'),
        children: [
          for (final entry in options.entries)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(entry.key),
              child: Row(
                children: [
                  Icon(
                    entry.key == current
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(entry.value),
                ],
              ),
            ),
        ],
      ),
    );
    if (choice == null) return;
    await ref.read(appSettingsProvider.notifier).setRetentionDays(choice);
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konto wirklich löschen?'),
        content: const Text(
          'Dein Konto und alle Serverdaten werden endgültig gelöscht. Die '
          'Daten auf diesem Gerät werden ebenfalls entfernt. Dieser Schritt '
          'kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Endgültig löschen'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await ref.read(authServiceProvider).deleteAccount();
    if (!context.mounted) return;

    switch (result) {
      case DeleteAccountSuccess():
        await ref.read(databaseProvider).wipeAllData();
        await ref.read(authServiceProvider).signOut();
        if (!context.mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Konto und Daten wurden gelöscht.')),
        );
      case DeleteAccountNeedsTransfer(:final households):
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Eigentümerschaft übergeben'),
            content: Text(
              'Du bist noch Eigentümer von: ${households.join(', ')}.\n\n'
              'Übergib die Eigentümerschaft oder löse die Haushalte auf, '
              'dann kannst du dein Konto löschen.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Verstanden'),
              ),
            ],
          ),
        );
      case DeleteAccountFailure(:final message):
        messenger.showSnackBar(
          _errorSnackBar(context, 'Löschung fehlgeschlagen: $message'),
        );
    }
  }

  Future<void> _editDisplayName(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Anzeigename'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    controller.dispose();

    final name = result?.trim() ?? '';
    if (name.isEmpty) return;
    await ref.read(identityProvider.notifier).setDisplayName(name);
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Abmelden?'),
        content: const Text(
          'Du wirst vom Konto abgemeldet. Die Daten auf diesem Gerät bleiben '
          'erhalten und stehen im Gastmodus weiter zur Verfügung.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Abmelden'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    // Vor dem Abmelden den Push-Token dieses Geraets entfernen (nur Android).
    await ref.read(fcmServiceProvider).deleteToken();
    await ref.read(authServiceProvider).signOut();
  }
}

/// Zeigt den Synchronisierungs-Status und erlaubt manuelles Abgleichen.
class _SyncTile extends ConsumerWidget {
  const _SyncTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncControllerProvider);

    final (icon, text) = switch (status.phase) {
      SyncPhase.syncing => (Icons.sync_rounded, 'Wird synchronisiert ...'),
      SyncPhase.error => (
        Icons.sync_problem_rounded,
        status.error == null
            ? 'Letzter Abgleich fehlgeschlagen'
            : 'Fehlgeschlagen: ${status.error}',
      ),
      SyncPhase.offline => (Icons.cloud_off_rounded, 'Kein Konto'),
      SyncPhase.idle => (
        Icons.cloud_done_rounded,
        status.lastSyncedAt == null
            ? 'Bereit'
            : 'Zuletzt ${DateFormat('HH:mm', 'de').format(status.lastSyncedAt!)}',
      ),
    };

    return ListTile(
      isThreeLine: status.phase == SyncPhase.error,
      leading: status.isSyncing
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      title: const Text('Synchronisierung'),
      subtitle: Text(text, maxLines: 4, overflow: TextOverflow.ellipsis),
      trailing: IconButton(
        tooltip: 'Jetzt abgleichen',
        onPressed: status.isSyncing
            ? null
            : () => ref.read(syncControllerProvider.notifier).syncNow(),
        icon: const Icon(Icons.refresh_rounded),
      ),
    );
  }
}

/// Wie lange eine Wecker-Erinnerung durchhält, bevor sie von selbst aufhört.
class _WakeTimeoutTile extends ConsumerWidget {
  const _WakeTimeoutTile();

  // Kurze Beschriftungen: der Auswahlknopf sitzt am rechten Rand und darf
  // auf schmalen Telefonen nicht überlaufen. Werte in Sekunden.
  static const _choices = <int, String>{
    30: '30 Sek.',
    60: '1 Min.',
    120: '2 Min.',
    300: '5 Min.',
    600: '10 Min.',
    0: 'Nie',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final active = settings.wakeScreenEnabled;

    return ListTile(
      enabled: active,
      leading: const Icon(Icons.timer_outlined),
      title: const Text('Wecker hört auf nach'),
      subtitle: Text(
        active
            ? 'Meldung verschwindet und der Vollbild-Schirm schließt sich.'
            : 'Nur im Wecker-Modus.',
      ),
      trailing: DropdownButton<int>(
        // Ein alter, in Minuten gespeicherter Wert kann von der Liste
        // abweichen; dann faellt die Anzeige auf 2 Minuten zurueck.
        value: _choices.containsKey(settings.wakeTimeoutSeconds)
            ? settings.wakeTimeoutSeconds
            : 120,
        onChanged: active
            ? (value) {
                if (value == null) return;
                ref
                    .read(appSettingsProvider.notifier)
                    .setWakeTimeoutSeconds(value);
              }
            : null,
        items: [
          for (final entry in _choices.entries)
            DropdownMenuItem(value: entry.key, child: Text(entry.value)),
        ],
      ),
      isThreeLine: false,
    );
  }
}

/// Name, Version und Prozessorart des Geräts.
///
/// Die Prozessorart steht hier, weil beim Weitergeben oder beim Installieren
/// von Hand die passende der drei APKs gewählt werden muss.
class _AboutTile extends ConsumerWidget {
  const _AboutTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final abi = ref.watch(deviceAbiProvider).value;
    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: const Text(appName),
      subtitle: Text(
        abi == null ? 'Version $appVersion' : 'Version $appVersion  -  $abi',
      ),
    );
  }
}

/// Zustand des Update-Kanals, mit Knopf zum Nachsehen.
class _UpdateTile extends ConsumerWidget {
  const _UpdateTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(updateControllerProvider);
    final controller = ref.read(updateControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    if (!controller.isSupported) {
      return const ListTile(
        leading: Icon(Icons.cloud_off_rounded),
        title: Text('Updates'),
        subtitle: Text('Für diese Plattform ist kein Kanal eingerichtet.'),
      );
    }

    final checking = status.phase == UpdatePhase.checking;
    final latest = status.manifest?.latest;

    final (icon, text) = switch (status.phase) {
      UpdatePhase.checking => (Icons.sync_rounded, 'Wird geprüft ...'),
      UpdatePhase.downloading => (
        Icons.download_rounded,
        'Wird geladen ...',
      ),
      UpdatePhase.installing => (
        Icons.install_mobile_rounded,
        'Wird installiert ...',
      ),
      UpdatePhase.failed => (
        Icons.error_outline_rounded,
        status.error ?? 'Prüfung fehlgeschlagen',
      ),
      UpdatePhase.idle when status.hasUpdate => (
        Icons.system_update_rounded,
        'Version $latest steht bereit',
      ),
      UpdatePhase.idle => (
        Icons.check_circle_outline_rounded,
        status.lastCheckedAt == null
            ? 'Noch nicht geprüft'
            : 'Aktuell (zuletzt geprüft um '
                  '${DateFormat('HH:mm', 'de').format(status.lastCheckedAt!)})',
      ),
    };

    return ListTile(
      isThreeLine: status.phase == UpdatePhase.failed,
      leading: checking
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              icon,
              color: status.phase == UpdatePhase.failed
                  ? scheme.error
                  : status.hasUpdate
                  ? scheme.primary
                  : null,
            ),
      title: const Text('Version prüfen'),
      subtitle: Text(text, maxLines: 4, overflow: TextOverflow.ellipsis),
      trailing: IconButton(
        tooltip: 'Jetzt nachsehen',
        onPressed: checking ? null : controller.check,
        icon: const Icon(Icons.refresh_rounded),
      ),
      onTap: status.hasUpdate
          ? () => showUpdateSheet(
              context,
              mandatory: status.availability.isRequired,
            )
          : null,
    );
  }
}

/// Einstieg ins Fehlerprotokoll, mit Anzahl der bisherigen Fehler.
class _DebugLogTile extends StatelessWidget {
  const _DebugLogTile();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return StreamBuilder<void>(
      stream: DebugLog.instance.changes,
      builder: (context, _) {
        final errors = DebugLog.instance.errorCount;
        final total = DebugLog.instance.entries.length;
        return ListTile(
          leading: Icon(
            errors > 0 ? Icons.bug_report_rounded : Icons.bug_report_outlined,
            color: errors > 0 ? scheme.error : null,
          ),
          title: const Text('Protokoll'),
          subtitle: Text(
            errors > 0
                ? '$errors Fehler unter $total Einträgen'
                : '$total Einträge, keine Fehler',
          ),
          trailing: errors > 0
              ? Chip(
                  label: Text('$errors'),
                  backgroundColor: scheme.errorContainer,
                  labelStyle: TextStyle(color: scheme.onErrorContainer),
                )
              : const Icon(Icons.chevron_right_rounded),
          onTap: () => DebugLogScreen.show(context),
        );
      },
    );
  }
}

/// Schalter fuer den Wecker-Modus, samt echtem Freigabe-Status.
///
/// Ab Android 14 nuetzt der Schalter allein nichts: ohne die Sonderfreigabe
/// "Vollbild-Benachrichtigungen" bleibt der Bildschirm dunkel. Deshalb wird der
/// Stand hier angezeigt und laesst sich direkt nachholen.
class _WakeScreenTile extends ConsumerWidget {
  const _WakeScreenTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(
      appSettingsProvider.select((s) => s.wakeScreenEnabled),
    );
    final permissions = ref.watch(notificationPermissionsProvider);
    final allowed = permissions.value?.fullScreenAllowed ?? true;
    final dndAllowed = permissions.value?.dndBypassAllowed ?? true;

    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.alarm_on_rounded),
          value: enabled,
          onChanged: (value) async {
            if (value) {
              await ref
                  .read(notificationServiceProvider)
                  .requestFullScreenIntentPermission();
            }
            await ref
                .read(appSettingsProvider.notifier)
                .setWakeScreenEnabled(value);
            ref.invalidate(notificationPermissionsProvider);
          },
          title: const Text('Wie ein Wecker'),
          subtitle: const Text(
            'Weckt den Bildschirm und zeigt die Erinnerung über dem '
            'Sperrbildschirm.',
          ),
          isThreeLine: true,
        ),
        // Nur zeigen, wenn der Schalter an ist, die Freigabe aber fehlt.
        if (enabled && !allowed)
          _PermissionHint(
            text:
                'Android erlaubt das Aufwecken noch nicht. Ohne diese '
                'Freigabe kommt die Meldung, der Bildschirm bleibt aber aus.',
            onGrant: () async {
              await ref
                  .read(notificationServiceProvider)
                  .requestFullScreenIntentPermission();
              ref.invalidate(notificationPermissionsProvider);
            },
          ),
        if (enabled && !dndAllowed)
          _PermissionHint(
            text:
                'Steht das Telefon auf "Bitte nicht stören", bleibt der '
                'Wecker still. Mit dieser Freigabe gilt er als Ausnahme.',
            onGrant: () async {
              await ref.read(notificationServiceProvider).openDndAccessSettings();
            },
          ),
      ],
    );
  }
}

/// Roter Kasten mit Hinweis und Knopf, wenn eine Systemfreigabe fehlt.
class _PermissionHint extends StatelessWidget {
  const _PermissionHint({required this.text, required this.onGrant});

  final String text;
  final Future<void> Function() onGrant;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(onPressed: onGrant, child: const Text('Erlauben')),
        ],
      ),
    );
  }
}

/// Zeigt, ob die Systemrechte fuer Erinnerungen vorliegen, und holt sie nach.
///
/// Ohne die Benachrichtigungsberechtigung kommt gar nichts an; ohne "Alarme &
/// Erinnerungen" (Android 12+) kommen zeitgenaue Erinnerungen nicht puenktlich.
class _NotificationPermissionTile extends ConsumerWidget {
  const _NotificationPermissionTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(notificationPermissionsProvider);
    final scheme = Theme.of(context).colorScheme;

    return status.when(
      loading: () => const ListTile(
        leading: Icon(Icons.notifications_outlined),
        title: Text('Berechtigungen'),
        subtitle: Text('Wird geprüft ...'),
      ),
      error: (error, _) => ListTile(
        leading: const Icon(Icons.notifications_outlined),
        title: const Text('Berechtigungen'),
        subtitle: Text('$error'),
      ),
      data: (data) {
        final allOk = data.notificationsAllowed && data.exactAlarmsAllowed;
        if (allOk) {
          return ListTile(
            leading: Icon(Icons.notifications_active_rounded, color: scheme.primary),
            title: const Text('Berechtigungen erteilt'),
            subtitle: const Text('Erinnerungen dürfen angezeigt werden.'),
          );
        }
        final missing = [
          if (!data.notificationsAllowed) 'Benachrichtigungen',
          if (!data.exactAlarmsAllowed) 'Alarme & Erinnerungen',
        ].join(' und ');
        return ListTile(
          leading: Icon(Icons.notifications_off_rounded, color: scheme.error),
          title: Text(
            'Berechtigung fehlt',
            style: TextStyle(color: scheme.error),
          ),
          subtitle: Text(
            '$missing nicht erlaubt. Ohne diese Rechte kommen keine '
            'Erinnerungen an.',
          ),
          isThreeLine: true,
          trailing: FilledButton(
            onPressed: () async {
              final service = ref.read(notificationServiceProvider);
              if (!data.notificationsAllowed) {
                await service.requestPermission();
              }
              if (!data.exactAlarmsAllowed) {
                await service.requestExactAlarms();
              }
              ref.invalidate(notificationPermissionsProvider);
            },
            child: const Text('Erlauben'),
          ),
        );
      },
    );
  }
}

/// Schalter fuer das biometrische App-Schloss.
///
/// Wird nur aktiv, wenn das Geraet eine Nutzer-Verifikation anbietet
/// (Windows Hello am Desktop, Fingerabdruck/Gesicht auf Android). Auf
/// Plattformen ohne Unterstuetzung bleibt der Schalter deaktiviert.
class _AppLockTile extends ConsumerWidget {
  const _AppLockTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(
      appSettingsProvider.select((s) => s.appLockEnabled),
    );
    final supported = ref.watch(appLockSupportedProvider);
    final isSupported = supported.value ?? false;

    return SwitchListTile(
      secondary: const Icon(Icons.lock_rounded),
      value: enabled && isSupported,
      onChanged: isSupported
          ? (value) async {
              // Vor dem Aktivieren einmal verifizieren, damit niemand ein
              // Schloss setzt, das er selbst nicht oeffnen kann.
              if (value) {
                final ok = await ref.read(appLockProvider).authenticate();
                if (!ok) return;
              }
              await ref
                  .read(appSettingsProvider.notifier)
                  .setAppLockEnabled(value);
            }
          : null,
      title: const Text('App-Schloss'),
      subtitle: Text(
        switch (supported) {
          AsyncData(value: false) =>
            'Auf diesem Gerät nicht verfügbar (keine Biometrie/PIN).',
          AsyncLoading() => 'Wird geprüft ...',
          _ =>
            'Beim Öffnen per Windows Hello bzw. Fingerabdruck/Gesicht '
                'entsperren.',
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
