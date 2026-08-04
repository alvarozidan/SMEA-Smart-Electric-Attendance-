import '../../domain/entities/student_import_result_entity.dart';

class StudentImportResultModel {
  static StudentImportResultEntity fromJson(Map<String, dynamic> json) {
    final failedJson = json['failed'] as List<dynamic>? ?? [];
    return StudentImportResultEntity(
      totalRows: json['totalRows'] as int? ?? 0,
      successCount: json['successCount'] as int? ?? 0,
      failedCount: json['failedCount'] as int? ?? 0,
      failed: failedJson.map((e) {
        final map = e as Map<String, dynamic>;
        return StudentImportFailedRow(
          row: map['row'] as int? ?? 0,
          nis: map['nis'] as String?,
          name: map['name'] as String?,
          reason: map['reason'] as String? ?? 'Tidak diketahui',
        );
      }).toList(),
    );
  }
}