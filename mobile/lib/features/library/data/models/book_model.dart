import '../../domain/entities/book_entity.dart';

class BookModel {
  static BookCategory _parseCategory(String raw) => switch(raw) {
    'UMUM' => BookCategory.umum,
    'PELAJARAN' => BookCategory.pelajaran,
    _ => throw FormatException('category tidak dikenali: $raw'),
  };

  static BookStatus _parseStatus(String raw) => switch(raw) {
    'TERSEDIA' => BookStatus.tersedia,
    'DIPINJAM' => BookStatus.dipinjam,
    _ => throw FormatException('status buku tidak dikenali: $raw'),
  };

  static String categoryToApi(BookCategory category) => category == BookCategory.umum ? 'UMUM' : 'PELAJARAN';

  static BookEntity fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int?;
    final barcode = json['barcode'] as String?;
    final title = json['title'] as String?;
    final categoryRaw = json['category'] as String?;
    final statusRaw = json['status'] as String?;

    if (id == null || barcode == null || title == null || categoryRaw == null || statusRaw == null) {
      throw const FormatException('Response /books tidak sesuai kontrak');
    }

    return BookEntity(
      id: id, 
      barcode: 
      barcode, 
      title: title, 
      category: _parseCategory(categoryRaw), 
      status: _parseStatus(statusRaw)
    );
  }

  static List<BookEntity> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((e) => BookModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}