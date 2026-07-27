import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/device_state.dart';

import '../../domain/usecases/get_devices.dart';
import '../../domain/usecases/get_device.dart';
import '../../domain/usecases/create_device.dart';
import '../../domain/usecases/update_device.dart';
import '../../domain/usecases/delete_device.dart';

class DeviceController extends StateNotifier<DeviceState> {
  DeviceController({
    required GetDevicesUseCase getDevices,
    required GetDeviceUseCase getDevice,
    required CreateDeviceUseCase createDevice,
    required UpdateDeviceUseCase updateDevice,
    required DeleteDeviceUseCase deleteDevice,
  })  : _getDevices = getDevices,
        _getDevice = getDevice,
        _createDevice = createDevice,
        _updateDevice = updateDevice,
        _deleteDevice = deleteDevice,
        super(const DeviceState());

  final GetDevicesUseCase _getDevices;
  final GetDeviceUseCase _getDevice;
  final CreateDeviceUseCase _createDevice;
  final UpdateDeviceUseCase _updateDevice;
  final DeleteDeviceUseCase _deleteDevice;
}