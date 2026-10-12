import 'package:flutter/material.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:kaosure/shared/design_system/colors/app_colors.dart';

import '../../../domain/entities/business_review_item.dart';
import '../../utils/business_registration_texts.dart';

/// One queue row: business, registration number, review state and waiting time.
class BusinessReviewTile extends StatelessWidget {
  const BusinessReviewTile({super.key, required this.item, required this.onTap,
    this.showDivider = true});

  final BusinessReviewItem item;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final submitted = item.submittedAt;
    final second = item.hasFirstVote;
    final waitingDays = submitted == null ? null : DateUtils.dateOnly(DateTime.now())
        .difference(DateUtils.dateOnly(submitted.toLocal())).inDays.clamp(0, 9999);
    return Column(children: [
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.kaoBlueSoft, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.storefront_outlined, color: AppColors.kaoBlue),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.businessName, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('${item.registrationNumber} · ${l10n.businessCategoryLabel(item.businessCategory)}',
                style: text.bodyMedium?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(spacing: 10, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _StatusPill(
                    label: second ? l10n.dualWaiting : l10n.businessReviewStatusNew,
                    color: second ? AppColors.kaoAmber : AppColors.kaoBlue,
                    tint: second ? AppColors.kaoAmberSoft : AppColors.kaoBlueSoft,
                  ),
                  if (submitted != null)
                    Text(
                      '${l10n.businessReviewSubmittedOn(MaterialLocalizations.of(context).formatMediumDate(submitted))}'
                      ' · ${l10n.businessReviewWaitingDays(waitingDays!)}',
                      style: text.bodySmall?.copyWith(color: AppColors.textSecondary)),
                ]),
            ])),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ]),
        ),
      ),
      if (showDivider) const Divider(height: 1, indent: 68),
    ]);
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color, required this.tint});

  final String label;
  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color, fontWeight: FontWeight.w700)),
      );
}
