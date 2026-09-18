import 'package:flutter/material.dart';

final class IdentityVerificationCancelledCard
    extends StatelessWidget {
  const IdentityVerificationCancelledCard({
    super.key,
    this.reason,
    this.onRestart,
  });

  final String? reason;
  final VoidCallback? onRestart;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.block,
              size: 72,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'คำขอถูกยกเลิก',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'คำขอยืนยันตัวตนนี้ถูกยกเลิก หากต้องการใช้งานต่อ กรุณาเริ่มกระบวนการใหม่',
              textAlign: TextAlign.center,
            ),
            if (reason != null) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(reason!),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.restart_alt),
                label: const Text(
                  'เริ่มการยืนยันตัวตนใหม่',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}