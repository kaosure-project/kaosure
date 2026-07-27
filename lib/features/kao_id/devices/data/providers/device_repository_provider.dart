import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/supabase_provider.dart';

import '../datasources/remote/device_remote_datasource.dart';
import '../datasources/remote/device_remote_datasource_impl.dart';

import '../repositories/device_repository_impl.dart';

import '../../domain/repositories/device_repository.dart';

final deviceRemoteDataSourceProvider =
    Provider<DeviceRemoteDataSource>((ref) {
  return DeviceRemoteDataSourceImpl(
    ref.watch(supabaseClientProvider),
  );
});

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepositoryImpl(
    ref.watch(deviceRemoteDataSourceProvider),
  );
});