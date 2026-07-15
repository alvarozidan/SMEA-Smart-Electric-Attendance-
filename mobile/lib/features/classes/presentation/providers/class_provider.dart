import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/clasess_remote_datasource.dart';
import '../../data/repositories/class_repository_impl.dart';
import '../../domain/entities/class_entity.dart';
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