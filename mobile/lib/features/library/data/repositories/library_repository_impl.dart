import '../../domain/entities/book_entity.dart';
import '../../domain/entities/loan_entity.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/library_remote_datasource.dart';
import '../models/book_model.dart';
import '../models/loan_model.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  LibraryRepositoryImpl(this._remote);
 
  final LibraryRemoteDatasource _remote;
 
  String? _categoryToApi(BookCategory? category) {
    if (category == null) return null;
    return BookModel.categoryToApi(category);
  }
 
  String? _statusToApi(BookStatus? status) {
    if (status == null) return null;
    return status == BookStatus.tersedia ? 'TERSEDIA' : 'DIPINJAM';
  }
 
  @override
  Future<List<BookEntity>> getBooks({BookCategory? category, BookStatus? status}) async {
    final jsonList = await _remote.getBooks(
      category: _categoryToApi(category),
      status: _statusToApi(status),
    );
    return BookModel.fromJsonList(jsonList);
  }
 
  @override
  Future<BookEntity> createBook({
    required String barcode,
    required String title,
    required BookCategory category,
  }) async {
    final json = await _remote.createBook({
      'barcode': barcode,
      'title': title,
      'category': BookModel.categoryToApi(category),
    });
    return BookModel.fromJson(json);
  }
 
  @override
  Future<BookEntity> updateBook(int id, {String? title, BookCategory? category}) async {
    final json = await _remote.updateBook(id, {
      if (title != null) 'title': title,
      if (category != null) 'category': BookModel.categoryToApi(category),
    });
    return BookModel.fromJson(json);
  }
 
  @override
  Future<void> deleteBook(int id) => _remote.deleteBook(id);
 
  @override
  Future<LibraryScanResult?> getLastScan(int deviceId) async {
    final json = await _remote.getLastScan(deviceId);
    if (json == null || json['rfidUid'] == null) return null;
    return LibraryScanResult(
      rfidUid: json['rfidUid'] as String,
      scannedAt: DateTime.parse(json['scannedAt'] as String).toLocal(),
    );
  }
 
  @override
  Future<List<LoanActionResult>> borrow({required String rfidUid, required List<String> bookBarcodes}) async {
    final jsonList = await _remote.borrow(rfidUid: rfidUid, bookBarcodes: bookBarcodes);
    return LoanModel.fromActionJsonList(jsonList);
  }
 
  @override
  Future<LoanActionResult> returnBook(String bookBarcode) async {
    final json = await _remote.returnBook(bookBarcode);
    return LoanModel.fromActionJson(json);
  }
 
  @override
  Future<LoanActionResult> extendLoan(String bookBarcode) async {
    final json = await _remote.extendLoan(bookBarcode);
    return LoanModel.fromActionJson(json);
  }
 
  @override
  Future<List<LoanEntity>> getActiveLoans() async {
    final jsonList = await _remote.getActiveLoans();
    return LoanModel.fromJoinedJsonList(jsonList);
  }

  @override
  Future<List<int>> getBookLabelPdf(String barcode) {
    return _remote.getBookLabelPdf(barcode);
  }
}