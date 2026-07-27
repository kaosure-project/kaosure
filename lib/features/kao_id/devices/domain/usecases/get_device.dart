import '../entities/device.dart';
import '../repositories/device_repository.dart';

final class GetDeviceUseCase {
  const GetDeviceUseCase(this._repository);

  final DeviceRepository _repository;

  Future<Device> call({
    required String deviceId,
  }) {
    return _repository.getDevice(
      deviceId: deviceId,
    );
  }
}