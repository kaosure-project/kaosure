import '../../domain/entities/verification_history.dart';

final class VerificationHistoryModel {
  const VerificationHistoryModel({
    required this.id,
    required this.profileId,
    this.documentId,
    required this.type,
    required this.status,
    required this.description,
    this.createdBy,
    required this.createdAt,
  });

  final String id;

  final String profileId;

  final String? documentId;

  final String type;

  final String status;

  final String description;

  final String? createdBy;

  final DateTime createdAt;

  factory VerificationHistoryModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return VerificationHistoryModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      documentId: json['document_id'] as String?,
      type: json['type'] as String,
      status: json['status'] as String,
      description: json['description'] as String,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(
        json['created_at'] as String,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'document_id': documentId,
      'type': type,
      'status': status,
      'description': description,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  VerificationHistory toEntity() {
    return VerificationHistory(
      id: id,
      profileId: profileId,
      documentId: documentId,
      type: type,
      status: status,
      description: description,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }

  factory VerificationHistoryModel.fromEntity(
    VerificationHistory entity,
  ) {
    return VerificationHistoryModel(
      id: entity.id,
      profileId: entity.profileId,
      documentId: entity.documentId,
      type: entity.type,
      status: entity.status,
      description: entity.description,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
    );
  }
}