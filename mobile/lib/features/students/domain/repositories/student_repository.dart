import '../entities/student_entity.dart';

abstract class StudentRepository {
  Future<List<StudentEntity>> getAll();

  Future<StudentEntity> create({
    required String nis,
    required String name,
    int? classId,
  });

  Future<StudentEntity> update(
    int id, {
      String? nis,
      String? name,
      int? classId,
  });

  Future<void> delete(int id);
}