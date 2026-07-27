import '../../domain/entities/session.dart';
import '../models/session_model.dart';

extension SessionModelMapper on SessionModel {
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
}

extension SessionEntityMapper on Session {
  SessionModel toModel() {
    return SessionModel(
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
}