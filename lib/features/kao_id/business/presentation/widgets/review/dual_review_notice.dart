import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../domain/entities/business_review_item.dart';

class DualReviewNotice extends StatelessWidget {
  const DualReviewNotice({super.key, required this.item, required this.ownVote});

  final BusinessReviewItem item;
  final bool ownVote;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: scheme.onSecondaryContainer),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.groups_outlined, color: scheme.onSecondaryContainer),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.dualReviewHelp)),
            ]),
            if (item.hasFirstVote) ...[
              const SizedBox(height: 12),
              Text('${l10n.dualFirstDecision}: '
                  '${item.firstDecisionApprove == true ? l10n.businessReviewApprove : l10n.businessReviewReject}',
                  style: theme.textTheme.titleSmall?.copyWith(color: scheme.onSecondaryContainer)),
              if (item.firstReason != null) SelectableText(item.firstReason!),
              const SizedBox(height: 8),
              Text(ownVote ? l10n.dualOwnVote : l10n.dualDisagreeHelp),
            ],
          ],
        ),
      ),
    );
  }
}
