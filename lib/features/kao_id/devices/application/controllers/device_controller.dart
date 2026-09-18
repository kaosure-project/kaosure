import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/device.dart';
import '../../domain/usecases/create_device.dart';
import '../../domain/usecases/delete_device.dart';
import '../../domain/usecases/get_device.dart';
import '../../domain/usecases/get_devices.dart';
import '../../domain/usecases/update_device.dart';

import '../states/device_state.dart';

final class DeviceController
    extends StateNotifier<DeviceState> {
  DeviceController({
    required this._getDevices,
    required this._getDevice,
    required this._createDevice,
    required this._updateDevice,
    required this._deleteDevice,
  }) : super(const DeviceState());

  final GetDevicesUseCase _getDevices;
  final GetDeviceUseCase _getDevice;
  final CreateDeviceUseCase _createDevice;
  final UpdateDeviceUseCase _updateDevice;
  final DeleteDeviceUseCase _deleteDevice;

  // ===========================================================================
  // LOAD DEVICES
  // ===========================================================================

  Future<void> loadDevices({
    required String ownerId,
  }) async {
    _setLoading();

    try {
      final devices = await _getDevices(
        ownerId: ownerId,
      );

      state = state.copyWith(
        isLoading: false,
        devices: devices,
        clearError: true,
      );
    } catch (error) {
      _setError(error);
    }
  }

  // ===========================================================================
  // LOAD DEVICE
  // ===========================================================================

  Future<void> loadDevice({
    required String deviceId,
  }) async {
    _setLoading();

    try {
      final device = await _getDevice(
        deviceId: deviceId,
      );

      state = state.copyWith(
        isLoading: false,
        selectedDevice: device,
        clearError: true,
      );
    } catch (error) {
      _setError(error);
    }
  }

  // ===========================================================================
  // CREATE DEVICE
  // ===========================================================================

  Future<void> createDevice({
    required Device device,
  }) async {
    _setLoading();

    try {
      await _createDevice(
        device: device,
      );

      await loadDevices(
        ownerId: device.ownerId,
      );
    } catch (error) {
      _setError(error);
    }
  }

  // ===========================================================================
  // UPDATE DEVICE
  // ===========================================================================

  Future<void> updateDevice({
    required Device device,
  }) async {
    _setLoading();

    try {
      await _updateDevice(
        device: device,
      );

      state = state.copyWith(
        selectedDevice: device,
        isLoading: false,
        clearError: true,
      );

      await loadDevices(
        ownerId: device.ownerId,
      );
    } catch (error) {
      _setError(error);
    }
  }

  // ===========================================================================
  // DELETE DEVICE
  // ===========================================================================

  Future<void> deleteDevice({
    required String deviceId,
    String? ownerId,
  }) async {
    _setLoading();

    try {
      await _deleteDevice(
        deviceId: deviceId,
      );

      state = state.copyWith(
        isLoading: false,
        clearSelectedDevice: true,
        clearError: true,
      );

      if (ownerId != null) {
        await loadDevices(
          ownerId: ownerId,
        );
      }
    } catch (error) {
      _setError(error);
    }
  }

  // ===========================================================================
  // STATE
  // ===========================================================================

  void clearError() {
    state = state.copyWith(
      clearError: true,
    );
  }

  void clearSelectedDevice() {
    state = state.copyWith(
      clearSelectedDevice: true,
    );
  }

  void clear() {
    state = const DeviceState();
  }

  // ===========================================================================
  // PRIVATE
  // ===========================================================================

  void _setLoading() {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );
  }

  void _setError(Object error) {
    state = state.copyWith(
      isLoading: false,
      errorMessage: error.toString(),
    );
  }
}