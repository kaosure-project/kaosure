import '../../domain/entities/device.dart';
import '../../domain/repositories/device_repository.dart';
import '../datasources/remote/device_remote_datasource.dart';
import '../mappers/device_mapper.dart';

final class DeviceRepositoryImpl implements DeviceRepository {
  const DeviceRepositoryImpl(this._remoteDataSource);

  final DeviceRemoteDataSource _remoteDataSource;

  @override
  Future<List<Device>> getDevices({
    required String ownerId,
  }) async {
    final models = await _remoteDataSource.getDevices(
      ownerId: ownerId,
    );

    return models
        .map(DeviceMapper.toEntity)
        .toList(growable: false);
  }

  @override
  Future<Device> getDevice({
    required String deviceId,
  }) async {
    final model = await _remoteDataSource.getDevice(
      deviceId: deviceId,
    );

    return DeviceMapper.toEntity(model);
  }

  @override
  Future<void> registerDevice({
    required Device device,
  }) {
    return _remoteDataSource.registerDevice(
      device: DeviceMapper.toModel(device),
    );
  }

  @override
  Future<void> updateDevice({
    required Device device,
  }) {
    return _remoteDataSource.updateDevice(
      device: DeviceMapper.toModel(device),
    );
  }

  @override
  Future<void> trustDevice({
    required String deviceId,
  }) {
    return _remoteDataSource.trustDevice(
      deviceId: deviceId,
    );
  }

  @override
  Future<void> untrustDevice({
    required String deviceId,
  }) {
    return _remoteDataSource.untrustDevice(
      deviceId: deviceId,
    );
  }

  @override
  Future<void> removeDevice({
    required String deviceId,
  }) {
    return _remoteDataSource.removeDevice(
      deviceId: deviceId,
    );
  }

  @override
  Future<bool> exists({
    required String deviceId,
  }) {
    return _remoteDataSource.exists(
      deviceId: deviceId,
    );
  }
}