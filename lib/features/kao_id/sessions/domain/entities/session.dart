import 'package:equatable/equatable.dart';

final class Session extends Equatable {
  const Session({
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

  bool get isActive {
    return revokedAt == null &&
        expiresAt.isAfter(DateTime.now());
  }

  Session copyWith({
    String? id,
    String? ownerId,
    String? deviceId,
    String? accessTokenHash,
    String? refreshTokenHash,
    String? tokenType,
    String? platform,
    String? ipAddress,
    String? userAgent,
    String? country,
    String? city,
    DateTime? lastActivityAt,
    DateTime? expiresAt,
    DateTime? revokedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Session(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      deviceId: deviceId ?? this.deviceId,
      accessTokenHash:
          accessTokenHash ?? this.accessTokenHash,
      refreshTokenHash:
          refreshTokenHash ?? this.refreshTokenHash,
      tokenType: tokenType ?? this.tokenType,
      platform: platform ?? this.platform,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      country: country ?? this.country,
      city: city ?? this.city,
      lastActivityAt:
          lastActivityAt ?? this.lastActivityAt,
      expiresAt: expiresAt ?? this.expiresAt,
      revokedAt: revokedAt ?? this.revokedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ownerId,
        deviceId,
        accessTokenHash,
        refreshTokenHash,
        tokenType,
        platform,
        ipAddress,
        userAgent,
        country,
        city,
        lastActivityAt,
        expiresAt,
        revokedAt,
        createdAt,
        updatedAt,
      ];
}