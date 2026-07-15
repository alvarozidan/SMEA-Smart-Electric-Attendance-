import '../../domain/entities/class_entity.dart';
import '../../domain/repositories/classes_repository.dart';
import '../datasources/clasess_remote_datasource.dart';
import '../models/class_model.dart';

class ClassRepositoryImpl implements ClassesRepository {
  ClassRepositoryImpl(this._remote);

  final ClasessRemoteDatasource _remote;

  @override
  Future<List<ClassEntity>> getAll() async {
    final jsonList = await _remote.getAll();
    return ClassModel.fromJsonList(jsonList);
  }
}