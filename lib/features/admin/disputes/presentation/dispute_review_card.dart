import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../withdrawals/data/admin_finance_service.dart';

class DisputeReviewCard extends ConsumerWidget {
  const DisputeReviewCard({
    super.key,
    required this.item,
    required this.onPropose,
    required this.onConfirm,
  });

  final Json item;
  final VoidCallback onPropose;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposal = item['proposal'] as Map?;
    final canPropose = item['can_propose'] == true;
    final canConfirm = item['can_confirm'] == true;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ออร์เดอร์ ${item['order']?['order_number'] ?? '-'}'),
            const SizedBox(height: 8),
            if (proposal != null) ...[
              Text('Proposal: ${proposal['decision']}'),
              Text('ผู้เสนอ: ${proposal['proposed_by_name'] ?? '-'}'),
              if (proposal['mode'] == 'cooling_off')
                Text('ยืนยันได้หลัง: ${proposal['confirm_after'] ?? '-'}'),
            ] else
              const Text('ยังไม่มี Proposal'),
            const SizedBox(height: 12),
            if (canPropose)
              FilledButton(
                onPressed: onPropose,
                child: const Text('เสนอผล Dispute'),
              ),
            if (canConfirm)
              FilledButton.tonal(
                onPressed: onConfirm,
                child: const Text('ยืนยัน / ส่งกลับ'),
              ),
          ],
        ),
      ),
    );
  }
}