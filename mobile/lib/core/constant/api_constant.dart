class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://10.170.0.130:3000/api/v1';

  //Auth
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  //Users alias guru
  static String userById(int id) => 'users/$id';
  static String userReactivate(int id) => 'users/$id/reactivate';

  //Students
  static const String students = '/students';
  static String studentById(int id) => '/students/$id';
  static const String studentsImport = '/students/import';

  //Classes
  static const String classes = '/classes';
  static String classById(int id) => '/classes/$id';
  static const String users = '/users';

  //RFID
  static const String rfidRegister = '/rfid/register';
  static const String rfidModeRegister = '/rfid/mode/register';
  static String rfidUnbind(String uid) => '/rfid/$uid';

  //Attendance
  static const String attendance = '/attendance';
  static const String attendanceReport = '/attendance/report';
  static String attendanceById(int id) => '/attendance/$id';

  //Devices
  static const String devices = '/devices';
  static const String devicesheartbeat = '/devices/heartbeat';
  static String deviceLastScan(int id) => '/devices/$id/last-scan';

  //Dashboard
  static const String dashboardSummary = '/dashboard/summary';
  static const String dashboardTrend = '/dashboard/trend';


  //Books
  static const String books = '/books';
  static String bookById(int id) => '/books/$id';
  static String bookLabel(String barcode) => '/books/$barcode/label';

  //Library
  static String libraryLastScan(int deviceId) => '/library/devices/$deviceId/last-scan';
  static const String libraryBorrow = '/library/borrow';
  static const String libraryReturn = '/library/return';
  static const String libraryExtend = '/library/extend';
  static const String libraryLoans = '/library/loans';
  
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}