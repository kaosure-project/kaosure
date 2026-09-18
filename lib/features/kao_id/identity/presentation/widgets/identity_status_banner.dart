import 'package:flutter/material.dart';

import '../../domain/enums/verification_status.dart';

final class IdentityStatusBanner extends StatelessWidget {
  const IdentityStatusBanner({
    super.key,
    required this.status,
  });

  final VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          _icon(status),
          color: _color(status),
        ),
        title: Text(status.label),
        subtitle: Text(_message(status)),
      ),
    );
  }

  IconData _icon(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.notSubmitted:
        return Icons.assignment_outlined;

      case VerificationStatus.submitted:
        return Icons.upload_file;

      case VerificationStatus.underReview:
        return Icons.hourglass_top;

      case VerificationStatus.additionalInformationRequired:
        return Icons.info_outline;

      case VerificationStatus.approved:
        return Icons.verified_user;

      case VerificationStatus.rejected:
        return Icons.cancel_outlined;

      case VerificationStatus.cancelled:
        return Icons.block;
    }
  }

  Color _color(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.notSubmitted:
        return Colors.grey;

      case VerificationStatus.submitted:
        return Colors.blue;

      case VerificationStatus.underReview:
        return Colors.orange;

      case VerificationStatus.additionalInformationRequired:
        return Colors.amber;

      case VerificationStatus.approved:
        return Colors.green;

      case VerificationStatus.rejected:
        return Colors.red;

      case VerificationStatus.cancelled:
        return Colors.black54;
    }
  }

  String _message(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.notSubmitted:
        return 'กรุณาอัปโหลดเอกสารเพื่อเริ่มการยืนยันตัวตน';

      case VerificationStatus.submitted:
        return 'ระบบได้รับเอกสารแล้ว กรุณารอการตรวจสอบ';

      case VerificationStatus.underReview:
        return 'เจ้าหน้าที่กำลังตรวจสอบเอกสารของคุณ';

      case VerificationStatus.additionalInformationRequired:
        return 'กรุณาส่งข้อมูลหรือเอกสารเพิ่มเติม';

      case VerificationStatus.approved:
        return 'บัญชีของคุณผ่านการยืนยันตัวตนเรียบร้อยแล้ว';

      case VerificationStatus.rejected:
        return 'การยืนยันตัวตนไม่ผ่าน กรุณาแก้ไขและส่งใหม่';

      case VerificationStatus.cancelled:
        return 'คำขอถูกยกเลิก';
    }
  }
}