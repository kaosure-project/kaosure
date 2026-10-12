import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../common/step_actions.dart';
import '../../common/step_header.dart';
import 'document_upload_card.dart';

class BusinessDocumentStep extends StatelessWidget {
  const BusinessDocumentStep({
    super.key,
    required this.uploaded,
    required this.uploading,
    required this.fileName,
    required this.onPick,
    required this.onBack,
    required this.onContinue,
  });

  final bool uploaded;
  final bool uploading;
  final String? fileName;
  final VoidCallback onPick;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepHeader(title: l10n.businessRegDocumentHeading,
            description: l10n.businessRegDocumentDescription),
        DocumentUploadCard(
          uploaded: uploaded,
          uploading: uploading,
          fileName: fileName,
          onPick: onPick,
        ),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.businessRegDocumentRequirements,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant))),
        ]),
        StepActions(
          primaryLabel: l10n.businessRegContinue,
          onPrimary: uploaded ? onContinue : null,
          onBack: onBack,
          busy: uploading,
        ),
      ],
    );
  }
}
