import 'package:flutter/material.dart';

final class IdentityVerificationRejectedCard extends StatelessWidget {
  const IdentityVerificationRejectedCard({
    super.key,
    this.reason,
    this.onResubmit,
  });

  final String? reason;
  final VoidCallback? onResubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.cancel_outlined,
              size: 72,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'การยืนยันตัวตนไม่ผ่าน',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'กรุณาตรวจสอบข้อมูล แก้ไขเอกสาร และส่งคำขอใหม่',
              textAlign: TextAlign.center,
            ),
            if (reason != null) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  reason!,
                  style: const TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onResubmit,
                icon: const Icon(Icons.refresh),
                label: const Text('ส่งเอกสารใหม่'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}