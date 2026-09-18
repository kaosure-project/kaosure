import 'package:flutter/material.dart';

import '../../domain/enums/verification_status.dart';
import 'verification_status_chip.dart';

final class VerificationStatusLegend extends StatelessWidget {
  const VerificationStatusLegend({
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
              'ความหมายของสถานะการยืนยันตัวตน',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...VerificationStatus.values.map(
              (status) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VerificationStatusChip(
                      status: status,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _description(status),
                      ),
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

  String _description(
    VerificationStatus status,
  ) {
    switch (status) {
      case VerificationStatus.notSubmitted:
        return 'ยังไม่ได้ส่งคำขอยืนยันตัวตน';

      case VerificationStatus.submitted:
        return 'ส่งคำขอเรียบร้อย กำลังรอเข้าสู่กระบวนการตรวจสอบ';

      case VerificationStatus.underReview:
        return 'เจ้าหน้าที่กำลังตรวจสอบข้อมูลและเอกสาร';

      case VerificationStatus.additionalInformationRequired:
        return 'ต้องส่งข้อมูลหรือเอกสารเพิ่มเติมก่อนดำเนินการต่อ';

      case VerificationStatus.approved:
        return 'ผ่านการยืนยันตัวตนเรียบร้อยแล้ว';

      case VerificationStatus.rejected:
        return 'ไม่ผ่านการยืนยันตัวตน กรุณาแก้ไขและส่งใหม่';

      case VerificationStatus.cancelled:
        return 'คำขอยืนยันตัวตนถูกยกเลิก';
    }
  }
}