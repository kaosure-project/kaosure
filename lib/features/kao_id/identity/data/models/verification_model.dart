import '../../domain/entities/verification.dart';
import '../../domain/entities/verification_log.dart';
import '../../domain/enums/verification_status.dart';

final class VerificationModel {
  const VerificationModel({
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

  final String id;
  final String documentId;
  final String requestedBy;
  final VerificationStatus status;
  final List<VerificationLog> logs;

  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;
  final String? notes;

  final DateTime createdAt;
  final DateTime updatedAt;

  factory VerificationModel.fromMap(
    Map<String, dynamic> map, {
    List<VerificationLog> logs = const [],
  }) {
    return VerificationModel(
      id: map['id'] as String,
      documentId: map['document_id'] as String,
      requestedBy: map['requested_by'] as String,
      status: VerificationStatusExtension.fromValue(
        map['status'] as String,
      ),
      logs: logs,
      submittedAt: map['submitted_at'] == null
          ? null
          : DateTime.parse(map['submitted_at'] as String),
      reviewedAt: map['reviewed_at'] == null
          ? null
          : DateTime.parse(map['reviewed_at'] as String),
      reviewedBy: map['reviewed_by'] as String?,
      rejectionReason: map['rejection_reason'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  factory VerificationModel.fromEntity(
    Verification entity,
  ) {
    return VerificationModel(
      id: entity.id,
      documentId: entity.documentId,
      requestedBy: entity.requestedBy,
      status: entity.status,
      logs: entity.logs,
      submittedAt: entity.submittedAt,
      reviewedAt: entity.reviewedAt,
      reviewedBy: entity.reviewedBy,
      rejectionReason: entity.rejectionReason,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Verification toEntity() {
    return Verification(
      id: id,
      documentId: documentId,
      requestedBy: requestedBy,
      status: status,
      logs: logs,
      submittedAt: submittedAt,
      reviewedAt: reviewedAt,
      reviewedBy: reviewedBy,
      rejectionReason: rejectionReason,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_id': documentId,
      'requested_by': requestedBy,
      'status': status.value,
      'submitted_at': submittedAt?.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'reviewed_by': reviewedBy,
      'rejection_reason': rejectionReason,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}