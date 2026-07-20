import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/clasess_remote_datasource.dart';
import '../../data/repositories/class_repository_impl.dart';
import '../../domain/entities/class_entity.dart';
import '../../domain/entities/user_option.dart';
import '../../domain/repositories/classes_repository.dart';

final classesRemoteDatasourceProvider = Provider<ClasessRemoteDatasource>((ref) {
  return ClasessRemoteDatasource(ref.watch(dioProvider));
});

final classesRepositoryProvider = Provider<ClassesRepository>((ref) {
  return ClassRepositoryImpl(ref.watch(classesRemoteDatasourceProvider));
});

final classesListProvider = FutureProvider.autoDispose<List<ClassEntity>>((ref) {
  return ref.watch(classesRepositoryProvider).getAll();
});

final teacherOptionsProvider = FutureProvider.autoDispose<List<UserOption>>((ref) {
  return ref.watch(classesRepositoryProvider).getTeacherOptions();
});

final classFormControllerProvider =
    AsyncNotifierProvider.autoDispose<ClassFormController, void>(ClassFormController.new);

class ClassFormController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> createClass({
    required String name,
    required String checkInStart,
    required String checkInDeadline,
    int? homeroomTeacherId,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return ref.read(classesRepositoryProvider).create(
            name: name,
            checkInStart: checkInStart,
            checkInDeadline: checkInDeadline,
            homeroomTeacherId: homeroomTeacherId,
          );
    });
    state = result.hasError ? AsyncError(result.error!, result.stackTrace!) : const AsyncData(null);
    if (!result.hasError) ref.invalidate(classesListProvider);
    return !result.hasError;
  }

  Future<bool> updateClass(
    int id, {
    String? name,
    String? checkInStart,
    String? checkInDeadline,
    int? homeroomTeacherId,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return ref.read(classesRepositoryProvider).update(
            id,
            name: name,
            checkInStart: checkInStart,
            checkInDeadline: checkInDeadline,
            homeroomTeacherId: homeroomTeacherId,
          );
    });
    state = result.hasError ? AsyncError(result.error!, result.stackTrace!) : const AsyncData(null);
    if (!result.hasError) ref.invalidate(classesListProvider);
    return !result.hasError;
  }
}