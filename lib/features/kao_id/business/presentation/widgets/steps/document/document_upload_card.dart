import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

class DocumentUploadCard extends StatelessWidget {
  const DocumentUploadCard({
    super.key,
    required this.uploaded,
    required this.uploading,
    required this.fileName,
    required this.onPick,
  });

  final bool uploaded;
  final bool uploading;
  final String? fileName;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = uploading
        ? l10n.businessRegDocumentUploading
        : uploaded
            ? l10n.businessRegDocumentUploaded
            : l10n.businessRegDocumentMissing;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: uploaded ? scheme.primaryContainer.withValues(alpha: 0.25) : scheme.surfaceContainerLow,
        border: Border.all(color: uploaded ? scheme.primary : scheme.outlineVariant),
      ),
      child: Column(
        children: [
          if (uploading)
            const SizedBox.square(dimension: 40, child: CircularProgressIndicator(strokeWidth: 3))
          else
            Icon(uploaded ? Icons.verified_outlined : Icons.upload_file_outlined,
                size: 40, color: uploaded ? scheme.primary : scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Semantics(liveRegion: true, child: Text(title,
              textAlign: TextAlign.center, style: theme.textTheme.titleSmall)),
          if (uploaded && fileName != null) ...[
            const SizedBox(height: 4),
            Text(fileName!, textAlign: TextAlign.center, maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: uploading ? null : onPick,
            icon: const Icon(Icons.attach_file),
            label: Text(uploaded ? l10n.businessRegDocumentReplace : l10n.businessRegDocumentChoose),
          ),
        ],
      ),
    );
  }
}
