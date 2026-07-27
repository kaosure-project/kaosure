import 'package:equatable/equatable.dart';

import '../enums/verification_status.dart';
import 'verification_log.dart';

/// Entity สำหรับข้อมูลการตรวจสอบเอกสาร
///
/// หนึ่ง Verification แทนหนึ่งกระบวนการตรวจสอบ
final class Verification extends Equatable {
  const Verification({
    required this.id,
    required this.status,
    required this.logs,
    this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  /// รหัสการตรวจสอบ
  final String id;

  /// สถานะการตรวจสอบ
  final VerificationStatus status;

  /// ประวัติการตรวจสอบ
  final List<VerificationLog> logs;

  /// วันที่ส่งตรวจ
  final DateTime? submittedAt;

  /// วันที่ตรวจเสร็จ
  final DateTime? reviewedAt;

  /// ผู้ตรวจสอบ
  final String? reviewedBy;

  /// เหตุผลที่ไม่ผ่าน
  final String? rejectionReason;

  @override
  List<Object?> get props => [
        id,
        status,
        logs,
        submittedAt,
        reviewedAt,
        reviewedBy,
        rejectionReason,
      ];

  Verification copyWith({
    String? id,
    VerificationStatus? status,
    List<VerificationLog>? logs,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
  }) {
    return Verification(
      id: id ?? this.id,
      status: status ?? this.status,
      logs: logs ?? this.logs,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}