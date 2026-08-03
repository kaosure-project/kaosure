import 'package:flutter/material.dart';

final class IdentitySecurityNoticeCard extends StatelessWidget {
  const IdentitySecurityNoticeCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'ความปลอดภัยของข้อมูล',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(height: 16),
            const _Item(
              icon: Icons.lock_outline,
              text:
                  'ข้อมูลและเอกสารของคุณถูกจัดเก็บอย่างปลอดภัย',
            ),
            const SizedBox(height: 12),
            const _Item(
              icon: Icons.verified_user_outlined,
              text:
                  'ใช้เพื่อการยืนยันตัวตนตามวัตถุประสงค์ของระบบเท่านั้น',
            ),
            const SizedBox(height: 12),
            const _Item(
              icon: Icons.visibility_off_outlined,
              text:
                  'ห้ามส่งรหัสผ่านหรือข้อมูลสำคัญผ่านช่องแชท',
            ),
            const SizedBox(height: 12),
            const _Item(
              icon: Icons.shield_outlined,
              text:
                  'โปรดตรวจสอบความถูกต้องของเอกสารก่อนส่งทุกครั้ง',
            ),
          ],
        ),
      ),
    );
  }
}

final class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
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