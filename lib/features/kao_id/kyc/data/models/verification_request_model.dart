import '../../domain/entities/verification_request.dart';

final class VerificationRequestModel {
  const VerificationRequestModel({
    required this.id,
    required this.requestedBy,
    required this.status,
    required this.reviewedAt,
    required this.reviewedBy,
    required this.rejectionReason,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String requestedBy;
  final String status;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory VerificationRequestModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return VerificationRequestModel(
      id: json['id'] as String,
      requestedBy: json['requested_by'] as String,
      status: json['status'] as String,
      reviewedAt: _parseDateTime(
        json['reviewed_at'],
      ),
      reviewedBy: json['reviewed_by'] as String?,
      rejectionReason:
          json['rejection_reason'] as String?,
      notes: json['notes'] as String?,
      createdAt: _parseRequiredDateTime(
        json['created_at'],
      ),
      updatedAt: _parseRequiredDateTime(
        json['updated_at'],
      ),
    );
  }

  VerificationRequest toEntity() {
    return VerificationRequest(
      id: id,
      requestedBy: requestedBy,
      status: status,
      reviewedAt: reviewedAt,
      reviewedBy: reviewedBy,
      rejectionReason: rejectionReason,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _parseDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.parse(
      value.toString(),
    );
  }

  static DateTime _parseRequiredDateTime(
    dynamic value,
  ) {
    if (value is DateTime) {
      return value;
    }

    return DateTime.parse(
      value.toString(),
    );
  }
}