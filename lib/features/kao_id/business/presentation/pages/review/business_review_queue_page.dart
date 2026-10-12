import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../../account/presentation/pages/security/mfa_page.dart';
import '../../../../governance/application/services/access_refresh.dart';
import '../../../application/providers/business_review_providers.dart';
import '../../../domain/entities/business_review_item.dart';
import '../../../domain/failures/business_review_failure.dart';
import '../../utils/business_review_texts.dart';
import '../../widgets/review/business_review_tile.dart';
import 'business_review_detail_page.dart';

class BusinessReviewQueuePage extends ConsumerStatefulWidget {
  const BusinessReviewQueuePage({super.key});

  @override
  ConsumerState<BusinessReviewQueuePage> createState() => _BusinessReviewQueuePageState();
}

class _BusinessReviewQueuePageState extends ConsumerState<BusinessReviewQueuePage>
    with WidgetsBindingObserver, AccessRefresh<BusinessReviewQueuePage> {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final queue = ref.watch(businessReviewQueueProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.businessReviewTitle),
        actions: [
          IconButton(
            tooltip: l10n.authCheckAgain,
            onPressed: queue.isLoading ? null : refreshAccess,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: l10n.twoFactorAuthentication,
            onPressed: _openMfa,
            icon: const Icon(Icons.security),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: queue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _QueueMessage(
                icon: Icons.lock_outline,
                message: l10n.businessReviewFailureMessage(error is BusinessReviewFailure
                    ? error.code
                    : BusinessReviewFailureCode.unknown),
                actions: [
                  OutlinedButton(onPressed: refreshAccess, child: Text(l10n.authCheckAgain)),
                  TextButton(onPressed: _openMfa, child: Text(l10n.twoFactorAuthentication)),
                ],
              ),
              data: (items) => RefreshIndicator(
                onRefresh: () => ref.refresh(businessReviewQueueProvider.future),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(l10n.businessReviewQueueHelp,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 12),
                    if (items.isEmpty)
                      _QueueMessage(icon: Icons.inbox_outlined, message: l10n.businessReviewEmpty)
                    else
                      for (final item in items)
                        BusinessReviewTile(item: item, onTap: () => _open(item)),
                  ],
                ),
              ),
            ),
          ),
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
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
