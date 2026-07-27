import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/remote/device_remote_datasource.dart';
import '../../data/datasources/remote/device_remote_datasource_impl.dart';
import '../../data/repositories/device_repository_impl.dart';
import '../../domain/repositories/device_repository.dart';
import '../../domain/usecases/exists_device.dart';
import '../../domain/usecases/get_device.dart';
import '../../domain/usecases/get_devices.dart';
import '../../domain/usecases/register_device.dart';
import '../../domain/usecases/remove_device.dart';
import '../../domain/usecases/trust_device.dart';
import '../../domain/usecases/untrust_device.dart';
import '../../domain/usecases/update_device.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final deviceRemoteDataSourceProvider =
    Provider<DeviceRemoteDataSource>(
  (ref) => DeviceRemoteDataSourceImpl(
    ref.watch(supabaseClientProvider),
  ),
);

final deviceRepositoryProvider =
    Provider<DeviceRepository>(
  (ref) => DeviceRepositoryImpl(
    ref.watch(deviceRemoteDataSourceProvider),
  ),
);

final getDevicesUseCaseProvider =
    Provider<GetDevicesUseCase>(
  (ref) => GetDevicesUseCase(
    ref.watch(deviceRepositoryProvider),
  ),
);

final getDeviceUseCaseProvider =
    Provider<GetDeviceUseCase>(
  (ref) => GetDeviceUseCase(
    ref.watch(deviceRepositoryProvider),
  ),
);

final registerDeviceUseCaseProvider =
    Provider<RegisterDeviceUseCase>(
  (ref) => RegisterDeviceUseCase(
    ref.watch(deviceRepositoryProvider),
  ),
);

final updateDeviceUseCaseProvider =
    Provider<UpdateDeviceUseCase>(
  (ref) => UpdateDeviceUseCase(
    ref.watch(deviceRepositoryProvider),
  ),
);

final trustDeviceUseCaseProvider =
    Provider<TrustDeviceUseCase>(
  (ref) => TrustDeviceUseCase(
    ref.watch(deviceRepositoryProvider),
  ),
);

final untrustDeviceUseCaseProvider =
    Provider<UntrustDeviceUseCase>(
  (ref) => UntrustDeviceUseCase(
    ref.watch(deviceRepositoryProvider),
  ),
);

final removeDeviceUseCaseProvider =
    Provider<RemoveDeviceUseCase>(
  (ref) => RemoveDeviceUseCase(
    ref.watch(deviceRepositoryProvider),
  ),
);

final existsDeviceUseCaseProvider =
    Provider<ExistsDeviceUseCase>(
  (ref) => ExistsDeviceUseCase(
    ref.watch(deviceRepositoryProvider),
  ),
);