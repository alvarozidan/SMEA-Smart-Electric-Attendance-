import '../entities/device_entity.dart';
import '../entities/scan_result.dart';

abstract class DeviceRepository {
  Future<List<DeviceEntity>> getAll();
  Future<DeviceEntity> toggleRegistrationMode(int deviceId, bool enabled);
  Future<ScanResult?> getLastScan(int deviceId);
}