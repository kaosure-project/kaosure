import 'package:flutter/material.dart';

final class IdentityPrivacyNoticeCard extends StatelessWidget {
  const IdentityPrivacyNoticeCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'นโยบายความเป็นส่วนตัว',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            const _PrivacyItem(
              icon: Icons.verified_user_outlined,
              text:
                  'ข้อมูลจะใช้เพื่อยืนยันตัวตนและป้องกันการทุจริตเท่านั้น',
            ),
            const SizedBox(height: 12),
            const _PrivacyItem(
              icon: Icons.lock_outline,
              text:
                  'ข้อมูลส่วนบุคคลได้รับการปกป้องตามมาตรฐานความปลอดภัยของระบบ',
            ),
            const SizedBox(height: 12),
            const _PrivacyItem(
              icon: Icons.person_off_outlined,
              text:
                  'จะไม่มีการเปิดเผยข้อมูลแก่บุคคลภายนอกโดยไม่ได้รับอนุญาต เว้นแต่กฎหมายกำหนด',
            ),
            const SizedBox(height: 12),
            const _PrivacyItem(
              icon: Icons.delete_outline,
              text:
                  'ผู้ใช้สามารถขอแก้ไขหรืออัปเดตข้อมูลได้ตามนโยบายของระบบ',
            ),
          ],
        ),
      ),
    );
  }
}

final class _PrivacyItem extends StatelessWidget {
  const _PrivacyItem({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text),
        ),
      ],
    );
  }
}