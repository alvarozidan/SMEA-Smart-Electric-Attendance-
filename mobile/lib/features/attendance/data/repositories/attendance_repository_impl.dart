import 'package:intl/intl.dart';

import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/attendance_status.dart';
import '../../domain/entities/report_file.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_datasource.dart';
import '../models/attendance_model.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  AttendanceRepositoryImpl(this._remote);

  final AttendanceRemoteDatasource _remote;
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  Future<List<AttendanceRecord>> getAll({
    required DateTime date,
    int? classId,
  }) async {
    final jsonList = await _remote.getAll({
      'date' : _dateFormat.format(date),
      if (classId != null) 'classId' : classId,
    });
    return AttendanceModel.fromJsonList(jsonList);
  }

  @override
  Future<AttendanceRecord> updateStatus(int id, AttendanceStatus status) async {
    final json = await _remote.updateStatus(id, status.raw);
    return AttendanceModel.fromJson(json);
  }

  @override
  Future<ReportFile> downloadReport({
    required String format,
    required DateTime startDate,
    required DateTime endDate,
    int? classId,
  }) async {
    final bytes = await _remote.downloadReport({
      'format' : format,
      'startDate' : _dateFormat.format(startDate),
      'endDate' : _dateFormat.format(endDate),
      if (classId != null) 'classId' : classId,
    });

    final filename = format == 'excel' ? 'laporan_kehadiran.xlsx' : 'laporan_kehadiran.pdf';
    return ReportFile(bytes: bytes, filename: filename);
  }
}