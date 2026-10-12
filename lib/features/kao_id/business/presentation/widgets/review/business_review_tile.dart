import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../domain/entities/business_review_item.dart';
import '../../utils/business_registration_texts.dart';

class BusinessReviewTile extends StatelessWidget {
  const BusinessReviewTile({super.key, required this.item, required this.onTap});

  final BusinessReviewItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final submitted = item.submittedAt;
    return Card.outlined(
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: const Icon(Icons.storefront_outlined),
        ),
        title: Text(item.businessName, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text('${item.registrationNumber} · ${l10n.businessCategoryLabel(item.businessCategory)}'),
            if (submitted != null)
              Text(l10n.businessReviewSubmittedOn(
                  MaterialLocalizations.of(context).formatMediumDate(submitted))),
            if (item.hasFirstVote)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(l10n.dualWaiting,
                    style: theme.textTheme.labelMedium?.copyWith(color: scheme.tertiary)),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
