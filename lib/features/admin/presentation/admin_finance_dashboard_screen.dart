import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../disputes/presentation/dispute_review_card.dart';
import '../withdrawals/application/admin_finance_providers.dart';
import '../withdrawals/presentation/withdrawal_review_card.dart';

class AdminFinanceDashboardScreen extends ConsumerStatefulWidget {
  const AdminFinanceDashboardScreen({super.key});

  @override
  ConsumerState<AdminFinanceDashboardScreen> createState() =>
      _AdminFinanceDashboardScreenState();
}

class _AdminFinanceDashboardScreenState
    extends ConsumerState<AdminFinanceDashboardScreen> {
  void _refreshQueues() {
    ref.invalidate(staffToolsProvider);
    ref.invalidate(disputeQueueProvider);
    ref.invalidate(pendingWithdrawalsProvider);
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _proposeDispute(String issueId) async {
    final decision = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('เลือกข้อเสนอสำหรับ Dispute'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, 'refund'),
            child: const Text('เสนอคืนเงิน'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, 'release'),
            child: const Text('เสนอปล่อยเงินให้ผู้ขาย'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, 'dismiss'),
            child: const Text('เสนอปิดเรื่อง'),
          ),
        ],
      ),
    );

    if (decision == null) return;

    final note = await _askText(
      title: 'บันทึกเหตุผลของข้อเสนอ',
      label: 'เหตุผล',
      requiredField: true,
      multiline: true,
    );

    if (note == null) return;

    await _runAction(
      () => ref.read(adminFinanceServiceProvider).proposeDispute(
            issueId: issueId,
            decision: decision,
            note: note,
          ),
      successMessage: 'บันทึกข้อเสนอแล้ว',
    );
  }

  Future<void> _confirmDispute(String issueId) async {
    final approve = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ยืนยันข้อเสนอ Dispute'),
        content: const Text('ตรวจสอบรายละเอียดก่อนยืนยันการดำเนินการ'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ส่งกลับ / ไม่อนุมัติ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );

    if (approve == null) return;

    final reason = approve
        ? null
        : await _askText(
            title: 'ระบุเหตุผลที่ส่งกลับ',
            label: 'เหตุผล',
            requiredField: true,
            multiline: true,
          );

    if (!approve && reason == null) return;

    await _runAction(
      () => ref.read(adminFinanceServiceProvider).confirmDispute(
            issueId: issueId,
            approve: approve,
            reason: reason,
          ),
      successMessage: approve ? 'ยืนยัน Dispute แล้ว' : 'ส่ง Dispute กลับแล้ว',
    );
  }

  Future<void> _approveWithdrawal(String withdrawalId) async {
    final confirmed = await _confirm(
      title: 'อนุมัติคำขอถอนเงิน?',
      message: 'การอนุมัตินี้เป็นขั้นตอนแรกของการจ่ายเงิน',
      confirmLabel: 'อนุมัติ',
    );

    if (confirmed != true) return;

    await _runAction(
      () => ref
          .read(adminFinanceServiceProvider)
          .approveWithdrawal(requestId: withdrawalId),
      successMessage: 'อนุมัติคำขอถอนเงินแล้ว',
    );
  }

  Future<void> _payWithdrawal(String withdrawalId) async {
    final reference = await _askText(
      title: 'ยืนยันการจ่ายเงิน',
      label: 'เลขอ้างอิงการโอน',
      requiredField: true,
    );

    if (reference == null) return;

    await _runAction(
      () => ref.read(adminFinanceServiceProvider).payWithdrawal(
            requestId: withdrawalId,
            transferReference: reference,
          ),
      successMessage: 'บันทึกการจ่ายเงินแล้ว',
    );
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    try {
      await action();
      if (!mounted) return;
      _showMessage(successMessage);
      _refreshQueues();
    } catch (error) {
      if (!mounted) return;
      _showMessage('ทำรายการไม่สำเร็จ: $error');
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  Future<String?> _askText({
    required String title,
    required String label,
    bool requiredField = false,
    bool multiline = false,
  }) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            minLines: multiline ? 3 : 1,
            maxLines: multiline ? 5 : 1,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (requiredField && text.isEmpty) {
                return 'กรุณากรอกข้อมูล';
              }
              if (requiredField && text.length < 3) {
                return 'กรุณากรอกอย่างน้อย 3 ตัวอักษร';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(dialogContext, controller.text.trim());
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final toolsAsync = ref.watch(staffToolsProvider);

    return toolsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Admin Finance')),
        body: _ErrorView(
          message: 'โหลดสิทธิ์เจ้าหน้าที่ไม่สำเร็จ: $error',
          onRetry: _refreshQueues,
        ),
      ),
      data: (tools) {
        final canReviewDisputes = tools?['order_issues'] == true;
        final canReviewWithdrawals = tools?['withdrawals'] == true;

        final tabs = <_DashboardTab>[
          if (canReviewDisputes)
            _DashboardTab(
              title: 'Disputes',
              icon: Icons.gavel_outlined,
              page: _queue<Map<String, dynamic>>(
                state: ref.watch(disputeQueueProvider),
                onRefresh: _refreshQueues,
                emptyMessage: 'ไม่มี Dispute ที่รอตรวจสอบ',
                itemBuilder: (item) {
                  final issueId =
                      (item['issue_id'] ?? item['id']).toString();

                  return DisputeReviewCard(
                    item: item,
                    onPropose: () => _proposeDispute(issueId),
                    onConfirm: () => _confirmDispute(issueId),
                  );
                },
              ),
            ),
          if (canReviewWithdrawals)
            _DashboardTab(
              title: 'Withdrawals',
              icon: Icons.account_balance_wallet_outlined,
              page: _queue<Map<String, dynamic>>(
                state: ref.watch(pendingWithdrawalsProvider),
                onRefresh: _refreshQueues,
                emptyMessage: 'ไม่มีคำขอถอนเงินที่รอตรวจสอบ',
                itemBuilder: (item) {
                  final withdrawalId =
                      (item['id'] ?? item['withdrawal_id']).toString();

                  return WithdrawalReviewCard(
                    item: item,
                    onApprove: () => _approveWithdrawal(withdrawalId),
                    onPay: () => _payWithdrawal(withdrawalId),
                  );
                },
              ),
            ),
        ];

        if (tabs.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Admin Finance')),
            body: const Center(
              child: Text('บัญชีนี้ไม่มีสิทธิ์เข้าถึงงานการเงิน'),
            ),
          );
        }

        return DefaultTabController(
          length: tabs.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Admin Finance'),
              actions: [
                IconButton(
                  tooltip: 'โหลดข้อมูลใหม่',
                  onPressed: _refreshQueues,
                  icon: const Icon(Icons.refresh),
                ),
              ],
              bottom: TabBar(
                tabs: [
                  for (final tab in tabs)
                    Tab(icon: Icon(tab.icon), text: tab.title),
                ],
              ),
            ),
            body: TabBarView(
              children: [for (final tab in tabs) tab.page],
            ),
          ),
        );
      },
    );
  }

  Widget _queue<T>({
    required AsyncValue<List<T>> state,
    required VoidCallback onRefresh,
    required String emptyMessage,
    required Widget Function(T item) itemBuilder,
  }) {
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
        message: 'โหลดรายการไม่สำเร็จ: $error',
        onRetry: onRefresh,
      ),
      data: (items) {
        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => onRefresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 140),
                Center(child: Text(emptyMessage)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, index) => itemBuilder(items[index]),
          ),
        );
      },
    );
  }
}

class _DashboardTab {
  const _DashboardTab({
    required this.title,
    required this.icon,
    required this.page,
  });

  final String title;
  final IconData icon;
  final Widget page;
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองอีกครั้ง'),
            ),
          ],
        ),
      ),
    );
  }
}