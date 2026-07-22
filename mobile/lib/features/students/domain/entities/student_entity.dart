class StudentEntity {
  const StudentEntity ({
    required this.id,
    required this.nis,
    required this.name,
    required this.classId,
    this.className,
    this.rfidUid,
    this.fingerprintIndex,
});
  final int id;
  final String nis;
  final String name;
  final int? classId;
  final String? className;
  final String? rfidUid;
  final int? fingerprintIndex;

  bool get hasRfid => rfidUid != null;
  bool get hasFingerprint => fingerprintIndex != null;
}