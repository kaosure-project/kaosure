import '../entities/device.dart';
import '../repositories/device_repository.dart';

final class GetDevicesUseCase {
  const GetDevicesUseCase(this._repository);

  final DeviceRepository _repository;

  Future<List<Device>> call({
    required String ownerId,
  }) {
    return _repository.getDevices(
      ownerId: ownerId,
    );
  }
}