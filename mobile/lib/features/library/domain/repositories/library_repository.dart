import '../entities/book_entity.dart';
import '../entities/loan_entity.dart';

abstract class LibraryRepository {
  Future<List<BookEntity>> getBooks({
    BookCategory? category,
    BookStatus? status,
  });

  Future<BookEntity> createBook({
    required String barcode,
    required String title,
    required BookCategory category,
  });

  Future<BookEntity> updateBook(int id, {String? title, BookCategory? category});

  Future<void> deleteBook(int id);

  Future<LibraryScanResult?> getLastScan(int deviceId);
  Future<List<LoanActionResult>> borrow({
    required String rfidUid,
    required List<String> bookBarcodes 
  });
  Future<LoanActionResult> returnBook(String bookBarcode);
  Future<LoanActionResult> extendLoan(String bookBarcode);
  Future<List<LoanEntity>> getActiveLoans();
  
  Future<List<int>> getBookLabelPdf(String barcode);
}


