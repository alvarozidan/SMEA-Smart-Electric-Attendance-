import '../entities/device_entity.dart';

abstract class DeviceRepository {
  Future<List<DeviceEntity>> getAll();
  Future<DeviceEntity> toggleRegistrationMode(int deviceId, bool enabled);
}