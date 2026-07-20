class ClassEntity {
  const ClassEntity({
    required this.id,
    required this.name,
    this.homeroomTeacherId,
    this.checkInStart,
    this.checkInDeadline,
  });

  final int id;
  final String name;
  final int? homeroomTeacherId;
  final String? checkInStart;
  final String? checkInDeadline;
}