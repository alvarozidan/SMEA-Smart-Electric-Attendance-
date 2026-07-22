class ScanResult {
  const ScanResult({
    required this.value,
    required this.type,
    required this.scannedAt,
  });

  final String value;
  final String type;
  final DateTime scannedAt;
}