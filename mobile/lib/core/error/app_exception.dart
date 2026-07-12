sealed class AppException implements Exception {
  AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

//401(redirect)
class UnauthorizedException extends AppException {
  UnauthorizedException([super.message = 'Sesi berakhir, silahkan login ulang']);
}

//403(forbidden)
class ForbiddenException extends AppException {
  ForbiddenException([super.message = 'Anda tidak memilik akses']);
}

//404(not found)
class NotFoundException extends AppException {
  NotFoundException([super.message = 'Data tidak ditemukan']);
}

//409(conflict)
class ConflictException extends AppException {
  ConflictException([super.message = 'Data konflik dengan yang sudah ada']);
}

class NetworkException extends AppException {
  NetworkException([super.message = 'Gagal terhubung ke server']);
}

class ServerException extends AppException {
  ServerException([super.message = 'Terjadi kesalahan pada server']);
}