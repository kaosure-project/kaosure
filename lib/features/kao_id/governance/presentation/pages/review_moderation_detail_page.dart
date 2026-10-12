import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../auth/application/providers/auth_provider.dart';
import '../../application/providers/staff_tools_providers.dart';
import '../../domain/entities/marketplace_review.dart';
import '../widgets/admin_display.dart';
import 'review_moderation_page.dart';

enum _Decision { hide, keep, show }

/// One review with its reports. Staff hide a review that breaks the rules
/// (with a note the reviewer sees), keep it shown, or show a hidden one again.
class ReviewModerationDetailPage extends ConsumerStatefulWidget {
  const ReviewModerationDetailPage({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ReviewModerationDetailPage> createState() => _ReviewModerationDetailPageState();
}

class _ReviewModerationDetailPageState extends ConsumerState<ReviewModerationDetailPage> {
  final _note = TextEditingController();
  String? _owner;
  MarketplaceReview? _data;
  Object? _error;
  String? _done;
  bool _busy = false;

  bool get _same => mounted && _owner != null && ref.read(authProvider).asData?.value?.id == _owner;

  @override
  void initState() {
    super.initState();
    _owner = ref.read(authProvider).asData?.value?.id;
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!_same || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await ref.read(reviewModerationRepositoryProvider).detail(widget.id);
      if (_same) setState(() => _data = data);
    } catch (e) {
      if (_same) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decide(_Decision decision) async {
    if (_data == null || !_same || _busy) return;
    final l = AppLocalizations.of(context);
    final note = _note.text.trim();
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(switch (decision) {
          _Decision.hide => l.moderationHide,
          _Decision.keep => l.moderationKeep,
          _Decision.show => l.moderationShow,
        }),
        content: Text(switch (decision) {
          _Decision.hide => l.moderationHideConfirm,
          _Decision.keep => l.moderationKeepConfirm,
          _Decision.show => l.moderationShowConfirm,
        }),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(
            key: const ValueKey('review-decision-confirm'),
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.continueLabel),
          ),
        ],
      ),
    );
    if (yes != true || !_same) return;
    setState(() {
      _busy = true;
      _error = null;
      _done = null;
    });
    try {
      await ref
          .read(reviewModerationRepositoryProvider)
          .moderate(widget.id, hide: decision == _Decision.hide, note: note.isEmpty ? null : note);
      if (_same) {
        _note.clear();
        setState(() => _done = l.moderationDone);
      }
    } catch (e) {
      if (_same) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (_same && _error == null) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final same = ref.watch(authProvider).asData?.value?.id == _owner && _owner != null;
    final data = _data;
    final note = _note.text.trim().length;
    final error = Theme.of(context).colorScheme.error;
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
                      if (_busy) const LinearProgressIndicator(),
                      if (_error case final e?)
                        Text(
                          reviewModerationErrorText(l, e),
                          key: const ValueKey('review-error'),
                          style: TextStyle(color: error),
                        ),
                      if (_done case final done?) Text(done, key: const ValueKey('review-done')),
                      if (data != null) ...[
                        AdminSection(
                          title: l.moderationTitle,
                          children: [
                            AdminValue(
                              label: l.moderationVerdict,
                              value: data.good ? l.moderationGood : l.moderationBad,
                            ),
                            AdminValue(
                              label: l.moderationReviewer,
                              value:
                                  '${reviewPartyText(data.reviewer)} (${data.reviewerRole == 'seller' ? l.moderationRoleSeller : l.moderationRoleBuyer})',
                            ),
                            AdminValue(label: l.moderationReviewee, value: reviewPartyText(data.reviewee)),
                            AdminValue(label: l.moderationOrder, value: data.orderNumber, copyable: true),
                            AdminValue(
                              label: l.moderationWrittenAt,
                              value: adminDate(context, data.createdAt?.toIso8601String()),
                            ),
                            if (data.presetIn(language) case final preset? when preset.isNotEmpty)
                              AdminValue(label: l.moderationPreset, value: preset),
                            AdminValue(label: l.moderationComment, value: data.comment),
                            AdminValue(
                              label: l.moderationVisibility,
                              value: data.isVisible ? l.moderationVisible : l.moderationHiddenBadge,
                            ),
                            if (!data.isVisible) ...[
                              AdminValue(
                                label: l.moderationHiddenBy,
                                value:
                                    '${realValue(data.hiddenByName)} · ${adminDate(context, data.hiddenAt?.toIso8601String())}',
                              ),
                              AdminValue(label: l.moderationHiddenReason, value: data.hiddenReason),
                            ],
                          ],
                        ),
                        AdminSection(
                          title: l.moderationReports,
                          children: [
                            if (data.reports.isEmpty) Text(l.moderationNoReports),
                            for (final report in data.reports)
                              ListTile(
                                key: ValueKey('review-report-${report.id}'),
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  report.status == ReviewReportStatus.pending
                                      ? Icons.flag_outlined
                                      : Icons.check_circle_outline,
                                ),
                                title: Text(
                                  '${reviewReasonText(l, report.reason)} · ${_reportStatusText(l, report.status)}',
                                ),
                                subtitle: Text(
                                  [
                                    if (report.detail case final detail? when detail.isNotEmpty) detail,
                                    '${reviewPartyText(report.reporter)} · '
                                        '${adminDate(context, report.createdAt?.toIso8601String())}',
                                  ].join('\n'),
                                ),
                              ),
                          ],
                        ),
                        AdminSection(
                          title: data.isVisible ? l.moderationHide : l.moderationShow,
                          children: [
                            TextField(
                              key: const ValueKey('review-note'),
                              controller: _note,
                              enabled: !_busy,
                              maxLength: 500,
                              maxLines: 3,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: l.moderationNote,
                                helperText: l.moderationNoteHelp,
                                helperMaxLines: 2,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                if (data.isVisible) ...[
                                  FilledButton.icon(
                                    key: const ValueKey('review-hide'),
                                    style: FilledButton.styleFrom(backgroundColor: error),
                                    onPressed: !_busy && note >= 3 ? () => _decide(_Decision.hide) : null,
                                    icon: const Icon(Icons.visibility_off_outlined),
                                    label: Text(l.moderationHide),
                                  ),
                                  if (data.pendingReports > 0)
                                    OutlinedButton.icon(
                                      key: const ValueKey('review-keep'),
                                      onPressed: _busy ? null : () => _decide(_Decision.keep),
                                      icon: const Icon(Icons.verified_outlined),
                                      label: Text(l.moderationKeep),
                                    ),
                                ] else
                                  FilledButton.icon(
                                    key: const ValueKey('review-show'),
                                    onPressed: _busy ? null : () => _decide(_Decision.show),
                                    icon: const Icon(Icons.visibility_outlined),
                                    label: Text(l.moderationShow),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                      if (data == null && !_busy) OutlinedButton(onPressed: _load, child: Text(l.authCheckAgain)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

String _reportStatusText(AppLocalizations l, ReviewReportStatus status) => switch (status) {
  ReviewReportStatus.pending => l.moderationReportPending,
  ReviewReportStatus.upheld => l.moderationReportUpheld,
  ReviewReportStatus.dismissed => l.moderationReportDismissed,
};
