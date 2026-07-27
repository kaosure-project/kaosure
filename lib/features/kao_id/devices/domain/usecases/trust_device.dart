import '../repositories/device_repository.dart';

final class TrustDeviceUseCase {
  const TrustDeviceUseCase(this._repository);

  final DeviceRepository _repository;

  Future<void> call({
    required String deviceId,
  }) {
    return _repository.trustDevice(
      deviceId: deviceId,
    );
  }
}