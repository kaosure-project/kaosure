import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/device_controller.dart';
import '../states/device_state.dart';

import 'device_usecase_provider.dart';

final deviceControllerProvider =
    StateNotifierProvider<DeviceController, DeviceState>((ref) {
  return DeviceController(
    getDevices: ref.watch(getDevicesProvider),
    getDevice: ref.watch(getDeviceProvider),
    createDevice: ref.watch(createDeviceProvider),
    updateDevice: ref.watch(updateDeviceProvider),
    deleteDevice: ref.watch(deleteDeviceProvider),
  );
});