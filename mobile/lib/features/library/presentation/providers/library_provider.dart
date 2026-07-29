import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/library_remote_datasource.dart';
import '../../data/repositories/library_repository_impl.dart';
import '../../domain/entities/book_entity.dart';
import '../../domain/entities/loan_entity.dart';
import '../../domain/repositories/library_repository.dart';

final libraryRemoteDatasourceProvider = Provider<LibraryRemoteDatasource>((ref) {
  return LibraryRemoteDatasource(ref.watch(dioProvider));
});

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepositoryImpl(ref.watch(libraryRemoteDatasourceProvider));
});

final booksListProvider =
    FutureProvider.autoDispose.family<List<BookEntity>, BookStatus?>((ref, status) {
  return ref.watch(libraryRepositoryProvider).getBooks(status: status);
});

final activeLoansProvider = FutureProvider.autoDispose<List<LoanEntity>>((ref) {
  return ref.watch(libraryRepositoryProvider).getActiveLoans();
});

final libraryTransactionControllerProvider =
    AsyncNotifierProvider.autoDispose<LibraryTransactionController, void>(
  LibraryTransactionController.new,
);

class LibraryTransactionController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<List<LoanActionResult>?> borrow({
    required String rfidUid,
    required List<String> bookBarcodes,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return ref.read(libraryRepositoryProvider).borrow(rfidUid: rfidUid, bookBarcodes: bookBarcodes);
    });
    state = result.hasError ? AsyncError(result.error!, result.stackTrace!) : const AsyncData(null);
    if (!result.hasError) {
      ref.invalidate(activeLoansProvider);
      ref.invalidate(booksListProvider);
    }
    return result.valueOrNull;
  }

  Future<LoanActionResult?> returnBook(String bookBarcode) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return ref.read(libraryRepositoryProvider).returnBook(bookBarcode);
    });
    state = result.hasError ? AsyncError(result.error!, result.stackTrace!) : const AsyncData(null);
    if (!result.hasError) {
      ref.invalidate(activeLoansProvider);
      ref.invalidate(booksListProvider);
    }
    return result.valueOrNull;
  }

  Future<LoanActionResult?> extendLoan(String bookBarcode) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return ref.read(libraryRepositoryProvider).extendLoan(bookBarcode);
    });
    state = result.hasError ? AsyncError(result.error!, result.stackTrace!) : const AsyncData(null);
    if (!result.hasError) ref.invalidate(activeLoansProvider);
    return result.valueOrNull;
  }
}

final bookControllerProvider =
    AsyncNotifierProvider.autoDispose<BookController, void>(BookController.new);

class BookController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> createBook({
    required String barcode,
    required String title,
    required BookCategory category,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return ref.read(libraryRepositoryProvider).createBook(barcode: barcode, title: title, category: category);
    });
    state = result.hasError ? AsyncError(result.error!, result.stackTrace!) : const AsyncData(null);
    if (!result.hasError) ref.invalidate(booksListProvider);
    return !result.hasError;
  }

  Future<bool> updateBook(int id, {String? title, BookCategory? category}) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return ref.read(libraryRepositoryProvider).updateBook(id, title: title, category: category);
    });
    state = result.hasError ? AsyncError(result.error!, result.stackTrace!) : const AsyncData(null);
    if (!result.hasError) ref.invalidate(booksListProvider);
    return !result.hasError;
  }

  Future<bool> deleteBook(int id) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return ref.read(libraryRepositoryProvider).deleteBook(id);
    });
    state = result.hasError ? AsyncError(result.error!, result.stackTrace!) : const AsyncData(null);
    if (!result.hasError) ref.invalidate(booksListProvider);
    return !result.hasError;
  }
}