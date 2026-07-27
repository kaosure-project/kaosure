import '../entities/device.dart';
import '../repositories/device_repository.dart';

final class RegisterDeviceUseCase {
  const RegisterDeviceUseCase(this._repository);

  final DeviceRepository _repository;

  Future<void> call({
    required Device device,
  }) {
    return _repository.registerDevice(
      device: device,
    );
  }
}