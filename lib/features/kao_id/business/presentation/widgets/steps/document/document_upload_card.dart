import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

class DocumentUploadCard extends StatelessWidget {
  const DocumentUploadCard({
    super.key,
    required this.label,
    required this.uploaded,
    required this.uploading,
    required this.fileName,
    required this.onPick,
    this.onRemove,
  });

  final String label;
  final bool uploaded;
  final bool uploading;
  final String? fileName;
  final VoidCallback? onPick;

  /// Shown only for optional documents that are already attached.
  final VoidCallback? onRemove;

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
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (uploading)
            const SizedBox.square(dimension: 40, child: CircularProgressIndicator(strokeWidth: 3))
          else
            Icon(
              uploaded ? Icons.verified_outlined : Icons.upload_file_outlined,
              size: 40,
              color: uploaded ? scheme.primary : scheme.onSurfaceVariant,
            ),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleSmall),
          ),
          if (uploaded && fileName != null) ...[
            const SizedBox(height: 4),
            Text(
              fileName!,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: uploading ? null : onPick,
                icon: const Icon(Icons.attach_file),
                label: Text(uploaded ? l10n.businessRegDocumentReplace : l10n.businessRegDocumentChoose),
              ),
              if (uploaded && onRemove != null)
                TextButton.icon(
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48), foregroundColor: scheme.error),
                  onPressed: uploading ? null : onRemove,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.businessRegDocumentRemove),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
