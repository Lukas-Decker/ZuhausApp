import 'package:flutter/material.dart';

import '../../../core/i18n/app_texts.dart';
import '../../../core/widgets/sheet_insets.dart';
import '../domain/medication_schedule.dart';

/// Erklärt, was die Einnahmehinweise bedeuten.
///
/// Ohne [only] stehen alle Hinweise darin (das Fragezeichen im Editor), mit
/// [only] genau einer (Antippen eines Hinweises am Wecker-Schirm).
Future<void> showIntakeHintExplanations(
  BuildContext context, {
  IntakeHint? only,
}) {
  final hints = only == null ? IntakeHint.values : [only];

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + sheetBottomInset(sheetContext),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              only == null
                  ? sheetContext.l10n.medsHintsExplainTitle
                  : only.label(sheetContext.l10n),
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            for (final hint in hints) ...[
              if (only == null) ...[
                Text(
                  hint.label(sheetContext.l10n),
                  style: Theme.of(sheetContext).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
              ],
              Text(
                hint.explanation(sheetContext.l10n),
                style: Theme.of(sheetContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
            ],
            Text(
              sheetContext.l10n.medsHintsDisclaimer,
              style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
