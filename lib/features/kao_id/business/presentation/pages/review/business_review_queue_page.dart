import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:kaosure/shared/design_system/colors/app_colors.dart';

import '../../../../account/presentation/pages/security/mfa_page.dart';
import '../../../../dashboard/presentation/widgets/home/dashboard_panel.dart';
import '../../../../dashboard/presentation/widgets/section/menu_panel.dart';
import '../../../../dashboard/presentation/widgets/section/section_body.dart';
import '../../../../governance/application/services/access_refresh.dart';
import '../../../../governance/presentation/widgets/admin/admin_scaffold.dart';
import '../../../application/providers/business_review_providers.dart';
import '../../../domain/entities/business_review_item.dart';
import '../../../domain/failures/business_review_failure.dart';
import '../../utils/business_review_texts.dart';
import '../../widgets/review/business_review_tile.dart';
import 'business_review_detail_page.dart';

enum _QueueFilter { all, fresh, second }

class BusinessReviewQueuePage extends ConsumerStatefulWidget {
  const BusinessReviewQueuePage({super.key, this.onlySecondVote = false});

  /// Opens with the "awaiting second reviewer" filter selected.
  final bool onlySecondVote;

  @override
  ConsumerState<BusinessReviewQueuePage> createState() => _BusinessReviewQueuePageState();
}

class _BusinessReviewQueuePageState extends ConsumerState<BusinessReviewQueuePage>
    with WidgetsBindingObserver, AccessRefresh<BusinessReviewQueuePage> {
  late _QueueFilter _filter = widget.onlySecondVote ? _QueueFilter.second : _QueueFilter.all;

  @override
  void refreshAccess() => ref.invalidate(businessReviewQueueProvider);

  Future<void> _openMfa() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MfaPage()));
    if (mounted) refreshAccess();
  }

  Future<void> _open(BusinessReviewItem item) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => BusinessReviewDetailPage(item: item),
    ));
    if (mounted) refreshAccess();
  }

  bool _matches(BusinessReviewItem item) => switch (_filter) {
        _QueueFilter.all => true,
        _QueueFilter.fresh => !item.hasFirstVote,
        _QueueFilter.second => item.hasFirstVote,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final queue = ref.watch(businessReviewQueueProvider);
    final items = queue.asData?.value;

    Widget filters(List<BusinessReviewItem> items) {
      final second = items.where((item) => item.hasFirstVote).length;
      final counts = {
        _QueueFilter.all: (l10n.businessReviewFilterAll, items.length),
        _QueueFilter.fresh: (l10n.businessReviewStatusNew, items.length - second),
        _QueueFilter.second: (l10n.dualWaiting, second),
      };
      return Wrap(spacing: 8, runSpacing: 8, children: [
        for (final MapEntry(key: filter, value: (label, count)) in counts.entries)
          ChoiceChip(
            label: Text('$label ($count)'),
            selected: _filter == filter,
            showCheckmark: false,
            selectedColor: AppColors.kaoBlueSoft,
            backgroundColor: AppColors.surface,
            side: BorderSide(color: _filter == filter ? AppColors.kaoBlue : AppColors.border),
            labelStyle: TextStyle(
              color: _filter == filter ? AppColors.kaoBlue : AppColors.textPrimary,
              fontWeight: _filter == filter ? FontWeight.w700 : FontWeight.w500),
            onSelected: (_) => setState(() => _filter = filter),
          ),
      ]);
    }

    Widget list(List<BusinessReviewItem> items) {
      if (items.isEmpty) {
        return DashboardPanel(child: _QueueMessage(
          icon: Icons.inbox_outlined, message: l10n.businessReviewEmpty));
      }
      final shown = items.where(_matches).toList();
      if (shown.isEmpty) {
        return DashboardPanel(child: _QueueMessage(
          icon: Icons.filter_list_off, message: l10n.businessReviewEmptyFilter));
      }
      return MenuPanel(children: [
        for (var i = 0; i < shown.length; i++)
          BusinessReviewTile(item: shown[i], showDivider: i < shown.length - 1,
            onTap: () => _open(shown[i])),
      ]);
    }

    return AdminScaffold(
      actions: [
        IconButton(
          tooltip: l10n.authCheckAgain,
          color: AppColors.kaoBlue,
          onPressed: queue.isLoading ? null : refreshAccess,
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          tooltip: l10n.twoFactorAuthentication,
          color: AppColors.kaoBlue,
          onPressed: _openMfa,
          icon: const Icon(Icons.security),
        ),
      ],
      child: SectionBody(
        icon: Icons.storefront_outlined,
        color: AppColors.kaoBlue,
        tint: AppColors.kaoBlueSoft,
        title: l10n.businessReviewTitle,
        description: l10n.businessReviewQueueHelp,
        onRefresh: items == null ? null : () async {
          await ref.refresh(businessReviewQueueProvider.future).then((_) {}, onError: (_) {});
        },
        top: [
          if (queue.isLoading && items != null) const LinearProgressIndicator(),
          if (items != null && items.isNotEmpty) filters(items),
        ],
        start: [
          queue.when(
            loading: () => const DashboardPanel(
              child: Center(child: CircularProgressIndicator())),
            error: (error, _) => DashboardPanel(child: _QueueMessage(
              icon: Icons.lock_outline,
              message: l10n.businessReviewFailureMessage(error is BusinessReviewFailure
                  ? error.code
                  : BusinessReviewFailureCode.unknown),
              actions: [
                OutlinedButton(onPressed: refreshAccess, child: Text(l10n.authCheckAgain)),
                TextButton(onPressed: _openMfa, child: Text(l10n.twoFactorAuthentication)),
              ],
            )),
            data: list,
          ),
        ],
      ),
    );
  }
}

class _QueueMessage extends StatelessWidget {
  const _QueueMessage({required this.icon, required this.message, this.actions = const []});

  final IconData icon;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: actions),
          ],
        ],
      ),
    );
  }
}
