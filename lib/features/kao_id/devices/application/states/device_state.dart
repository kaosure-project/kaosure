import '../../domain/entities/device.dart';

class DeviceState {
  const DeviceState({
    this.isLoading = false,
    this.devices = const [],
    this.selectedDevice,
    this.errorMessage,
  });

  final bool isLoading;
  final List<Device> devices;
  final Device? selectedDevice;
  final String? errorMessage;

  DeviceState copyWith({
    bool? isLoading,
    List<Device>? devices,
    Device? selectedDevice,
    String? errorMessage,
  }) {
    return DeviceState(
      isLoading: isLoading ?? this.isLoading,
      devices: devices ?? this.devices,
      selectedDevice: selectedDevice ?? this.selectedDevice,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}