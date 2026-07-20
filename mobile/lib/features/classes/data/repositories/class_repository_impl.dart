import '../../domain/entities/class_entity.dart';
import '../../domain/entities/user_option.dart';
import '../../domain/repositories/classes_repository.dart';
import '../datasources/clasess_remote_datasource.dart';
import '../models/class_model.dart';
import '../models/user_option_model.dart';

class ClassRepositoryImpl implements ClassesRepository {
  ClassRepositoryImpl(this._remote);

  final ClasessRemoteDatasource _remote;

  @override
  Future<List<ClassEntity>> getAll() async {
    final jsonList = await _remote.getAll();
    return ClassModel.fromJsonList(jsonList);
  }

  @override
  Future<ClassEntity> create({
    required String name,
    required String checkInStart,
    required String checkInDeadline,
    int? homeroomTeacherId,
  }) async {
    final json = await _remote.create({
      'name': name,
      'checkInStart': checkInStart,
      'checkInDeadline': checkInDeadline,
      if (homeroomTeacherId != null) 'homeroomTeacherId': homeroomTeacherId,
    });
    return ClassModel.fromJson(json);
  }

  @override
  Future<ClassEntity> update(
    int id, {
    String? name,
    String? checkInStart,
    String? checkInDeadline,
    int? homeroomTeacherId,
  }) async {
    final json = await _remote.update(id, {
      if (name != null) 'name': name,
      if (checkInStart != null) 'checkInStart': checkInStart,
      if (checkInDeadline != null) 'checkInDeadline': checkInDeadline,
      if (homeroomTeacherId != null) 'homeroomTeacherId': homeroomTeacherId,
    });
    return ClassModel.fromJson(json);
  }

  @override
  Future<List<UserOption>> getTeacherOptions() async {
    final jsonList = await _remote.getTeacherOptions();
    return UserOptionModel.fromJsonList(jsonList);
  }
}