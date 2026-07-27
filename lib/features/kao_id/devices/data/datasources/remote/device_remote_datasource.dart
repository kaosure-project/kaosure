import '../../models/device_model.dart';

abstract interface class DeviceRemoteDataSource {
  Future<List<DeviceModel>> getDevices({
    required String ownerId,
  });

  Future<DeviceModel> getDevice({
    required String deviceId,
  });

  Future<void> registerDevice({
    required DeviceModel device,
  });

  Future<void> updateDevice({
    required DeviceModel device,
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