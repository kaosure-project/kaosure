import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/application/providers/auth_provider.dart';
import '../../application/providers/staff_tools_providers.dart';
import '../../domain/entities/marketplace_review.dart';
import '../../domain/entities/order_issue_case.dart';
import '../widgets/admin_display.dart';
import 'order_issue_detail_page.dart';
import 'review_moderation_page.dart';
import 'withdrawals_page.dart';

String orderIssueKindText(AppLocalizations l, String kind) => switch (kind) {
  'not_arrived' => l.orderIssueKindNotArrived,
  'not_as_described' => l.orderIssueKindNotAsDescribed,
  'cancel_request' => l.orderIssueKindCancelRequest,
  _ => kind,
};

String orderIssueStatusText(AppLocalizations l, String status) => switch (status) {
  'open' => l.orderIssueStatusOpen,
  'withdrawn' => l.orderIssueStatusWithdrawn,
  'refunded' => l.orderIssueStatusRefunded,
  'released' => l.orderIssueStatusReleased,
  'dismissed' => l.orderIssueStatusDismissed,
  _ => status,
};

String orderIssuePartyText(ReviewParty? party) => party == null ? realValue(null) : reviewPartyText(party);

/// The server's answers for order issues, in the staff member's language.
String orderIssueErrorText(AppLocalizations l, Object error) {
  final message = error is PostgrestException ? error.message : error.toString();
  for (final (code, text) in [
    ('mfa_required', l.mfaSessionRequired),
    ('own_order', l.orderIssueErrorOwn),
    ('note_required', l.orderIssueNoteHelp),
    ('order_issue_closed', l.orderIssueErrorClosed),
    ('order_issue_not_found', l.orderIssueErrorGone),
    ('order_issue_access_denied', l.staffToolDenied),
  ]) {
    if (message.contains(code)) return text;
  }
  if (error is PostgrestException && error.code == '42501') return l.staffToolDenied;
  return l.staffActionFailed;
}

/// "ปัญหาคำสั่งซื้อ": problems Secondhand buyers reported after shipping,
/// waiting for a decision or already closed.
class OrderIssuesPage extends ConsumerStatefulWidget {
  const OrderIssuesPage({super.key});

  @override
  ConsumerState<OrderIssuesPage> createState() => _OrderIssuesPageState();
}

class _OrderIssuesPageState extends ConsumerState<OrderIssuesPage> {
  String? _owner;
  OrderIssueQueueFilter _filter = OrderIssueQueueFilter.open;
  List<OrderIssueCase> _rows = [];
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
      final rows = await ref.read(orderIssueRepositoryProvider).queue(_filter, before: before);
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

  Future<void> _open(OrderIssueCase row) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => OrderIssueDetailPage(id: row.id)));
    ref.invalidate(staffToolsProvider);
    if (_same) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final same = ref.watch(authProvider).asData?.value?.id == _owner && _owner != null;
    return Scaffold(
      appBar: AppBar(title: Text(l.orderIssuesTitle)),
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
                        title: l.orderIssuesTitle,
                        children: [
                          Text(l.orderIssuesHelp),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final filter in OrderIssueQueueFilter.values)
                                ChoiceChip(
                                  key: ValueKey('order-issues-${filter.name}'),
                                  label: Text(switch (filter) {
                                    OrderIssueQueueFilter.open => l.orderIssuesFilterOpen,
                                    OrderIssueQueueFilter.closed => l.orderIssuesFilterClosed,
                                  }),
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
                      if (_error case final error?) Text(orderIssueErrorText(l, error)),
                      if (_loaded && _rows.isEmpty) Text(l.staffEmpty),
                      for (final row in _rows)
                        Card(
                          key: ValueKey('order-issue-${row.id}'),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(20),
                            leading: Icon(
                              row.isOpen ? Icons.report_problem_outlined : Icons.task_alt_rounded,
                              color: row.isOpen ? Theme.of(context).colorScheme.error : Colors.green.shade700,
                            ),
                            title: Text('${orderIssueKindText(l, row.kind)} · ${realValue(row.order?.productTitle)}'),
                            subtitle: Text(
                              [
                                if (row.detail case final detail? when detail.isNotEmpty) detail,
                                [
                                  realValue(row.order?.orderNumber),
                                  if (row.order case final order?) baht(order.total),
                                  adminDate(context, row.createdAt?.toIso8601String()),
                                ].join(' · '),
                                '${l.moderationRoleBuyer}: ${orderIssuePartyText(row.buyer)} · '
                                    '${l.moderationRoleSeller}: ${orderIssuePartyText(row.seller)}',
                                if (!row.isOpen) orderIssueStatusText(l, row.status),
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
