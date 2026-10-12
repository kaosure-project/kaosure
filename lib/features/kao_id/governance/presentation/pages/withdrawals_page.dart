import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/application/providers/auth_provider.dart';
import '../../application/providers/staff_tools_providers.dart';
import '../../domain/entities/withdrawal_request.dart';
import '../widgets/admin_display.dart';
import 'withdrawal_detail_page.dart';

String withdrawalStatusText(AppLocalizations l, WithdrawalStatus status) => switch (status) {
  WithdrawalStatus.pending => l.withdrawalStatusPending,
  WithdrawalStatus.paid => l.withdrawalStatusPaid,
  WithdrawalStatus.rejected => l.withdrawalStatusRejected,
  WithdrawalStatus.cancelled => l.withdrawalStatusCancelled,
};

String baht(double amount) => '฿${NumberFormat('#,##0.00').format(amount)}';

/// The server's answers for withdrawal tools, in the staff member's language.
String withdrawalErrorText(AppLocalizations l, Object error) {
  final message = error is PostgrestException ? error.message : error.toString();
  for (final (code, text) in [
    ('mfa_required', l.mfaSessionRequired),
    ('own_withdrawal', l.withdrawalErrorOwn),
    ('withdrawal_not_pending', l.withdrawalErrorNotPending),
    ('bank_changed', l.withdrawalBankChanged),
    ('wallet_mismatch', l.withdrawalErrorWallet),
    ('reference_required', l.withdrawalReferenceHelp),
    ('reason_required', l.withdrawalReasonHelp),
    ('withdraw_access_denied', l.staffToolDenied),
  ]) {
    if (message.contains(code)) return text;
  }
  if (error is PostgrestException && error.code == '42501') return l.staffToolDenied;
  return l.staffActionFailed;
}

/// "คำขอถอนเงิน": members' requests to move wallet money to their bank.
class WithdrawalsPage extends ConsumerStatefulWidget {
  const WithdrawalsPage({super.key});

  @override
  ConsumerState<WithdrawalsPage> createState() => _WithdrawalsPageState();
}

class _WithdrawalsPageState extends ConsumerState<WithdrawalsPage> {
  String? _owner;
  WithdrawalStatus _status = WithdrawalStatus.pending;
  List<WithdrawalRequest> _rows = [];
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
    final before = more && _rows.isNotEmpty ? _rows.last.createdAt : null;
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
      final rows = await ref.read(withdrawalReviewRepositoryProvider).queue(_status, before: before);
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

  Future<void> _open(WithdrawalRequest row) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => WithdrawalDetailPage(id: row.id)));
    ref.invalidate(staffToolsProvider);
    if (_same) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final same = ref.watch(authProvider).asData?.value?.id == _owner && _owner != null;
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
                      AdminSection(
                        title: l.withdrawalsTitle,
                        children: [
                          Text(l.withdrawalsHelp),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final status in WithdrawalStatus.values)
                                ChoiceChip(
                                  key: ValueKey('withdrawals-${status.name}'),
                                  label: Text(withdrawalStatusText(l, status)),
                                  selected: _status == status,
                                  onSelected: _busy
                                      ? null
                                      : (_) {
                                          setState(() => _status = status);
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
                      if (_error case final error?) Text(withdrawalErrorText(l, error)),
                      if (_loaded && _rows.isEmpty) Text(l.staffEmpty),
                      for (final row in _rows)
                        Card(
                          key: ValueKey('withdrawal-${row.id}'),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(20),
                            leading: const Icon(Icons.savings_outlined),
                            title: Text('${realValue(row.displayName)} · ${baht(row.amount)}'),
                            subtitle: Text(
                              [
                                realValue(row.accountCode ?? row.profileId),
                                '${row.bankName} ••••${row.last4}',
                                adminDate(context, row.createdAt?.toIso8601String()),
                                if (row.transferReference case final reference? when reference.isNotEmpty)
                                  '${l.withdrawalReference}: $reference',
                                if (row.rejectReason case final reason? when reason.isNotEmpty)
                                  '${l.reviewReason}: $reason',
                              ].join('\n'),
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
