import 'package:flutter/material.dart';

final class IdentityGuidelineCard extends StatelessWidget {
  const IdentityGuidelineCard({
    super.key,
    this.guidelines = const [
      'ใช้เอกสารตัวจริงที่ยังไม่หมดอายุ',
      'ถ่ายภาพให้คมชัด เห็นข้อมูลครบถ้วน',
      'หลีกเลี่ยงแสงสะท้อนและเงาบดบัง',
      'ข้อมูลในเอกสารต้องตรงกับบัญชีผู้ใช้',
    ],
  });

  final List<String> guidelines;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'คำแนะนำในการอัปโหลดเอกสาร',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...guidelines.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(item),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}