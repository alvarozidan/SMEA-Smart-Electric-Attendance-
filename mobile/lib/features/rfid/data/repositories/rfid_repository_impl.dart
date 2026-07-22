import '../../domain/repositories/rfid_repository.dart';
import '../datasources/rfid_remote_datasource.dart';

class RfidRepositoryImpl implements RfidRepository {
  RfidRepositoryImpl(this._remote);

  final RfidRemoteDatasource _remote;

  @override
  Future<void> register({
    required int studentId,
    required int deviceId,
    required String type,
    required String value,
  }) {
    return _remote.register({
      'studentId' : studentId,
      'deviceId' : deviceId,
      'type' : type,
      'value' : value,
    });
  }

  @override
  Future<void> unbindRfid(String rfidUid) => _remote.unbindRfid(rfidUid);
}