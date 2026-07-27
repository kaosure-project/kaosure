import '../../domain/entities/device.dart';

final class DeviceModel {
  const DeviceModel({
    required this.id,
    required this.ownerId,
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.osVersion,
    required this.appVersion,
    required this.isTrusted,
    required this.lastSeenAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String deviceId;
  final String deviceName;
  final String platform;
  final String osVersion;
  final String appVersion;
  final bool isTrusted;
  final DateTime lastSeenAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      deviceId: json['device_id'] as String,
      deviceName: json['device_name'] as String,
      platform: json['platform'] as String,
      osVersion: json['os_version'] as String,
      appVersion: json['app_version'] as String,
      isTrusted: json['is_trusted'] as bool,
      lastSeenAt: DateTime.parse(json['last_seen_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'device_id': deviceId,
      'device_name': deviceName,
      'platform': platform,
      'os_version': osVersion,
      'app_version': appVersion,
      'is_trusted': isTrusted,
      'last_seen_at': lastSeenAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Device toEntity() {
    return Device(
      id: id,
      ownerId: ownerId,
      deviceId: deviceId,
      deviceName: deviceName,
      platform: platform,
      osVersion: osVersion,
      appVersion: appVersion,
      isTrusted: isTrusted,
      lastSeenAt: lastSeenAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory DeviceModel.fromEntity(Device entity) {
    return DeviceModel(
      id: entity.id,
      ownerId: entity.ownerId,
      deviceId: entity.deviceId,
      deviceName: entity.deviceName,
      platform: entity.platform,
      osVersion: entity.osVersion,
      appVersion: entity.appVersion,
      isTrusted: entity.isTrusted,
      lastSeenAt: entity.lastSeenAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}