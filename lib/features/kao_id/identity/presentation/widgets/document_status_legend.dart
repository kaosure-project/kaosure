import 'package:flutter/material.dart';

import '../../domain/enums/document_status.dart';
import 'document_status_chip.dart';

final class DocumentStatusLegend extends StatelessWidget {
  const DocumentStatusLegend({
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
              'ความหมายของสถานะเอกสาร',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...DocumentStatus.values.map(
              (status) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DocumentStatusChip(
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

  String _description(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.draft:
        return 'สร้างรายการเอกสารแล้ว แต่ยังไม่ได้อัปโหลดหรือส่งตรวจ';

      case DocumentStatus.uploaded:
        return 'อัปโหลดเอกสารเรียบร้อยแล้ว พร้อมส่งตรวจสอบ';

      case DocumentStatus.pendingReview:
        return 'เจ้าหน้าที่กำลังตรวจสอบเอกสาร';

      case DocumentStatus.approved:
        return 'เอกสารผ่านการตรวจสอบและสามารถใช้งานได้';

      case DocumentStatus.rejected:
        return 'เอกสารถูกปฏิเสธ กรุณาแก้ไขและส่งใหม่';

      case DocumentStatus.expired:
        return 'เอกสารหมดอายุ ต้องอัปโหลดฉบับใหม่';

      case DocumentStatus.suspended:
        return 'เอกสารถูกระงับชั่วคราวโดยระบบหรือผู้ดูแล';

      case DocumentStatus.archived:
        return 'เอกสารถูกเก็บเป็นประวัติและไม่ถูกใช้งานแล้ว';
    }
  }
}