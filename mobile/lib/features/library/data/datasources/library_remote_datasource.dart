import 'package:dio/dio.dart';

import '../../../../core/constant/api_constant.dart';

class LibraryRemoteDatasource {
  LibraryRemoteDatasource(this._dio);

  final Dio _dio;

  Future<List<dynamic>> getBooks({String? category, String? status}) async {
    final response = await _dio.get(
      ApiConstants.books,
      queryParameters: {
        if (category != null) 'category' : category,
        if (status != null) 'status' : status,
      },
    );
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createBook(Map<String, dynamic> body) async {
    final response = await _dio.post(ApiConstants.books, data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateBook(int id, Map<String, dynamic> body) async {
    final response = await _dio.put(ApiConstants.bookById(id), data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteBook(int id) async {
    await _dio.delete(ApiConstants.bookById(id));
  }

  Future<Map<String, dynamic>?> getLastScan(int deviceId) async {
    final response = await _dio.get(ApiConstants.libraryLastScan(deviceId));
    return response.data as Map<String, dynamic>?;
  }

  Future<List<dynamic>> borrow({ required String rfidUid, required List<String> bookBarcodes}) async {
    final response = await _dio.post(
      ApiConstants.libraryBorrow,
      data: {'rfidUid' : rfidUid, 'bookBarcodes': bookBarcodes},
    );
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> returnBook(String bookBarcode) async {
    final response = await _dio.post(ApiConstants.libraryReturn, data: {'bookBarcode' : bookBarcode});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> extendLoan(String bookBarcode) async {
    final response = await _dio.post(ApiConstants.libraryExtend, data: {'bookBarcode' : bookBarcode});
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getActiveLoans() async {
    final response = await _dio.get(ApiConstants.libraryLoans);
    return response.data as List<dynamic>;
  }

  Future<List<int>> getBookLabelPdf(String barcode) async {
    final response = await _dio.get<List<int>>(
      ApiConstants.bookLabel(barcode),
      options: Options(responseType: ResponseType.bytes),
    );
    if (response.statusCode != 200 || response.data == null) {
      throw Exception('Gagal mengambil label buku');
    }
    return response.data!;
  }
}