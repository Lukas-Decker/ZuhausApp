import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/app_info.dart';
import '../../../core/widgets/sheet_insets.dart';
import '../domain/release_manifest.dart';
import '../update_providers.dart';
import 'changelog_dialog.dart';

/// Zeigt den Update-Hinweis.
///
/// Ein Pflicht-Update kommt als Dialog, der sich nicht wegklicken lässt; alles
/// andere als normales Blatt von unten.
Future<void> showUpdateSheet(
  BuildContext context, {
  required bool mandatory,
}) {
  if (mandatory) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _MandatoryUpdateDialog(),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      // Unten die Systemleiste (Gestenbalken oder Zurueck-Knoepfe) mitrechnen.
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + sheetBottomInset(sheetContext),
      ),
      child: const UpdateSheetBody(mandatory: false),
    ),
  );
}

class _MandatoryUpdateDialog extends StatelessWidget {
  const _MandatoryUpdateDialog();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: const SizedBox(
          width: 420,
          child: UpdateSheetBody(mandatory: true),
        ),
      ),
    );
  }
}

/// Inhalt des Hinweises: Version, Änderungen, Fortschritt und Knöpfe.
class UpdateSheetBody extends ConsumerStatefulWidget {
  const UpdateSheetBody({super.key, required this.mandatory});

  final bool mandatory;

  @override
  ConsumerState<UpdateSheetBody> createState() => _UpdateSheetBodyState();
}

class _UpdateSheetBodyState extends ConsumerState<UpdateSheetBody> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Kommt die App aus der Systemeinstellung zurück, gleich nachsehen ob die
    // Installation jetzt erlaubt ist, statt den Nutzer noch einmal tippen zu
    // lassen.
    _lifecycle = AppLifecycleListener(
      onResume: () =>
          ref.read(updateControllerProvider.notifier).recheckInstallPermission(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mandatory = widget.mandatory;
    final status = ref.watch(updateControllerProvider);
    final controller = ref.read(updateControllerProvider.notifier);
    final manifest = status.manifest;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (manifest == null) return const SizedBox.shrink();

    final asset = status.asset;
    final published = manifest.publishedAt;
    // Nur was seit der installierten Version dazugekommen ist.
    final changes = manifest.changesSince(
      AppVersion.tryParse(appVersion) ?? const AppVersion(0, 0, 0),
    );

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                mandatory
                    ? Icons.warning_amber_rounded
                    : Icons.system_update_rounded,
                color: mandatory ? scheme.error : scheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  mandatory ? 'Update erforderlich' : 'Update verfügbar',
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Version $appVersion  ->  ${manifest.latest}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (asset?.sizeBytes != null || published != null) ...[
            const SizedBox(height: 2),
            Text(
              [
                if (asset?.sizeBytes != null) formatBytes(asset!.sizeBytes!),
                if (published != null)
                  DateFormat('d. MMMM y', 'de').format(published),
              ].join('  -  '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          if (mandatory) ...[
            const SizedBox(height: 12),
            Text(
              'Diese Version wird nicht mehr unterstützt. Bitte aktualisieren, '
              'um weiterzuarbeiten.',
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
            ),
          ],
          if (changes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => showChangelogDialog(context, entries: changes),
                icon: const Icon(Icons.notes_rounded),
                label: Text(
                  changes.length == 1
                      ? 'Änderungen ansehen'
                      : 'Änderungen aus ${changes.length} Versionen ansehen',
                ),
              ),
            ),
          ],
          if (status.needsInstallPermission) ...[
            const SizedBox(height: 16),
            Text(
              'Android muss die Installation aus dieser App noch erlauben. '
              'Der Schalter heißt "Unbekannte Apps installieren".',
              style: theme.textTheme.bodyMedium,
            ),
          ],
          if (status.error != null) ...[
            const SizedBox(height: 16),
            Text(
              status.error!,
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
            ),
          ],
          if (status.phase == UpdatePhase.downloading) ...[
            const SizedBox(height: 20),
            LinearProgressIndicator(value: status.progress),
            const SizedBox(height: 6),
            Text(
              status.total > 0
                  ? '${formatBytes(status.received)} von ${formatBytes(status.total)}'
                  : 'Wird geladen ...',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (status.phase == UpdatePhase.installing) ...[
            const SizedBox(height: 20),
            const LinearProgressIndicator(),
            const SizedBox(height: 6),
            Text(
              Platform.isWindows
                  ? 'Die App wird gleich beendet und aktualisiert neu gestartet.'
                  : 'Installation bestätigen, wenn Android danach fragt.',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!mandatory && !status.phase.isBusy)
                TextButton(
                  onPressed: () async {
                    await controller.skipCurrentVersion();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Später'),
                ),
              const SizedBox(width: 8),
              if (status.needsInstallPermission)
                FilledButton.icon(
                  onPressed: controller.openInstallPermissionSettings,
                  icon: const Icon(Icons.settings_rounded),
                  label: const Text('Installation erlauben'),
                )
              else
                FilledButton.icon(
                  onPressed: status.phase.isBusy
                      ? null
                      : controller.downloadAndInstall,
                  icon: const Icon(Icons.download_rounded),
                  label: Text(
                    status.phase == UpdatePhase.failed
                        ? 'Erneut versuchen'
                        : 'Jetzt aktualisieren',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Byte-Angabe für Menschen, mit deutschem Dezimalkomma.
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
  final mb = bytes / (1024 * 1024);
  return '${mb.toStringAsFixed(1).replaceAll('.', ',')} MB';
}
