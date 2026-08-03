import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/device_providers.dart';
import '../../domain/entities/device.dart';
import '../states/device_state.dart';

final class DeviceController extends StateNotifier<DeviceState> {
  DeviceController(this._ref) : super(DeviceState.initial());

  final Ref _ref;

  Future<void> loadDevices({
    required String ownerId,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final devices = await _ref.read(
        getDevicesUseCaseProvider,
      ).call(
        ownerId: ownerId,
      );

      state = state.copyWith(
        devices: devices,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> registerDevice({
    required Device device,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      await _ref.read(
        registerDeviceUseCaseProvider,
      ).call(
        device: device,
      );

      await loadDevices(ownerId: device.ownerId);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }
}