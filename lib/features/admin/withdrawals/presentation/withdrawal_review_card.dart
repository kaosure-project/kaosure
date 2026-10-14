import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_finance_service.dart';

class WithdrawalReviewCard extends ConsumerWidget {
  const WithdrawalReviewCard({
    super.key,
    required this.item,
    required this.onApprove,
    required this.onPay,
  });

  final Json item;
  final VoidCallback onApprove;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReview = item['lane'] == 'review';
    final canApprove = item['can_approve'] == true;
    final canPay = item['can_pay'] == true;
    final flags = (item['risk_flags'] as List? ?? const [])
        .map((e) => e.toString())
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ยอดถอน ฿${item['amount'] ?? '-'}'),
            const SizedBox(height: 6),
            Chip(
              label: Text(
                isReview ? 'รอตรวจสอบ · review' : 'ช่องทาง auto',
              ),
            ),
            if (flags.isNotEmpty)
              Text('เหตุผลเข้าตรวจ: ${flags.join(', ')}'),
            if (item['approved_by_name'] != null)
              Text('อนุมัติโดย: ${item['approved_by_name']}'),
            if (item['pay_after'] != null)
              Text('เริ่มจ่ายได้หลัง: ${item['pay_after']}'),
            const SizedBox(height: 12),
            if (canApprove)
              FilledButton(
                onPressed: onApprove,
                child: const Text('อนุมัติคำขอ'),
              ),
            if (canPay)
              FilledButton.tonal(
                onPressed: onPay,
                child: const Text('บันทึกการโอนเงิน'),
              ),
          ],
        ),
      ),
    );
  }
}