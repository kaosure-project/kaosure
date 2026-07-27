import 'package:equatable/equatable.dart';

import '../enums/verification_status.dart';

/// Entity สำหรับบันทึกประวัติการตรวจสอบเอกสาร
///
/// ใช้เก็บ Timeline ของการตรวจสอบแต่ละครั้ง
final class VerificationLog extends Equatable {
  const VerificationLog({
    required this.id,
    required this.status,
    required this.action,
    required this.createdAt,
    this.comment,
    this.reviewedBy,
  });

  /// รหัส Log
  final String id;

  /// สถานะหลังจากดำเนินการ
  final VerificationStatus status;

  /// การดำเนินการ เช่น submit, approve, reject
  final String action;

  /// หมายเหตุ
  final String? comment;

  /// ผู้ดำเนินการ
  final String? reviewedBy;

  /// วันที่สร้าง Log
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        status,
        action,
        comment,
        reviewedBy,
        createdAt,
      ];

  VerificationLog copyWith({
    String? id,
    VerificationStatus? status,
    String? action,
    String? comment,
    String? reviewedBy,
    DateTime? createdAt,
  }) {
    return VerificationLog(
      id: id ?? this.id,
      status: status ?? this.status,
      action: action ?? this.action,
      comment: comment ?? this.comment,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}