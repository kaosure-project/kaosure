import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/device_model.dart';
import 'device_remote_datasource.dart';

final class DeviceRemoteDataSourceImpl
    implements DeviceRemoteDataSource {
  DeviceRemoteDataSourceImpl(this._supabase);

  final SupabaseClient _supabase;

  @override
  Future<List<DeviceModel>> getDevices({
    required String ownerId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<DeviceModel> getDevice({
    required String deviceId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> registerDevice({
    required DeviceModel device,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateDevice({
    required DeviceModel device,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> trustDevice({
    required String deviceId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> untrustDevice({
    required String deviceId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeDevice({
    required String deviceId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<bool> exists({
    required String deviceId,
  }) {
    throw UnimplementedError();
  }
}