import 'package:flutter/material.dart';

final class IdentityVerificationCompletedCard extends StatelessWidget {
  const IdentityVerificationCompletedCard({
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
              Icons.verified,
              size: 72,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'ยืนยันตัวตนสำเร็จ',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'บัญชีของคุณได้รับการยืนยันตัวตนเรียบร้อยแล้ว',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            const _BenefitItem(
              icon: Icons.storefront_outlined,
              text: 'สามารถใช้งานฟีเจอร์ที่ต้องยืนยันตัวตนได้',
            ),
            const SizedBox(height: 12),
            const _BenefitItem(
              icon: Icons.security_outlined,
              text: 'เพิ่มความน่าเชื่อถือให้บัญชีของคุณ',
            ),
            const SizedBox(height: 12),
            const _BenefitItem(
              icon: Icons.payments_outlined,
              text: 'พร้อมใช้งานบริการที่เกี่ยวข้องกับการชำระเงิน',
            ),
          ],
        ),
      ),
    );
  }
}

final class _BenefitItem extends StatelessWidget {
  const _BenefitItem({
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