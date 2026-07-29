enum BookCategory { umum, pelajaran }

enum BookStatus { tersedia, dipinjam }

class BookEntity {
  const BookEntity({
    required this.id,
    required this.barcode,
    required this.title,
    required this.category,
    required this.status,
  });

  final int id;
  final String barcode;
  final String title;
  final BookCategory category;
  final BookStatus status;
}