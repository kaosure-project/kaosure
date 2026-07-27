import '../repositories/device_repository.dart';

final class ExistsDeviceUseCase {
  const ExistsDeviceUseCase(this._repository);

  final DeviceRepository _repository;

  Future<bool> call({
    required String deviceId,
  }) {
    return _repository.exists(
      deviceId: deviceId,
    );
  }
}