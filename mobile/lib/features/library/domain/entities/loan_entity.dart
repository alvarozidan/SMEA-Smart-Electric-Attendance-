import 'book_entity.dart';

enum LoanStatus { dipinjam, dikembalikan }

class LoanEntity {
  const LoanEntity({
    required this.id,
    required this.bookBarcode,
    required this.bookTitle,
    required this.bookCategory,
    required this.rfidUid,
    required this.studentName,
    required this.studentNis,
    required this.borrowedAt,
    required this.dueDate,
    required this.extensionCount,
    required this.overdueDaysLive,
  });

  final int id;
  final String bookBarcode;
  final String bookTitle;
  final BookCategory bookCategory;
  final String rfidUid;
  final String studentName;
  final String studentNis;
  final DateTime borrowedAt;
  final DateTime dueDate;
  final int extensionCount;
  final int overdueDaysLive;

  bool get isOverdue => overdueDaysLive > 0;
  bool get canExtend => bookCategory == BookCategory.umum && extensionCount < 1 && !isOverdue;
}

class LoanActionResult {
  const LoanActionResult({
    required this.loanId,
    required this.dueDate,
    required this.status,
    required this.overdueDays,
    required this.extensionCount,
  });

  final int loanId;
  final DateTime dueDate;
  final LoanStatus status;
  final int overdueDays;
  final int extensionCount;
}

class LibraryScanResult {
  const LibraryScanResult({
    required this.rfidUid,
    required this.scannedAt,
  });

  final String rfidUid;
  final DateTime scannedAt;
}