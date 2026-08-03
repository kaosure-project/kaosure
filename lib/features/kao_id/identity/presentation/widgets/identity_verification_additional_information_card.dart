import 'package:flutter/material.dart';

final class IdentityVerificationAdditionalInformationCard
    extends StatelessWidget {
  const IdentityVerificationAdditionalInformationCard({
    super.key,
    this.reason,
    this.onUpload,
  });

  final String? reason;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.info_outline,
              size: 72,
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            Text(
              'ต้องการข้อมูลเพิ่มเติม',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'เจ้าหน้าที่ต้องการข้อมูลหรือเอกสารเพิ่มเติมเพื่อดำเนินการยืนยันตัวตน',
              textAlign: TextAlign.center,
            ),
            if (reason != null) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(reason!),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onUpload,
                icon: const Icon(Icons.upload_file),
                label: const Text('อัปโหลดข้อมูลเพิ่มเติม'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}