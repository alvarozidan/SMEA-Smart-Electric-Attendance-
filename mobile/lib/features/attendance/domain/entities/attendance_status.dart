enum AttendanceStatus { hadir, terlambat, tidakHadir, izin, sakit }

extension AttendanceStatusX on AttendanceStatus {
  String get raw {
    return switch (this) {
      AttendanceStatus.hadir => 'hadir',
      AttendanceStatus.terlambat => 'terlambat',
      AttendanceStatus.tidakHadir => 'tidak_hadir',
      AttendanceStatus.izin => 'izin',
      AttendanceStatus.sakit => 'sakit',
    };
  }

  String get label {
     return switch (this) {
      AttendanceStatus.hadir => 'hadir',
      AttendanceStatus.terlambat => 'terlambat',
      AttendanceStatus.tidakHadir => 'tidak_hadir',
      AttendanceStatus.izin => 'izin',
      AttendanceStatus.sakit => 'sakit',
    };
  }

  static AttendanceStatus fromRaw(String raw) {
    return switch (raw) {
      'hadir' => AttendanceStatus.hadir,
      'terlambat' => AttendanceStatus.hadir,
      'tidak_hadir' => AttendanceStatus.tidakHadir,
      'izin' => AttendanceStatus.izin,
      'sakit' => AttendanceStatus.sakit,
      _ => throw FormatException('Status tidak dikenali: $raw'),
    };
  }
}