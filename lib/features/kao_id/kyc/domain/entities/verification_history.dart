import 'package:equatable/equatable.dart';

final class VerificationHistory extends Equatable {
  const VerificationHistory({
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

  /// identity_documents.id
  final String? documentId;

  /// email
  /// phone
  /// identity_card
  /// passport
  /// residence_permit
  /// bank
  final String type;

  /// pending
  /// approved
  /// rejected
  /// expired
  final String status;

  final String description;

  final String? createdBy;

  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        profileId,
        documentId,
        type,
        status,
        description,
        createdBy,
        createdAt,
      ];

  VerificationHistory copyWith({
    String? id,
    String? profileId,
    String? documentId,
    String? type,
    String? status,
    String? description,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return VerificationHistory(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      documentId: documentId ?? this.documentId,
      type: type ?? this.type,
      status: status ?? this.status,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}