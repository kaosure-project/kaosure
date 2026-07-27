import '../entities/device.dart';
import '../repositories/device_repository.dart';

final class CreateDeviceUseCase {
  const CreateDeviceUseCase(this._repository);

  final DeviceRepository _repository;

  Future<void> call({
    required Device device,
  }) {
    return _repository.registerDevice(
      device: device,
    );
  }
}