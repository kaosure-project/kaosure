import '../../domain/entities/kao_id_identity.dart';

final class KaoIdIdentityModel {
  const KaoIdIdentityModel({
    required this.id,
    required this.profileId,
    required this.kaoId,
    required this.status,
    required this.issuedAt,
  });

  final String id;
  final String profileId;
  final String kaoId;
  final String status;
  final DateTime issuedAt;

  factory KaoIdIdentityModel.fromJson(Map<String, dynamic> json) {
    return KaoIdIdentityModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      kaoId: json['kao_id'] as String,
      status: json['status'] as String,
      issuedAt: DateTime.parse(json['issued_at'] as String),
    );
  }

  KaoIdIdentity toEntity() => KaoIdIdentity(
        id: id,
        profileId: profileId,
        kaoId: kaoId,
        status: status,
        issuedAt: issuedAt,
      );
}
