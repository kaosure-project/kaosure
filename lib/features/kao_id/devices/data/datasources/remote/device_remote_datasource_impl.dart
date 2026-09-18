import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/device_model.dart';
import 'device_remote_datasource.dart';

final class DeviceRemoteDataSourceImpl
    implements DeviceRemoteDataSource {
  DeviceRemoteDataSourceImpl(this._supabase);

  final SupabaseClient _supabase;

  static const String _table = 'devices';

  String get _currentUserId {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User is not signed in.');
    }

    return user.id;
  }

  Map<String, dynamic> _toDatabaseMap(
    DeviceModel device,
  ) {
    return {
      'profile_id': device.ownerId,
      'device_id': device.deviceId,
      'device_name': device.deviceName,
      'operating_system': device.platform,
      'os_version': device.osVersion,
      'app_version': device.appVersion,
      'is_trusted': device.isTrusted,
      'last_seen_at':
          device.lastSeenAt.toIso8601String(),
    };
  }

  DeviceModel _fromDatabaseMap(
    Map<String, dynamic> row,
  ) {
    return DeviceModel.fromJson({
      'id': row['id'],
      'owner_id': row['profile_id'],
      'device_id': row['device_id'],
      'device_name': row['device_name'],
      'platform': row['operating_system'],
      'os_version': row['os_version'],
      'app_version': row['app_version'],
      'is_trusted': row['is_trusted'],
      'last_seen_at': row['last_seen_at'],
      'created_at': row['created_at'],
      'updated_at': row['updated_at'],
    });
  }

  void _validateOwner(
    String ownerId,
  ) {
    if (ownerId != _currentUserId) {
      throw Exception(
        'Not authorized to access this device profile.',
      );
    }
  }

  // ===========================================================================
  // GET DEVICES
  // ===========================================================================

  @override
  Future<List<DeviceModel>> getDevices({
    required String ownerId,
  }) async {
    _validateOwner(ownerId);

    final rows = await _supabase
        .from(_table)
        .select()
        .eq('profile_id', ownerId)
        .order('last_seen_at', ascending: false);

    return rows
        .map(
          (row) => _fromDatabaseMap(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList(growable: false);
  }

  // ===========================================================================
  // GET DEVICE
  // ===========================================================================

  @override
  Future<DeviceModel> getDevice({
    required String deviceId,
  }) async {
    final userId = _currentUserId;

    final row = await _supabase
        .from(_table)
        .select()
        .eq('profile_id', userId)
        .eq('device_id', deviceId)
        .single();

    return _fromDatabaseMap(
      Map<String, dynamic>.from(row),
    );
  }

  // ===========================================================================
  // REGISTER DEVICE
  // ===========================================================================

  @override
  Future<void> registerDevice({
    required DeviceModel device,
  }) async {
    _validateOwner(device.ownerId);

    final row = await _supabase
        .from(_table)
        .insert(
          _toDatabaseMap(device),
        )
        .select()
        .single();

    _fromDatabaseMap(
      Map<String, dynamic>.from(row),
    );
  }

  // ===========================================================================
  // UPDATE DEVICE
  // ===========================================================================

  @override
  Future<void> updateDevice({
    required DeviceModel device,
  }) async {
    _validateOwner(device.ownerId);

    final row = await _supabase
        .from(_table)
        .update(
          {
            'device_id': device.deviceId,
            'device_name': device.deviceName,
            'operating_system': device.platform,
            'os_version': device.osVersion,
            'app_version': device.appVersion,
            'is_trusted': device.isTrusted,
            'last_seen_at':
                device.lastSeenAt.toIso8601String(),
          },
        )
        .eq('id', device.id)
        .eq('profile_id', device.ownerId)
        .select()
        .single();

    _fromDatabaseMap(
      Map<String, dynamic>.from(row),
    );
  }

  // ===========================================================================
  // TRUST DEVICE
  // ===========================================================================

  @override
  Future<void> trustDevice({
    required String deviceId,
  }) async {
    await _updateTrustStatus(
      deviceId: deviceId,
      isTrusted: true,
    );
  }

  // ===========================================================================
  // UNTRUST DEVICE
  // ===========================================================================

  @override
  Future<void> untrustDevice({
    required String deviceId,
  }) async {
    await _updateTrustStatus(
      deviceId: deviceId,
      isTrusted: false,
    );
  }

  Future<void> _updateTrustStatus({
    required String deviceId,
    required bool isTrusted,
  }) async {
    final userId = _currentUserId;

    await _supabase
        .from(_table)
        .update({
          'is_trusted': isTrusted,
        })
        .eq('profile_id', userId)
        .eq('device_id', deviceId);
  }

  // ===========================================================================
  // REMOVE DEVICE
  // ===========================================================================

  @override
  Future<void> removeDevice({
    required String deviceId,
  }) async {
    final userId = _currentUserId;

    await _supabase
        .from(_table)
        .delete()
        .eq('profile_id', userId)
        .eq('device_id', deviceId);
  }

  // ===========================================================================
  // EXISTS
  // ===========================================================================

  @override
  Future<bool> exists({
    required String deviceId,
  }) async {
    final userId = _currentUserId;

    final rows = await _supabase
        .from(_table)
        .select('id')
        .eq('profile_id', userId)
        .eq('device_id', deviceId)
        .limit(1);

    return rows.isNotEmpty;
  }
}