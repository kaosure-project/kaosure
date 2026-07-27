import '../entities/device.dart';

abstract interface class DeviceRepository {
  Future<List<Device>> getDevices({
    required String ownerId,
  });

  Future<Device> getDevice({
    required String deviceId,
  });

  Future<void> registerDevice({
    required Device device,
  });

  Future<void> updateDevice({
    required Device device,
  });

  Future<void> trustDevice({
    required String deviceId,
  });

  Future<void> untrustDevice({
    required String deviceId,
  });

  Future<void> removeDevice({
    required String deviceId,
  });

  Future<bool> exists({
    required String deviceId,
  });
}