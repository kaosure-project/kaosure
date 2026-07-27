import '../../domain/entities/device.dart';

final class DeviceState {
  const DeviceState({
    this.devices = const [],
    this.selectedDevice,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Device> devices;
  final Device? selectedDevice;
  final bool isLoading;
  final String? errorMessage;

  factory DeviceState.initial() {
    return const DeviceState();
  }

  DeviceState copyWith({
    List<Device>? devices,
    Device? selectedDevice,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DeviceState(
      devices: devices ?? this.devices,
      selectedDevice: selectedDevice ?? this.selectedDevice,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}