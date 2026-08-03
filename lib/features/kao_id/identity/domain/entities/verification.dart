import 'package:equatable/equatable.dart';

import '../enums/verification_status.dart';
import 'verification_log.dart';

/// Entity สำหรับข้อมูลการตรวจสอบเอกสาร (KYC)
///
/// หนึ่ง Verification แทนหนึ่งคำขอการตรวจสอบ
final class Verification extends Equatable {
  const Verification({
    required this.id,
    required this.documentId,
    required this.requestedBy,
    required this.status,
    required this.logs,
    required this.createdAt,
    required this.updatedAt,
    this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
    this.notes,
  });

  /// รหัสคำขอการตรวจสอบ
  final String id;

  /// เอกสารที่ส่งมาตรวจ
  final String documentId;

  /// เจ้าของคำขอ
  final String requestedBy;

  /// สถานะการตรวจสอบ
  final VerificationStatus status;

  /// ประวัติการดำเนินการ
  final List<VerificationLog> logs;

  /// วันที่ส่งตรวจ
  final DateTime? submittedAt;

  /// วันที่ตรวจเสร็จ
  final DateTime? reviewedAt;

  /// ผู้ตรวจสอบ
  final String? reviewedBy;

  /// เหตุผลที่ไม่ผ่าน
  final String? rejectionReason;

  /// หมายเหตุเพิ่มเติม
  final String? notes;

  /// วันที่สร้าง
  final DateTime createdAt;

  /// วันที่แก้ไขล่าสุด
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        documentId,
        requestedBy,
        status,
        logs,
        submittedAt,
        reviewedAt,
        reviewedBy,
        rejectionReason,
        notes,
        createdAt,
        updatedAt,
      ];

  Verification copyWith({
    String? id,
    String? documentId,
    String? requestedBy,
    VerificationStatus? status,
    List<VerificationLog>? logs,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Verification(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      requestedBy: requestedBy ?? this.requestedBy,
      status: status ?? this.status,
      logs: logs ?? this.logs,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}