import '../../domain/entities/book_entity.dart';
import '../../domain/entities/loan_entity.dart';

class LoanModel {
  static LoanStatus _parseStatus(String raw) => switch (raw) {
    'DIPINJAM' => LoanStatus.dipinjam,
    'DIKEMBALIKAN' => LoanStatus.dikembalikan,
    _ => throw FormatException('category pinjaman tidak dikenal: $raw'),
  };

  static BookCategory _parseCategory(String raw) => switch (raw) {
    'UMUM' => BookCategory.umum,
    'PELAJARAN' => BookCategory.pelajaran,
    _ => throw FormatException('category buku tidak dikenal: $raw'),
  };

  static LoanEntity fromJoinedJson(Map<String, dynamic> json) {
    return LoanEntity(
      id: (json['id'] as num).toInt(), 
      bookBarcode: json['bookBarcode'] as String, 
      bookTitle: json['bookTitle'] as String, 
      bookCategory: _parseCategory(json['bookCategory'] as String), 
      rfidUid: json['rfidUid'] as String, 
      studentName: json['studentName'] as String, 
      studentNis: json['studentNis'] as String, 
      borrowedAt: DateTime.parse(json['dueDate'] as String).toLocal(), 
      dueDate: DateTime.parse(json['dueDate'] as String).toLocal(), 
      extensionCount: (json['extensionCount'] as num).toInt(), 
      overdueDaysLive: (json['overdueDaysLive'] as num).toInt(),
    );
  }

  static List<LoanEntity> fromJoinedJsonList(List<dynamic> jsonList) {
    return jsonList.map((e) => LoanModel.fromJoinedJson(e as Map<String, dynamic>)).toList();
  }

  static LoanActionResult fromActionJson(Map<String, dynamic> json) {
    return LoanActionResult(
      loanId: json['Id'] as int, 
      dueDate: DateTime.parse(json['dueDate'] as String).toLocal(), 
      status: _parseStatus(json['status'] as String), 
      overdueDays: json['overdueDays'] as int? ?? 0, 
      extensionCount: json['extensionCount'] as int? ?? 0,
    );
  }

  static List<LoanActionResult> fromActionJsonList(List<dynamic> jsonList) {
    return jsonList.map((e) => LoanModel.fromActionJson(e as Map<String, dynamic>)).toList();
  }
}