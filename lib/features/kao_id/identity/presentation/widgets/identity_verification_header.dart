import 'package:flutter/material.dart';

import '../../domain/enums/verification_status.dart';
import 'verification_status_chip.dart';

final class IdentityVerificationHeader extends StatelessWidget {
  const IdentityVerificationHeader({
    super.key,
    required this.status,
    this.title = 'ยืนยันตัวตน',
    this.subtitle =
        'ยืนยันตัวตนเพื่อเพิ่มความน่าเชื่อถือและปลดล็อกการใช้งานทั้งหมดของ Kao ID',
  });

  final VerificationStatus status;

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: VerificationStatusChip(
            status: status,
          ),
        ),
      ],
    );
  }
}