import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/features/wallet/domain/entities/topup_request.dart';
import 'package:kaosure/features/wallet/presentation/utils/topup_texts.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../auth/application/providers/auth_provider.dart';
import '../../application/providers/staff_tools_providers.dart';
import '../../domain/entities/topup_review.dart';
import '../widgets/admin_display.dart';
import 'topups_page.dart';

/// One top-up with its slip. Staff check the amount, the receiving account and
/// that the payer is the member named in Kao ID, then approve with the bank
/// reference or decline with a reason.
class TopupDetailPage extends ConsumerStatefulWidget {
  const TopupDetailPage({super.key, required this.id});

  final String id;

  @override
  ConsumerState<TopupDetailPage> createState() => _TopupDetailPageState();
}

class _TopupDetailPageState extends ConsumerState<TopupDetailPage> {
  final _reference = TextEditingController();
  final _reason = TextEditingController();
  String? _owner;
  TopupReviewDetail? _data;
  Uint8List? _slip;
  bool _slipFailed = false;
  bool _payerConfirmed = false;
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
    _reference.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!_same || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final repository = ref.read(topupReviewRepositoryProvider);
    try {
      final data = await repository.detail(widget.id);
      if (!_same) return;
      setState(() => _data = data);
      final path = data.slipPath;
      if (path != null && _slip == null) {
        try {
          final bytes = await repository.slip(path);
          if (_same) setState(() => _slip = bytes);
        } catch (_) {
          if (_same) setState(() => _slipFailed = true);
        }
      }
    } catch (e) {
      if (_same) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _review({required bool approve}) async {
    final data = _data;
    if (data == null || !_same || _busy) return;
    final l = AppLocalizations.of(context);
    final item = data.item;
    final amount = topupBaht(item.request.amount);
    final firstVote = item.dualReview && item.request.status == TopupStatus.pendingReview;
    final text = (approve ? _reference : _reason).text.trim();
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(approve ? _approveLabel(l, item) : l.topupReviewReject),
        content: Text(
          !approve
              ? l.topupReviewRejectConfirm(amount)
              : firstVote
              ? l.topupReviewFirstConfirm(amount)
              : l.topupReviewApproveConfirm(amount, realValue(data.memberName ?? item.displayName)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(
            key: const ValueKey('topup-confirm'),
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
    final repository = ref.read(topupReviewRepositoryProvider);
    try {
      final result = approve
          ? await repository.approve(item.request.id, payerConfirmed: _payerConfirmed, reference: text)
          : await repository.reject(item.request.id, text);
      if (_same) {
        setState(
          () => _done = switch (result.request.status) {
            TopupStatus.approved => l.topupReviewApprovedDone,
            TopupStatus.awaitingSecond => l.topupReviewFirstDone,
            _ => l.topupReviewRejectedDone,
          },
        );
      }
    } catch (e) {
      if (_same) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (_same && _error == null) await _load();
  }

  String _approveLabel(AppLocalizations l, TopupReviewItem item) => switch (item.request.status) {
    TopupStatus.awaitingSecond => l.topupReviewSecondApprove,
    _ when item.dualReview => l.topupReviewFirstApprove,
    _ => l.topupReviewApprove,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final same = ref.watch(authProvider).asData?.value?.id == _owner && _owner != null;
    final data = _data;
    final item = data?.item;
    final request = item?.request;
    final open = request != null && (request.status == TopupStatus.pendingReview || request.status == TopupStatus.awaitingSecond);
    final myFirstVote = request?.status == TopupStatus.awaitingSecond && item?.firstReviewer == _owner;
    final canAct = data != null && open && !data.ownRequest && !myFirstVote;
    final canApprove = canAct && data.kaoIdActive && _payerConfirmed && _reference.text.trim().length >= 3;
    final error = TextStyle(color: theme.colorScheme.error);
    return Scaffold(
      appBar: AppBar(title: Text(l.topupsTitle)),
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
                      if (_error case final failure?)
                        Text(topupReviewErrorText(l, failure), key: const ValueKey('topup-error'), style: error),
                      if (_done case final done?) Text(done, key: const ValueKey('topup-done')),
                      if (data != null && item != null && request != null) ...[
                        AdminSection(
                          title: l.adminMembersTitle,
                          children: [
                            AdminValue(label: l.displayName, value: item.displayName),
                            AdminValue(label: l.topupReviewVerifiedName, value: data.memberName),
                            AdminValue(label: l.kaoId, value: data.kaoId, copyable: true),
                            AdminValue(label: l.adminAccountCode, value: item.accountCode, copyable: true),
                            AdminValue(label: l.adminUserId, value: item.profileId, copyable: true),
                            if (!data.kaoIdActive)
                              Text(l.topupReviewKaoIdInactive, key: const ValueKey('topup-kao-id-inactive'), style: error),
                          ],
                        ),
                        AdminSection(
                          title: l.topupsTitle,
                          children: [
                            AdminValue(label: l.topupReviewCode, value: request.code, copyable: true),
                            AdminValue(label: l.topupReviewStatus, value: topupStatusText(l, request.status)),
                            AdminValue(label: l.withdrawalAmount, value: topupBaht(request.amount)),
                            AdminValue(label: l.topupReviewSource, value: request.sourceApp),
                            AdminValue(
                              label: l.withdrawalRequestedAt,
                              value: adminDate(context, request.createdAt?.toIso8601String()),
                            ),
                            AdminValue(
                              label: l.topupReviewSlipSent,
                              value: adminDate(context, request.slipUploadedAt?.toIso8601String()),
                            ),
                            AdminValue(label: l.topupReceiver, value: request.receiverName),
                            AdminValue(label: l.topupSettingsId, value: request.promptPayMasked),
                            AdminValue(
                              label: l.topupReviewWallet,
                              value: '${topupBaht(data.walletBalance)} · ${realValue(data.walletStatus)}',
                            ),
                            AdminValue(label: l.topupReviewToday, value: topupBaht(data.todayTotal)),
                            if (item.dualReview) Text(l.topupReviewDual, key: const ValueKey('topup-dual')),
                            if (item.firstReviewerName != null || item.firstReviewedAt != null)
                              AdminValue(
                                label: l.topupReviewFirst,
                                value:
                                    '${realValue(item.firstReviewerName)} · ${adminDate(context, item.firstReviewedAt?.toIso8601String())}',
                              ),
                            if (item.bankReference != null)
                              AdminValue(label: l.topupReviewReference, value: item.bankReference, copyable: true),
                            if (request.rejectReason != null)
                              AdminValue(label: l.topupRejectReason, value: request.rejectReason),
                            if (item.reviewerName != null || request.reviewedAt != null)
                              AdminValue(
                                label: l.withdrawalReviewer,
                                value:
                                    '${realValue(item.reviewerName)} · ${adminDate(context, request.reviewedAt?.toIso8601String())}',
                              ),
                            const SizedBox(height: 8),
                            Text(l.withdrawalDetailLogged, style: theme.textTheme.bodySmall),
                          ],
                        ),
                        if (data.duplicates.isNotEmpty)
                          AdminSection(
                            title: l.topupReviewDuplicates,
                            children: [
                              for (final other in data.duplicates)
                                Text(
                                  '${other.code} · ${topupBaht(other.amount)} · ${topupStatusText(l, other.status)}',
                                  key: ValueKey('topup-duplicate-${other.code}'),
                                  style: error,
                                ),
                            ],
                          ),
                        AdminSection(
                          title: l.topupReviewSlip,
                          children: [
                            if (_slip case final bytes?)
                              SizedBox(
                                height: 520,
                                child: InteractiveViewer(
                                  maxScale: 5,
                                  child: Image.memory(bytes, key: const ValueKey('topup-slip'), fit: BoxFit.contain),
                                ),
                              )
                            else if (_slipFailed)
                              Text(l.topupReviewSlipFailed, style: error)
                            else if (data.slipPath == null)
                              Text(l.topupStatusAwaitingSlip),
                          ],
                        ),
                        if (open && data.ownRequest) Text(l.topupReviewOwn, key: const ValueKey('topup-own')),
                        if (open && myFirstVote)
                          Text(l.topupReviewWaitingOther, key: const ValueKey('topup-waiting-other')),
                        if (canAct) ...[
                          AdminSection(
                            title: _approveLabel(l, item),
                            children: [
                              CheckboxListTile(
                                key: const ValueKey('topup-payer'),
                                value: _payerConfirmed,
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                onChanged: _busy || !data.kaoIdActive
                                    ? null
                                    : (value) => setState(() => _payerConfirmed = value ?? false),
                                title: Text(l.topupReviewPayerConfirm(realValue(data.memberName ?? item.displayName))),
                              ),
                              TextField(
                                key: const ValueKey('topup-reference'),
                                controller: _reference,
                                enabled: !_busy && data.kaoIdActive,
                                maxLength: 100,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  labelText: l.topupReviewReference,
                                  helperText: request.status == TopupStatus.awaitingSecond
                                      ? l.topupReviewSecondHelp
                                      : l.topupReviewReferenceHelp,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                              FilledButton.icon(
                                key: const ValueKey('topup-approve'),
                                onPressed: canApprove && !_busy ? () => _review(approve: true) : null,
                                icon: const Icon(Icons.check_circle_outline),
                                label: Text(_approveLabel(l, item)),
                              ),
                            ],
                          ),
                          AdminSection(
                            title: l.topupReviewReject,
                            children: [
                              TextField(
                                key: const ValueKey('topup-reason'),
                                controller: _reason,
                                enabled: !_busy,
                                maxLength: 500,
                                maxLines: 3,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  labelText: l.topupRejectReason,
                                  helperText: l.withdrawalReasonHelp,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                              OutlinedButton.icon(
                                key: const ValueKey('topup-reject'),
                                onPressed: !_busy && _reason.text.trim().length >= 3
                                    ? () => _review(approve: false)
                                    : null,
                                icon: const Icon(Icons.block),
                                label: Text(l.topupReviewReject),
                              ),
                            ],
                          ),
                        ],
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
