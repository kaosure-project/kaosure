import '../repositories/device_repository.dart';

final class UntrustDeviceUseCase {
  const UntrustDeviceUseCase(this._repository);

  final DeviceRepository _repository;

  Future<void> call({
    required String deviceId,
  }) {
    return _repository.untrustDevice(
      deviceId: deviceId,
    );
  }
}