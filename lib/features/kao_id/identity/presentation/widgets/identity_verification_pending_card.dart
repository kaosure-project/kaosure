import 'package:flutter/material.dart';

final class IdentityVerificationPendingCard extends StatelessWidget {
  const IdentityVerificationPendingCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.hourglass_top,
              size: 72,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              'กำลังตรวจสอบเอกสาร',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'ระบบได้รับเอกสารของคุณเรียบร้อยแล้ว กรุณารอเจ้าหน้าที่ตรวจสอบ',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const _StepItem(
              icon: Icons.check_circle_outline,
              text: 'ได้รับเอกสารเรียบร้อย',
            ),
            const SizedBox(height: 12),
            const _StepItem(
              icon: Icons.manage_search,
              text: 'เจ้าหน้าที่กำลังตรวจสอบข้อมูล',
            ),
            const SizedBox(height: 12),
            const _StepItem(
              icon: Icons.notifications_active_outlined,
              text: 'ระบบจะแจ้งผลเมื่อการตรวจสอบเสร็จสิ้น',
            ),
          ],
        ),
      ),
    );
  }
}

final class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text),
        ),
      ],
    );
  }
}