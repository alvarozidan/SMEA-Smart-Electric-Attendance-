abstract class RfidRepository {
  Future<void> register({
    required int studentId,
    required int deviceId,
    required String type,
    required String value,
  });

  Future<void> unbindRfid(String rfidUid);
}