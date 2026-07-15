class StudentEntity {
  const StudentEntity ({
    required this.id,
    required this.nis,
    required this.name,
    required this.classId,
    this.className,
  });

  final int id;
  final String nis;
  final String name;
  final int? classId;
  final String? className;
}