import 'package:equatable/equatable.dart';

final class Session extends Equatable {
  const Session({
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

  @override
  List<Object?> get props => [
        id,
        ownerId,
        deviceId,
        accessToken,
        refreshToken,
        ipAddress,
        userAgent,
        isActive,
        expiresAt,
        createdAt,
        updatedAt,
      ];

  Session copyWith({
    String? id,
    String? ownerId,
    String? deviceId,
    String? accessToken,
    String? refreshToken,
    String? ipAddress,
    String? userAgent,
    bool? isActive,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Session(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      deviceId: deviceId ?? this.deviceId,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}