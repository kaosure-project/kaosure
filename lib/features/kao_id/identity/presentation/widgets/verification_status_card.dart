import 'package:flutter/material.dart';

import '../../domain/enums/verification_status.dart';

final class VerificationStatusCard extends StatelessWidget {
  const VerificationStatusCard({
    super.key,
    required this.status,
  });

  final VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final IconData icon;
    late final String description;

    switch (status) {
      case VerificationStatus.notSubmitted:
        color = Colors.grey;
        icon = Icons.assignment_outlined;
        description =
            'กรุณาอัปโหลดเอกสารเพื่อเริ่มการยืนยันตัวตน';
        break;

      case VerificationStatus.submitted:
        color = Colors.orange;
        icon = Icons.upload_file_rounded;
        description =
            'ระบบได้รับเอกสารของคุณแล้ว';
        break;

      case VerificationStatus.underReview:
        color = Colors.amber;
        icon = Icons.hourglass_top_rounded;
        description =
            'เจ้าหน้าที่กำลังตรวจสอบเอกสาร';
        break;

      case VerificationStatus.additionalInformationRequired:
        color = Colors.deepOrange;
        icon = Icons.info_outline_rounded;
        description =
            'กรุณาส่งข้อมูลเพิ่มเติม';
        break;

      case VerificationStatus.approved:
        color = Colors.green;
        icon = Icons.verified_rounded;
        description =
            'ยืนยันตัวตนเรียบร้อยแล้ว';
        break;

      case VerificationStatus.rejected:
        color = Colors.red;
        icon = Icons.cancel_rounded;
        description =
            'กรุณาตรวจสอบข้อมูลและส่งใหม่';
        break;

      case VerificationStatus.cancelled:
        color = Colors.grey;
        icon = Icons.block_rounded;
        description =
            'คำขอถูกยกเลิก';
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    status.label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}