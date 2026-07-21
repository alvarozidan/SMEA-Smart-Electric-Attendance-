class ReportFile {
  const ReportFile({
    required this.bytes,
    required this.filename,
  });

  final List<int> bytes;
  final String filename;
}