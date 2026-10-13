import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

class ReviewDecisionPanel extends StatelessWidget {
  const ReviewDecisionPanel({
    super.key,
    required this.reasonController,
    required this.checked,
    required this.directorConfirmed,
    required this.busy,
    required this.ownVote,
    required this.documentsViewed,
    required this.onCheckedChanged,
    required this.onDirectorChanged,
    required this.onApprove,
    required this.onReject,
  });

  final TextEditingController reasonController;
  final bool checked;
  final bool directorConfirmed;
  final bool busy;
  final bool ownVote;
  final bool documentsViewed;
  final ValueChanged<bool>? onCheckedChanged;
  final ValueChanged<bool>? onDirectorChanged;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.businessReviewDecisionHeading,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: checked,
          title: Text(l10n.businessReviewChecked),
          onChanged: onCheckedChanged == null ? null : (value) => onCheckedChanged!(value ?? false),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: directorConfirmed,
          title: Text(l10n.businessReviewDirectorConfirm),
          subtitle: Text(l10n.businessReviewDirectorConfirmHelp),
          onChanged: onDirectorChanged == null ? null : (value) => onDirectorChanged!(value ?? false),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: reasonController,
          enabled: !busy && !ownVote,
          maxLength: 1000,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(labelText: l10n.businessReviewReason, border: const OutlineInputBorder()),
        ),
        if (ownVote)
          Text(l10n.dualOwnVote, style: theme.textTheme.bodySmall?.copyWith(color: scheme.tertiary))
        else if (!documentsViewed)
          Text(
            l10n.businessReviewViewAllHint,
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        const SizedBox(height: 16),
        if (busy) const Padding(padding: EdgeInsets.only(bottom: 12), child: LinearProgressIndicator()),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: onApprove,
          icon: const Icon(Icons.verified_outlined),
          label: Text(l10n.businessReviewApprove),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: scheme.error,
            side: BorderSide(color: onReject == null ? scheme.outlineVariant : scheme.error),
          ),
          onPressed: onReject,
          icon: const Icon(Icons.block),
          label: Text(l10n.businessReviewReject),
        ),
      ],
    );
  }
}
