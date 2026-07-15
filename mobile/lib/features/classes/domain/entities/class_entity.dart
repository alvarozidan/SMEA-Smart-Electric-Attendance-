class ClassEntity {
  const ClassEntity({
    required this.id,
    required this.name,
    this.homeroomTeacherId,
  });

  final int id;
  final String name;
  final int? homeroomTeacherId;
}