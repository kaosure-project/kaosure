import '../../domain/entities/device.dart';
import '../models/device_model.dart';

final class DeviceMapper {
  const DeviceMapper._();

  static Device toEntity(DeviceModel model) {
    return model.toEntity();
  }

  static DeviceModel toModel(Device entity) {
    return DeviceModel.fromEntity(entity);
  }
}