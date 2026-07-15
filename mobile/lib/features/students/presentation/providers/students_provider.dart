import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/students_remote_datasource.dart';
import '../../data/repositories/student_repository_impl.dart';
import '../../domain/entities/student_entity.dart';
import '../../domain/repositories/student_repository.dart';              

final studentsRemoteDatasourceProvider = Provider<StudentsRemoteDatasource>((ref) {
  return StudentsRemoteDatasource(ref.watch(dioProvider));
});

final studentsRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepositoryImpl(ref.watch(studentsRemoteDatasourceProvider));
});

final studentsListProvider = FutureProvider.autoDispose<List<StudentEntity>>((ref) {
  return ref.watch(studentsRepositoryProvider).getAll();
}); 

final studentFormControllerProvider =
    AsyncNotifierProvider.autoDispose<StudentFormController, void>(StudentFormController.new);

class StudentFormController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> createStudent({
    required String nis,
    required String name,
    int? classId,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return ref.read(studentsRepositoryProvider).create(
        nis: nis, 
        name: name,
        classId: classId
      );
    });
    state = result.hasError ? AsyncError(result.error!, result.stackTrace!) : const AsyncData(null);
    if (!result.hasError) ref.invalidate(studentsListProvider);
    return !result.hasError;
  }

  Future<bool> updateStudent(
    int id, {
    String? nis,
    String? name,
    int? classId    
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return ref.read(studentsRepositoryProvider).update(
        id, 
        nis: nis,
        name: name,
        classId:  classId);
    });
    state = result.hasError ? AsyncError(result.error!, result.stackTrace!) : AsyncData(null);
    if (!result.hasError) ref.invalidate(studentsListProvider);
    return !result.hasError;
  }

  Future<bool> deleteStudent(int id) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return ref.read(studentsRepositoryProvider).delete(id);
    });
    state = result.hasError ? AsyncError(result.error!, result.stackTrace!) : const AsyncData(null);
    if (!result.hasError) ref.invalidate(studentsListProvider);
    return !result.hasError;
  }
}