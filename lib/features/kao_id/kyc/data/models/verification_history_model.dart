import '../../domain/entities/verification_history.dart';

final class VerificationHistoryModel {
  const VerificationHistoryModel({
    required this.id,
    required this.verificationRequestId,
    required this.action,
    required this.oldStatus,
    required this.newStatus,
    required this.performedBy,
    required this.notes,
    required this.createdAt,
  });

  final String id;
  final String verificationRequestId;
  final String action;
  final String? oldStatus;
  final String? newStatus;
  final String? performedBy;
  final String? notes;
  final DateTime createdAt;

  factory VerificationHistoryModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return VerificationHistoryModel(
      id: json['id'] as String,
      verificationRequestId:
          json['verification_request_id']
              as String,
      action: json['action'] as String,
      oldStatus:
          json['old_status'] as String?,
      newStatus:
          json['new_status'] as String?,
      performedBy:
          json['performed_by'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(
        json['created_at'] as String,
      ),
    );
  }

  VerificationHistory toEntity() {
    return VerificationHistory(
      id: id,
      verificationRequestId:
          verificationRequestId,
      action: action,
      oldStatus: oldStatus,
      newStatus: newStatus,
      performedBy: performedBy,
      notes: notes,
      createdAt: createdAt,
    );
  }
}
