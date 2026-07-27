import '../entities/device.dart';
import '../repositories/device_repository.dart';

final class UpdateDeviceUseCase {
  const UpdateDeviceUseCase(this._repository);

  final DeviceRepository _repository;

  Future<void> call({
    required Device device,
  }) {
    return _repository.updateDevice(
      device: device,
    );
  }
}