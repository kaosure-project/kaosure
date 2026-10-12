import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/application/providers/auth_provider.dart';
import '../../application/providers/staff_tools_providers.dart';
import '../../domain/entities/marketplace_review.dart';
import '../widgets/admin_display.dart';
import 'review_moderation_detail_page.dart';

String reviewFilterText(AppLocalizations l, ReviewQueueFilter filter) => switch (filter) {
  ReviewQueueFilter.reported => l.moderationFilterReported,
  ReviewQueueFilter.hidden => l.moderationFilterHidden,
  ReviewQueueFilter.recent => l.moderationFilterRecent,
};

String reviewReasonText(AppLocalizations l, String reason) => switch (reason) {
  'abusive' => l.moderationReasonAbusive,
  'personal_info' => l.moderationReasonPersonalInfo,
  'false_info' => l.moderationReasonFalseInfo,
  'spam' => l.moderationReasonSpam,
  'other' => l.moderationReasonOther,
  _ => reason,
};

String reviewPartyText(ReviewParty party) =>
    [realValue(party.displayName), if (party.accountCode case final code? when code.isNotEmpty) code].join(' · ');

/// The server's answers for review moderation, in the staff member's language.
String reviewModerationErrorText(AppLocalizations l, Object error) {
  final message = error is PostgrestException ? error.message : error.toString();
  for (final (code, text) in [
    ('mfa_required', l.mfaSessionRequired),
    ('own_review', l.moderationErrorOwn),
    ('note_required', l.moderationErrorNote),
    ('review_not_found', l.moderationErrorGone),
    ('review_access_denied', l.staffToolDenied),
  ]) {
    if (message.contains(code)) return text;
  }
  if (error is PostgrestException && error.code == '42501') return l.staffToolDenied;
  return l.staffActionFailed;
}

/// "จัดการรีวิว": reported, hidden and recent Secondhand reviews.
class ReviewModerationPage extends ConsumerStatefulWidget {
  const ReviewModerationPage({super.key});

  @override
  ConsumerState<ReviewModerationPage> createState() => _ReviewModerationPageState();
}

class _ReviewModerationPageState extends ConsumerState<ReviewModerationPage> {
  String? _owner;
  ReviewQueueFilter _filter = ReviewQueueFilter.reported;
  List<MarketplaceReview> _rows = [];
  bool _busy = false, _loaded = false, _more = false;
  Object? _error;

  bool get _same => mounted && _owner != null && ref.read(authProvider).asData?.value?.id == _owner;

  @override
  void initState() {
    super.initState();
    _owner = ref.read(authProvider).asData?.value?.id;
    Future.microtask(_load);
  }

  Future<void> _load({bool more = false}) async {
    if (!_same || _busy) return;
    final before = more && _rows.isNotEmpty ? _rows.last.sortAt : null;
    setState(() {
      _busy = true;
      _error = null;
      if (!more) {
        _rows = [];
        _loaded = false;
        _more = false;
      }
    });
    try {
      final rows = await ref.read(reviewModerationRepositoryProvider).queue(_filter, before: before);
      if (_same) {
        setState(() {
          _rows = [..._rows, ...rows];
          _more = rows.length == 30;
          _loaded = true;
        });
      }
    } catch (e) {
      if (_same) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(MarketplaceReview row) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ReviewModerationDetailPage(id: row.id)));
    ref.invalidate(staffToolsProvider);
    if (_same) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final same = ref.watch(authProvider).asData?.value?.id == _owner && _owner != null;
    return Scaffold(
      appBar: AppBar(title: Text(l.moderationTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: !same
                ? Text(l.contactSessionChanged)
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      AdminSection(
                        title: l.moderationTitle,
                        children: [
                          Text(l.moderationHelp),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final filter in ReviewQueueFilter.values)
                                ChoiceChip(
                                  key: ValueKey('reviews-${filter.name}'),
                                  label: Text(reviewFilterText(l, filter)),
                                  selected: _filter == filter,
                                  onSelected: _busy
                                      ? null
                                      : (_) {
                                          setState(() => _filter = filter);
                                          _load();
                                        },
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: _busy ? null : () => _load(),
                              icon: const Icon(Icons.refresh),
                              label: Text(l.authCheckAgain),
                            ),
                          ),
                        ],
                      ),
                      if (_busy) const LinearProgressIndicator(),
                      if (_error case final error?) Text(reviewModerationErrorText(l, error)),
                      if (_loaded && _rows.isEmpty) Text(l.staffEmpty),
                      for (final row in _rows)
                        Card(
                          key: ValueKey('review-${row.id}'),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(20),
                            leading: Icon(
                              row.good ? Icons.sentiment_satisfied_alt_rounded : Icons.sentiment_dissatisfied_rounded,
                              color: row.good ? Colors.green.shade700 : Theme.of(context).colorScheme.error,
                            ),
                            title: Text(
                              '${row.good ? l.moderationGood : l.moderationBad} · '
                              '${realValue(row.reviewer.displayName)} → ${realValue(row.reviewee.displayName)}',
                            ),
                            subtitle: Text(
                              [
                                if (row.presetIn(language) case final preset? when preset.isNotEmpty) preset,
                                if (row.comment case final comment? when comment.isNotEmpty) comment,
                                [
                                  realValue(row.orderNumber),
                                  adminDate(context, row.createdAt?.toIso8601String()),
                                ].join(' · '),
                                if (!row.isVisible) l.moderationHiddenBadge,
                                if (row.pendingReports > 0)
                                  '${l.moderationPendingReports(row.pendingReports)}: '
                                      '${row.reasons.keys.map((reason) => reviewReasonText(l, reason)).join(', ')}',
                              ].join('\n'),
                              maxLines: 6,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _busy ? null : () => _open(row),
                          ),
                        ),
                      if (_more)
                        OutlinedButton(onPressed: _busy ? null : () => _load(more: true), child: Text(l.adminMore)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
