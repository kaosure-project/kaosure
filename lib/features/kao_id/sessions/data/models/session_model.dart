import '../../domain/entities/session.dart';

final class SessionModel {
  const SessionModel({
    required this.id,
    required this.ownerId,
    required this.deviceId,
    required this.accessTokenHash,
    required this.refreshTokenHash,
    required this.tokenType,
    required this.platform,
    required this.ipAddress,
    required this.userAgent,
    required this.country,
    required this.city,
    required this.lastActivityAt,
    required this.expiresAt,
    required this.revokedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String? deviceId;
  final String accessTokenHash;
  final String? refreshTokenHash;
  final String tokenType;
  final String platform;
  final String? ipAddress;
  final String? userAgent;
  final String? country;
  final String? city;
  final DateTime lastActivityAt;
  final DateTime expiresAt;
  final DateTime? revokedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SessionModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return SessionModel(
      id: json['id'] as String,
      ownerId: json['profile_id'] as String,
      deviceId: json['device_id'] as String?,
      accessTokenHash:
          json['access_token_hash'] as String,
      refreshTokenHash:
          json['refresh_token_hash'] as String?,
      tokenType: json['token_type'] as String,
      platform: json['platform'] as String,
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      country: json['country'] as String?,
      city: json['city'] as String?,
      lastActivityAt:
          DateTime.parse(
        json['last_activity_at'] as String,
      ),
      expiresAt:
          DateTime.parse(
        json['expires_at'] as String,
      ),
      revokedAt: json['revoked_at'] == null
          ? null
          : DateTime.parse(
              json['revoked_at'] as String,
            ),
      createdAt:
          DateTime.parse(
        json['created_at'] as String,
      ),
      updatedAt:
          DateTime.parse(
        json['updated_at'] as String,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': ownerId,
      'device_id': deviceId,
      'access_token_hash': accessTokenHash,
      'refresh_token_hash': refreshTokenHash,
      'token_type': tokenType,
      'platform': platform,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'country': country,
      'city': city,
      'last_activity_at':
          lastActivityAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'revoked_at':
          revokedAt?.toIso8601String(),
      'created_at':
          createdAt.toIso8601String(),
      'updated_at':
          updatedAt.toIso8601String(),
    };
  }

  Session toEntity() {
    return Session(
      id: id,
      ownerId: ownerId,
      deviceId: deviceId,
      accessTokenHash: accessTokenHash,
      refreshTokenHash: refreshTokenHash,
      tokenType: tokenType,
      platform: platform,
      ipAddress: ipAddress,
      userAgent: userAgent,
      country: country,
      city: city,
      lastActivityAt: lastActivityAt,
      expiresAt: expiresAt,
      revokedAt: revokedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory SessionModel.fromEntity(
    Session entity,
  ) {
    return SessionModel(
      id: entity.id,
      ownerId: entity.ownerId,
      deviceId: entity.deviceId,
      accessTokenHash:
          entity.accessTokenHash,
      refreshTokenHash:
          entity.refreshTokenHash,
      tokenType: entity.tokenType,
      platform: entity.platform,
      ipAddress: entity.ipAddress,
      userAgent: entity.userAgent,
      country: entity.country,
      city: entity.city,
      lastActivityAt:
          entity.lastActivityAt,
      expiresAt: entity.expiresAt,
      revokedAt: entity.revokedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}