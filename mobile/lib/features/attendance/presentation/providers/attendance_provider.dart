import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/attendance_remote_datasource.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/attendance_status.dart';
import '../../domain/repositories/attendance_repository.dart';

final attendanceRemoteDatasourceProvider = Provider<AttendanceRemoteDatasource>((ref) {
  return AttendanceRemoteDatasource(ref.watch(dioProvider));
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepositoryImpl(ref.watch(attendanceRemoteDatasourceProvider));
});

class AttendanceFilter {
  const AttendanceFilter({
    required this.date,
    this.classId,
  });

  final DateTime date;
  final int? classId;

  AttendanceFilter copyWith({
    DateTime? date,
    int? classId,
    bool clearClassId = false
  }) {
    return AttendanceFilter(
      date: date ?? this.date,
      classId: clearClassId ? null : (classId ?? this.classId),
    );
  }
}

final attendanceFilterProvider = StateProvider.autoDispose<AttendanceFilter>((ref) {
  final now = DateTime.now();
  return AttendanceFilter(
    date: DateTime(now.year, now.month, now.day)
  );
});

final attendanceListProvider = FutureProvider.autoDispose<List<AttendanceRecord>>((ref) {
  final filter = ref.watch(attendanceFilterProvider);
  return ref.watch(attendanceRepositoryProvider).getAll(
    date: filter.date, 
    classId: filter.classId
  );
});

final attendanceActionControllerProvider =
  AsyncNotifierProvider.autoDispose<AttendanceActionController, void>(AttendanceActionController.new);

class AttendanceActionController extends AutoDisposeAsyncNotifier<void> {

  @override
  Future<void> build() async {}

  Future<bool> updateStatus(int id, AttendanceStatus status) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return ref.read(attendanceRepositoryProvider).updateStatus(id, status);
    });
    state = result.hasError ? AsyncError(result.error!, result.stackTrace!) : const AsyncData(null);
    if (!result.hasError) ref.invalidate(attendanceListProvider);
    return !result.hasError;
  }
}

final reportControllerProvider =
  AsyncNotifierProvider.autoDispose<ReportController, void>(ReportController.new);

class ReportController extends AutoDisposeAsyncNotifier<void> {

  @override
  Future<void> build() async {}

  Future<bool> downloadAndOpen({
    required String format,
    required DateTime startDate,
    required DateTime endDate,
    int? classId,
  }) async {
    debugPrint('REPORT: mulai downloadAndOpen');
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      debugPrint('REPORT: manggil repository.downloadReport');
      final report = await ref.read(attendanceRepositoryProvider).downloadReport(
        format: format, 
        startDate: startDate, 
        endDate: endDate,
        classId: classId,
      );

      debugPrint('REPORT: dapat ${report.bytes.length} bytes, filename=${report.filename}');
      final dir = await getTemporaryDirectory();
      debugPrint('REPORT: temp dir = ${dir.path}');
      final file = File('${dir.path}/${report.filename}');
      await file.writeAsBytes(report.bytes);
      debugPrint('REPORT: file ditulis, membuka...');
      await OpenFile.open(file.path);
      debugPrint('REPORT: OpenFile.open selesai');
    });

    state = result.hasError ? AsyncError(result.error!, result.stackTrace!) : const AsyncData(null);
    debugPrint('REPORT: selesai, hasError=${result.hasError}, error=${result.error}');
    return !result.hasError;
  }
}