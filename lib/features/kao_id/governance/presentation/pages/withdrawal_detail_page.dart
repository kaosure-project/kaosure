import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../auth/application/providers/auth_provider.dart';
import '../../application/providers/staff_tools_providers.dart';
import '../../domain/entities/withdrawal_request.dart';
import '../widgets/admin_display.dart';
import 'withdrawals_page.dart';

/// One request with the full account number for the transfer. Staff send the
/// money from the company account, then confirm with the bank reference;
/// rejecting returns the amount to the member's wallet.
class WithdrawalDetailPage extends ConsumerStatefulWidget {
  const WithdrawalDetailPage({super.key, required this.id});

  final String id;

  @override
  ConsumerState<WithdrawalDetailPage> createState() => _WithdrawalDetailPageState();
}

class _WithdrawalDetailPageState extends ConsumerState<WithdrawalDetailPage> {
  final _reference = TextEditingController();
  final _reason = TextEditingController();
  String? _owner;
  WithdrawalTransfer? _data;
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
    try {
      final data = await ref.read(withdrawalReviewRepositoryProvider).detail(widget.id);
      if (_same) setState(() => _data = data);
    } catch (e) {
      if (_same) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _review({required bool paid}) async {
    final data = _data;
    if (data == null || !_same || _busy) return;
    final l = AppLocalizations.of(context);
    final request = data.request;
    final text = (paid ? _reference : _reason).text.trim();
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(paid ? l.withdrawalMarkPaid : l.withdrawalReject),
        content: Text(
          paid
              ? l.withdrawalPaidConfirm(baht(request.amount), request.bankName, data.accountNumber)
              : l.withdrawalRejectConfirm(baht(request.amount)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(
            key: const ValueKey('withdrawal-confirm'),
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
    final repository = ref.read(withdrawalReviewRepositoryProvider);
    try {
      paid ? await repository.markPaid(request.id, text) : await repository.reject(request.id, text);
      if (_same) setState(() => _done = paid ? l.withdrawalPaidDone : l.withdrawalRejectedDone);
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
    final same = ref.watch(authProvider).asData?.value?.id == _owner && _owner != null;
    final data = _data;
    final request = data?.request;
    final pending = request?.status == WithdrawalStatus.pending;
    final reference = _reference.text.trim().length;
    final reason = _reason.text.trim().length;
    return Scaffold(
      appBar: AppBar(title: Text(l.withdrawalsTitle)),
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
                      if (_error case final error?)
                        Text(withdrawalErrorText(l, error), key: const ValueKey('withdrawal-error')),
                      if (_done case final done?) Text(done, key: const ValueKey('withdrawal-done')),
                      if (data != null && request != null) ...[
                        AdminSection(
                          title: l.adminMembersTitle,
                          children: [
                            AdminValue(label: l.displayName, value: request.displayName),
                            AdminValue(label: l.adminAccountCode, value: request.accountCode, copyable: true),
                            AdminValue(label: l.adminUserId, value: request.profileId, copyable: true),
                          ],
                        ),
                        AdminSection(
                          title: l.withdrawalsTitle,
                          children: [
                            AdminValue(label: l.lifeTitle, value: withdrawalStatusText(l, request.status)),
                            AdminValue(label: l.withdrawalAmount, value: baht(request.amount)),
                            AdminValue(
                              label: l.withdrawalRequestedAt,
                              value: adminDate(context, request.createdAt?.toIso8601String()),
                            ),
                            AdminValue(label: l.withdrawalBank, value: request.bankName),
                            AdminValue(label: l.withdrawalAccountName, value: request.accountName, copyable: true),
                            AdminValue(label: l.withdrawalAccountNumber, value: data.accountNumber, copyable: true),
                            AdminValue(label: l.withdrawalBranch, value: data.branchName),
                            AdminValue(
                              label: l.withdrawalWallet,
                              value: '${baht(data.walletBalance)} / ${baht(data.walletHold)}',
                            ),
                            if (request.transferReference != null)
                              AdminValue(
                                label: l.withdrawalReference,
                                value: request.transferReference,
                                copyable: true,
                              ),
                            if (request.rejectReason != null)
                              AdminValue(label: l.reviewReason, value: request.rejectReason),
                            if (request.reviewerName != null || request.reviewedAt != null)
                              AdminValue(
                                label: l.withdrawalReviewer,
                                value:
                                    '${realValue(request.reviewerName)} · ${adminDate(context, request.reviewedAt?.toIso8601String())}',
                              ),
                            if (pending && !data.bankStillVerified)
                              Text(
                                l.withdrawalBankChanged,
                                key: const ValueKey('withdrawal-bank-changed'),
                                style: TextStyle(color: Theme.of(context).colorScheme.error),
                              ),
                            const SizedBox(height: 8),
                            Text(l.withdrawalDetailLogged, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                        if (pending) ...[
                          AdminSection(
                            title: l.withdrawalMarkPaid,
                            children: [
                              TextField(
                                key: const ValueKey('withdrawal-reference'),
                                controller: _reference,
                                enabled: !_busy && data.bankStillVerified,
                                maxLength: 100,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  labelText: l.withdrawalReference,
                                  helperText: l.withdrawalReferenceHelp,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                              FilledButton.icon(
                                key: const ValueKey('withdrawal-mark-paid'),
                                onPressed: !_busy && data.bankStillVerified && reference >= 3
                                    ? () => _review(paid: true)
                                    : null,
                                icon: const Icon(Icons.check_circle_outline),
                                label: Text(l.withdrawalMarkPaid),
                              ),
                            ],
                          ),
                          AdminSection(
                            title: l.withdrawalReject,
                            children: [
                              TextField(
                                key: const ValueKey('withdrawal-reason'),
                                controller: _reason,
                                enabled: !_busy,
                                maxLength: 500,
                                maxLines: 3,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  labelText: l.withdrawalRejectReason,
                                  helperText: l.withdrawalReasonHelp,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                              OutlinedButton.icon(
                                key: const ValueKey('withdrawal-reject'),
                                onPressed: !_busy && reason >= 3 ? () => _review(paid: false) : null,
                                icon: const Icon(Icons.undo),
                                label: Text(l.withdrawalReject),
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
