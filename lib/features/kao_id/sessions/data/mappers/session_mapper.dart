import '../../domain/entities/session.dart';
import '../models/session_model.dart';

extension SessionModelMapper on SessionModel {
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
}

extension SessionEntityMapper on Session {
  SessionModel toModel() {
    return SessionModel(
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
}