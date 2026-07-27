import '../../domain/entities/session.dart';

final class SessionModel {
  const SessionModel({
    required this.id,
    required this.ownerId,
    required this.deviceId,
    required this.accessToken,
    required this.refreshToken,
    required this.ipAddress,
    required this.userAgent,
    required this.isActive,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String deviceId;
  final String accessToken;
  final String refreshToken;
  final String ipAddress;
  final String userAgent;
  final bool isActive;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      deviceId: json['device_id'] as String,
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      ipAddress: json['ip_address'] as String,
      userAgent: json['user_agent'] as String,
      isActive: json['is_active'] as bool,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'device_id': deviceId,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'is_active': isActive,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Session toEntity() {
    return Session(
      id: id,
      ownerId: ownerId,
      deviceId: deviceId,
      accessToken: accessToken,
      refreshToken: refreshToken,
      ipAddress: ipAddress,
      userAgent: userAgent,
      isActive: isActive,
      expiresAt: expiresAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory SessionModel.fromEntity(Session entity) {
    return SessionModel(
      id: entity.id,
      ownerId: entity.ownerId,
      deviceId: entity.deviceId,
      accessToken: entity.accessToken,
      refreshToken: entity.refreshToken,
      ipAddress: entity.ipAddress,
      userAgent: entity.userAgent,
      isActive: entity.isActive,
      expiresAt: entity.expiresAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}