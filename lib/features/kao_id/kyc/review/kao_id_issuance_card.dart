import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import 'kyc_review_repository.dart';
import 'review_failure_message.dart';

class KaoIdIssuanceCard extends ConsumerStatefulWidget {
  const KaoIdIssuanceCard({super.key, required this.eligible});
  final bool eligible;
  @override
  ConsumerState<KaoIdIssuanceCard> createState() => _KaoIdIssuanceCardState();
}
class _KaoIdIssuanceCardState extends ConsumerState<KaoIdIssuanceCard> {
  bool _busy = false;
  Object? _failure;
  Future<void> _issue() async {
    if (_busy) { return; }
    setState(() { _busy = true; _failure = null; });
    try {
      await ref.read(kycReviewRepositoryProvider).issue();
      if (!mounted) { return; }
      ref.invalidate(myKaoIdR7cProvider);
    } catch (error) {
      if (mounted) { setState(() => _failure = error); }
    } finally {
      if (mounted) { setState(() => _busy = false); }
    }
  }
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final current = ref.watch(myKaoIdR7cProvider);
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l.kaoId, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        current.when(
          skipLoadingOnRefresh: false,
          skipLoadingOnReload: false,
          loading: () => const LinearProgressIndicator(),
          error: (error, stack) => Text(l.issueLoadFailed),
          data: (identity) {
            if (identity != null) {
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SelectableText(identity['kao_id'] as String),
                Text(identity['status'] == 'active' ? l.issueActive : l.issueInactive),
              ]);
            }
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(widget.eligible ? l.issueReady : l.issueAwaitingReview),
              if (widget.eligible) FilledButton(onPressed: _busy ? null : _issue,
                child: Text(l.issueRequest)),
            ]);
          },
        ),
        if (_busy) const LinearProgressIndicator(),
        if (_failure != null) Text(reviewFailureMessage(l, _failure!, l.issueFailed)),
        TextButton(onPressed: _busy ? null : () => ref.invalidate(myKaoIdR7cProvider),
          child: Text(l.authCheckAgain)),
      ],
    )));
  }
}
