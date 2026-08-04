class StudentImportFailedRow {
  const StudentImportFailedRow({
    required this.row,
    required this.reason,
    this.nis,
    this.name,
  });

  final int row;
  final String? nis;
  final String? name;
  final String reason;
}

class StudentImportResultEntity {
  const StudentImportResultEntity({
    required this.totalRows,
    required this.successCount,
    required this.failedCount,
    required this.failed,
  });

  final int totalRows;
  final int successCount;
  final int failedCount;
  final List<StudentImportFailedRow> failed;
}