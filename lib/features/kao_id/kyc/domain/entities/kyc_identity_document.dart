import 'package:equatable/equatable.dart';

final class KycIdentityDocument extends Equatable {
  const KycIdentityDocument({
    required this.id,
    required this.ownerId,
    required this.documentType,
    required this.documentNumber,
    required this.status,
    required this.issuedDate,
    required this.expiryDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String documentType;
  final String documentNumber;
  final String status;
  final DateTime? issuedDate;
  final DateTime? expiryDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        ownerId,
        documentType,
        documentNumber,
        status,
        issuedDate,
        expiryDate,
        createdAt,
        updatedAt,
      ];
}
