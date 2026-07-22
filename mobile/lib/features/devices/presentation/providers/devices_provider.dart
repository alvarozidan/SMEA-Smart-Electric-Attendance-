import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/device_remote_datasource.dart';
import '../../data/repositories/devices_repository_impl.dart';
import '../../domain/entities/device_entity.dart';
import '../../domain/repositories/device_repository.dart';

final deviceRemoteDatasourceProvider = Provider<DeviceRemoteDatasource>((ref) {
  return DeviceRemoteDatasource(ref.watch(dioProvider));
});

final devicesRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DevicesRepositoryImpl(ref.watch(deviceRemoteDatasourceProvider));
});

final devicesListProvider = FutureProvider.autoDispose<List<DeviceEntity>>((ref) {
  return ref.watch(devicesRepositoryProvider).getAll();
});

final deviceToggleControllerProvider =
  AsyncNotifierProvider.autoDispose<DeviceToggleController, void>(DeviceToggleController.new);

class DeviceToggleController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> toggle(int deviceId, bool enabled) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return ref.read(devicesRepositoryProvider).toggleRegistrationMode(deviceId, enabled);
    });
    state = result.hasError ? AsyncError(result.error!, result.stackTrace!) : const AsyncData(null);
    if (!result.hasError) ref.invalidate(devicesListProvider);
    return !result.hasError;
  }
}