import '../../domain/entities/device.dart';

final class DeviceState {
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
    bool clearSelectedDevice = false,
    bool clearError = false,
  }) {
    return DeviceState(
      isLoading: isLoading ?? this.isLoading,
      devices: devices ?? this.devices,
      selectedDevice: clearSelectedDevice
          ? null
          : selectedDevice ?? this.selectedDevice,
      errorMessage: clearError
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}