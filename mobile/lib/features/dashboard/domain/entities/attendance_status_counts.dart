class AttendanceStatusCounts {
  const AttendanceStatusCounts({
    required this.hadir,
    required this.terlambat,
    required this.tidakHadir,
    required this.izin,
    required this.sakit,
  });

  factory AttendanceStatusCounts.fromJson(Map<String, dynamic> json) {
    return AttendanceStatusCounts(
      hadir: json['hadir'] as int? ?? 0, 
      terlambat: json['terlambat'] as int? ?? 0, 
      tidakHadir: json['tidakHadir'] as int? ?? 0, 
      izin: json['izin'] as int? ?? 0, 
      sakit: json['sakit'] as int? ?? 0,
    );
  }

  final int hadir;
  final int terlambat;
  final int tidakHadir;
  final int izin;
  final int sakit;

  int get total => hadir + terlambat + tidakHadir + izin + sakit;
}