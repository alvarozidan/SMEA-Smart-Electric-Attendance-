import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../students/presentation/providers/students_provider.dart';
import '../../data/datasources/rfid_remote_datasource.dart';
import '../../data/repositories/rfid_repository_impl.dart';
import '../../domain/repositories/rfid_repository.dart';

final rfidRemoteDatasourceProvider = Provider<RfidRemoteDatasource>((ref) {
  return RfidRemoteDatasource(ref.watch(dioProvider));
});

final rfidRepositoryProvider = Provider<RfidRepository>((ref) {
  return RfidRepositoryImpl(ref.watch(rfidRemoteDatasourceProvider));
});

final rfidActionControllerProvider =
  AsyncNotifierProvider.autoDispose<RfidActionController, void>(RfidActionController.new);

class RfidActionController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> register({
    required int studentId,
    required int deviceId,
    required String type,
    required String value,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return ref.read(rfidRepositoryProvider).register(
        studentId: studentId, 
        deviceId: deviceId, 
        type: type, 
        value: value
      );
    });
    state = result.hasError? AsyncError(result.error!, result.stackTrace!) : const AsyncData(null);
    if (!result.hasError) ref.invalidate(studentsListProvider);
    return !result.hasError;
  }

  Future<bool> unbindRfid(String rfidUid) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return ref.read(rfidRepositoryProvider).unbindRfid(rfidUid);
    });
    state = result.hasError ? AsyncError(result.error!, result.stackTrace!) : const AsyncData(null);
    if (!result.hasError) ref.invalidate(studentsListProvider);
    return !result.hasError;
  }
}