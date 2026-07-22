import '../../domain/entities/device_entity.dart';
import '../../domain/repositories/device_repository.dart';
import '../datasources/device_remote_datasource.dart';
import '../models/device_model.dart';

class DevicesRepositoryImpl implements DeviceRepository {
  DevicesRepositoryImpl(this._remote);

  final DeviceRemoteDatasource _remote;

  @override
  Future<List<DeviceEntity>> getAll() async {
    final jsonList = await _remote.getAll();
    return DeviceModel.fromJsonList(jsonList);
  }

  @override
  Future<DeviceEntity> toggleRegistrationMode(int deviceId, bool enabled) async {
    final json = await _remote.toggleRegistrationMode(deviceId, enabled);
    return DeviceModel.fromJson(json);
  }
}