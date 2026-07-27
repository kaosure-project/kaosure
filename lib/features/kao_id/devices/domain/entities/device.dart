import 'package:equatable/equatable.dart';

final class Device extends Equatable {
  const Device({
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

  @override
  List<Object?> get props => [
        id,
        ownerId,
        deviceId,
        deviceName,
        platform,
        osVersion,
        appVersion,
        isTrusted,
        lastSeenAt,
        createdAt,
        updatedAt,
      ];

  Device copyWith({
    String? id,
    String? ownerId,
    String? deviceId,
    String? deviceName,
    String? platform,
    String? osVersion,
    String? appVersion,
    bool? isTrusted,
    DateTime? lastSeenAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Device(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      platform: platform ?? this.platform,
      osVersion: osVersion ?? this.osVersion,
      appVersion: appVersion ?? this.appVersion,
      isTrusted: isTrusted ?? this.isTrusted,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}