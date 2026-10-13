import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/features/wallet/domain/entities/topup_request.dart';
import 'package:kaosure/features/wallet/presentation/utils/topup_texts.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/application/providers/auth_provider.dart';
import '../../application/providers/staff_tools_providers.dart';
import '../../domain/entities/topup_review.dart';
import '../widgets/admin_display.dart';
import 'topup_detail_page.dart';
import 'topup_settings_page.dart';

/// The server's answers for top-up tools, in the staff member's language.
String topupReviewErrorText(AppLocalizations l, Object error) {
  final message = error is PostgrestException ? error.message : error.toString();
  for (final (code, text) in [
    ('mfa_required', l.mfaSessionRequired),
    ('payer_confirmation_required', l.topupReviewPayerRequired),
    ('reference_required', l.topupReviewReferenceHelp),
    ('reason_required', l.withdrawalReasonHelp),
    ('own_topup', l.topupReviewOwn),
    ('topup_not_pending', l.withdrawalErrorNotPending),
    ('second_reviewer_required', l.topupReviewSecondRequired),
    ('member_kao_id_inactive', l.topupReviewKaoIdInactive),
    ('reference_used', l.topupReviewReferenceUsed),
    ('reference_mismatch', l.topupReviewReferenceMismatch),
    ('wallet_unavailable', l.topupBlockWallet),
    ('settings_changed', l.topupSettingsChanged),
    ('receiver_required', l.topupSettingsReceiverRequired),
    ('invalid_promptpay', l.topupSettingsPromptPayInvalid),
    ('invalid_settings', l.topupSettingsInvalid),
    ('topup_access_denied', l.staffToolDenied),
    ('topup_settings_denied', l.staffToolDenied),
  ]) {
    if (message.contains(code)) return text;
  }
  if (error is PostgrestException && error.code == '42501') return l.staffToolDenied;
  return l.staffActionFailed;
}

const _queueStatuses = [
  TopupStatus.pendingReview,
  TopupStatus.awaitingSecond,
  TopupStatus.approved,
  TopupStatus.rejected,
  TopupStatus.awaitingSlip,
  TopupStatus.expired,
  TopupStatus.cancelled,
];

/// "คำขอเติมเงิน": slips waiting for staff to check and credit.
class TopupsPage extends ConsumerStatefulWidget {
  const TopupsPage({super.key, this.canEditSettings = false});

  final bool canEditSettings;

  @override
  ConsumerState<TopupsPage> createState() => _TopupsPageState();
}

class _TopupsPageState extends ConsumerState<TopupsPage> {
  String? _owner;
  TopupStatus _status = TopupStatus.pendingReview;
  List<TopupReviewItem> _rows = [];
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
    final before = more && _rows.isNotEmpty ? _rows.last.request.createdAt : null;
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
      final rows = await ref.read(topupReviewRepositoryProvider).queue(_status, before: before);
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

  Future<void> _push(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
    ref.invalidate(staffToolsProvider);
    if (_same) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final same = ref.watch(authProvider).asData?.value?.id == _owner && _owner != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.topupsTitle),
        actions: [
          if (widget.canEditSettings)
            IconButton(
              key: const ValueKey('topups-settings'),
              tooltip: l.topupSettingsTitle,
              onPressed: () => _push(const TopupSettingsPage()),
              icon: const Icon(Icons.tune),
            ),
        ],
      ),
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
                        title: l.topupsTitle,
                        children: [
                          Text(l.topupsHelp),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final status in _queueStatuses)
                                ChoiceChip(
                                  key: ValueKey('topups-${status.code}'),
                                  label: Text(topupStatusText(l, status)),
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
                      if (_error case final error?) Text(topupReviewErrorText(l, error)),
                      if (_loaded && _rows.isEmpty) Text(l.staffEmpty),
                      for (final row in _rows)
                        Card(
                          key: ValueKey('topup-${row.request.id}'),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(20),
                            leading: const Icon(Icons.qr_code_2),
                            title: Text('${realValue(row.displayName)} · ${topupBaht(row.request.amount)}'),
                            subtitle: Text(
                              [
                                '${row.request.code} · ${realValue(row.accountCode ?? row.profileId)}',
                                adminDate(context, row.request.createdAt?.toIso8601String()),
                                if (row.dualReview) l.topupReviewDual,
                                if (row.firstReviewerName case final name?) '${l.topupReviewFirst}: $name',
                                if (row.bankReference case final reference? when reference.isNotEmpty)
                                  '${l.topupReviewReference}: $reference',
                                if (row.request.rejectReason case final reason? when reason.isNotEmpty)
                                  '${l.topupRejectReason}: $reason',
                              ].join('\n'),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _busy ? null : () => _push(TopupDetailPage(id: row.request.id)),
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
