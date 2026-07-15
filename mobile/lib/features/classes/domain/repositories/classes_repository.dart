import '../entities/class_entity.dart';

abstract class ClassesRepository {
  Future<List<ClassEntity>> getAll();
}