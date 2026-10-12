import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaosure/l10n/app_localizations.dart';

import '../../../auth/application/providers/auth_provider.dart';
import '../../application/providers/staff_tools_providers.dart';
import '../../domain/entities/order_issue_case.dart';
import '../widgets/admin_display.dart';
import 'order_issues_page.dart';
import 'withdrawals_page.dart';

/// One reported order with its history. Staff refund the buyer, pay the
/// seller, or let the order carry on; every decision needs a note both
/// members see.
class OrderIssueDetailPage extends ConsumerStatefulWidget {
  const OrderIssueDetailPage({super.key, required this.id});

  final String id;

  @override
  ConsumerState<OrderIssueDetailPage> createState() => _OrderIssueDetailPageState();
}

class _OrderIssueDetailPageState extends ConsumerState<OrderIssueDetailPage> {
  final _note = TextEditingController();
  String? _owner;
  OrderIssueCase? _data;
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
      final data = await ref.read(orderIssueRepositoryProvider).detail(widget.id);
      if (_same) setState(() => _data = data);
    } catch (e) {
      if (_same) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decide(OrderIssueDecision decision) async {
    if (_data == null || !_same || _busy) return;
    final l = AppLocalizations.of(context);
    final note = _note.text.trim();
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(_decisionText(l, decision)),
        content: Text(switch (decision) {
          OrderIssueDecision.refund => l.orderIssueRefundConfirm,
          OrderIssueDecision.release => l.orderIssueReleaseConfirm,
          OrderIssueDecision.dismiss => l.orderIssueDismissConfirm,
        }),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(
            key: const ValueKey('order-issue-decision-confirm'),
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
      await ref.read(orderIssueRepositoryProvider).resolve(widget.id, decision, note);
      if (_same) {
        _note.clear();
        setState(() => _done = l.orderIssueDone);
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
    final same = ref.watch(authProvider).asData?.value?.id == _owner && _owner != null;
    final data = _data;
    final order = data?.order;
    final ready = !_busy && _note.text.trim().length >= 3;
    final error = Theme.of(context).colorScheme.error;
    String date(DateTime? value) => adminDate(context, value?.toIso8601String());
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
                      if (_busy) const LinearProgressIndicator(),
                      if (_error case final e?)
                        Text(
                          orderIssueErrorText(l, e),
                          key: const ValueKey('order-issue-error'),
                          style: TextStyle(color: error),
                        ),
                      if (_done case final done?) Text(done, key: const ValueKey('order-issue-done')),
                      if (data != null) ...[
                        AdminSection(
                          title: orderIssueKindText(l, data.kind),
                          children: [
                            AdminValue(label: l.orderIssueStatus, value: orderIssueStatusText(l, data.status)),
                            AdminValue(label: l.orderIssueReportedAt, value: date(data.createdAt)),
                            AdminValue(label: l.orderIssueDetail, value: data.detail),
                            AdminValue(label: l.moderationRoleBuyer, value: orderIssuePartyText(data.buyer)),
                            AdminValue(label: l.moderationRoleSeller, value: orderIssuePartyText(data.seller)),
                            if (!data.isOpen) ...[
                              AdminValue(
                                label: l.orderIssueResolvedBy,
                                value: '${realValue(data.resolvedByName)} · ${date(data.resolvedAt)}',
                              ),
                              AdminValue(label: l.orderIssueResolution, value: data.resolutionNote),
                            ],
                          ],
                        ),
                        if (order != null)
                          AdminSection(
                            title: l.moderationOrder,
                            children: [
                              AdminValue(label: l.moderationOrder, value: order.orderNumber, copyable: true),
                              AdminValue(label: l.orderIssueProduct, value: order.productTitle),
                              AdminValue(label: l.orderIssueAmount, value: baht(order.total)),
                              AdminValue(
                                label: l.orderIssuePayment,
                                value: order.paymentMethod == 'mock'
                                    ? l.orderIssuePaymentMock
                                    : realValue(order.paymentMethod == 'wallet' ? 'KaoSure Wallet' : null),
                              ),
                              AdminValue(label: l.orderIssueEscrow, value: _escrowText(l, order.escrowStatus)),
                              AdminValue(
                                label: l.orderIssueShipping,
                                value: [
                                  realValue(order.carrier),
                                  if (order.trackingNumber case final tracking? when tracking.isNotEmpty) tracking,
                                  date(order.shippedAt),
                                ].join(' · '),
                              ),
                            ],
                          ),
                        if (data.events.isNotEmpty)
                          AdminSection(
                            title: l.orderIssueEvents,
                            children: [
                              for (final event in data.events)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  leading: const Icon(Icons.history, size: 18),
                                  title: Text(realValue(event.note ?? event.event)),
                                  subtitle: Text(date(event.createdAt)),
                                ),
                            ],
                          ),
                        if (data.history.isNotEmpty)
                          AdminSection(
                            title: l.orderIssueHistory,
                            children: [
                              for (final earlier in data.history)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  title: Text(
                                    '${orderIssueKindText(l, earlier.kind)} · ${orderIssueStatusText(l, earlier.status)}',
                                  ),
                                  subtitle: Text(
                                    [
                                      if (earlier.detail case final detail? when detail.isNotEmpty) detail,
                                      if (earlier.resolutionNote case final note? when note.isNotEmpty) note,
                                      date(earlier.createdAt),
                                    ].join('\n'),
                                  ),
                                ),
                            ],
                          ),
                        if (data.decidable)
                          AdminSection(
                            title: l.orderIssueDecide,
                            children: [
                              TextField(
                                key: const ValueKey('order-issue-note'),
                                controller: _note,
                                enabled: !_busy,
                                maxLength: 500,
                                maxLines: 3,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  labelText: l.orderIssueNote,
                                  helperText: l.orderIssueNoteHelp,
                                  helperMaxLines: 2,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  FilledButton.icon(
                                    key: const ValueKey('order-issue-refund'),
                                    style: FilledButton.styleFrom(backgroundColor: error),
                                    onPressed: ready ? () => _decide(OrderIssueDecision.refund) : null,
                                    icon: const Icon(Icons.undo_rounded),
                                    label: Text(l.orderIssueRefund),
                                  ),
                                  FilledButton.icon(
                                    key: const ValueKey('order-issue-release'),
                                    onPressed: ready ? () => _decide(OrderIssueDecision.release) : null,
                                    icon: const Icon(Icons.payments_outlined),
                                    label: Text(l.orderIssueRelease),
                                  ),
                                  OutlinedButton.icon(
                                    key: const ValueKey('order-issue-dismiss'),
                                    onPressed: ready ? () => _decide(OrderIssueDecision.dismiss) : null,
                                    icon: const Icon(Icons.local_shipping_outlined),
                                    label: Text(l.orderIssueDismiss),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          Text(l.orderIssueClosedNote, key: const ValueKey('order-issue-closed')),
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

String _decisionText(AppLocalizations l, OrderIssueDecision decision) => switch (decision) {
  OrderIssueDecision.refund => l.orderIssueRefund,
  OrderIssueDecision.release => l.orderIssueRelease,
  OrderIssueDecision.dismiss => l.orderIssueDismiss,
};

String _escrowText(AppLocalizations l, String? status) => switch (status) {
  'holding' => l.orderIssueEscrowHolding,
  'disputed' => l.orderIssueEscrowDisputed,
  'released' => l.orderIssueEscrowReleased,
  'refunded' => l.orderIssueEscrowRefunded,
  _ => realValue(status),
};
