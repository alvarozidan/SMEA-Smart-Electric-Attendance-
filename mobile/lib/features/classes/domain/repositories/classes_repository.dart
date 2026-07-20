import '../entities/class_entity.dart';
import '../entities/user_option.dart';

abstract class ClassesRepository {
  Future<List<ClassEntity>> getAll();

  Future<ClassEntity> create({
    required String name,
    required String checkInStart,
    required String checkInDeadline,
    int? homeroomTeacherId,
  });

  Future<ClassEntity> update({
    int id,
    String? name,
    String? checkInStart,
    String? checkInDeadline,
    int? homeroomTeacherId,
  });

  Future<List<UserOption>> getTeacherOptions();
}