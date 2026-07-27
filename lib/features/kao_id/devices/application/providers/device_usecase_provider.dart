import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/device_repository_provider.dart';

import '../../domain/usecases/create_device.dart';
import '../../domain/usecases/delete_device.dart';
import '../../domain/usecases/get_device.dart';
import '../../domain/usecases/get_devices.dart';
import '../../domain/usecases/update_device.dart';

final getDevicesProvider = Provider<GetDevicesUseCase>((ref) {
  return GetDevicesUseCase(
    ref.watch(deviceRepositoryProvider),
  );
});

final getDeviceProvider = Provider<GetDeviceUseCase>((ref) {
  return GetDeviceUseCase(
    ref.watch(deviceRepositoryProvider),
  );
});

final createDeviceProvider = Provider<CreateDeviceUseCase>((ref) {
  return CreateDeviceUseCase(
    ref.watch(deviceRepositoryProvider),
  );
});

final updateDeviceProvider = Provider<UpdateDeviceUseCase>((ref) {
  return UpdateDeviceUseCase(
    ref.watch(deviceRepositoryProvider),
  );
});

final deleteDeviceProvider = Provider<DeleteDeviceUseCase>((ref) {
  return DeleteDeviceUseCase(
    ref.watch(deviceRepositoryProvider),
  );
});