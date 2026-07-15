import '../../domain/entities/student_entity.dart';
import '../../domain/repositories/student_repository.dart';
import '../datasources/students_remote_datasource.dart';
import '../models/student_model.dart';

class StudentRepositoryImpl implements StudentRepository {
  StudentRepositoryImpl(this._remote);

  final StudentsRemoteDatasource _remote;

  @override
  Future<List<StudentEntity>> getAll() async {
    final jsonList = await _remote.getAll();
    return StudentModel.fromJsonList(jsonList);
  }

  @override
  Future<StudentEntity> create({
    required String nis,
    required String name,
    int? classId,
  }) async {
    final json = await _remote.create({
      'nis' : nis,
      'name' : name,
      if (classId != null) 'classId' : classId,
    });
    return StudentModel.fromJson(json);
  }

  @override
  Future<StudentEntity> update(
    int id, {
      String? nis,
      String? name,
      int? classId,
  }) async {
    final json = await _remote.update(
      id, {
        if (nis != null) 'nis' : nis,
        if (name != null) 'name' : name,
        if (classId != null) 'classId' : classId,
      });
      return StudentModel.fromJson(json);
  }

  @override
  Future<void> delete(int id) => _remote.delete(id);
}