import '../repositories/device_repository.dart';

final class RemoveDeviceUseCase {
  const RemoveDeviceUseCase(this._repository);

  final DeviceRepository _repository;

  Future<void> call({
    required String deviceId,
  }) {
    return _repository.removeDevice(
      deviceId: deviceId,
    );
  }
}