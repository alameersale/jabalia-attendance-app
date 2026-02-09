class ApiConfig {
  // غيّر هذا الرابط لرابط السيرفر الخاص بك
  static const String baseUrl = 'https://jabalia.ps/api';
  
  // Endpoints
  static const String login = '/attendance/login';
  static const String logout = '/attendance/logout';
  static const String employees = '/attendance/employees';
  static const String session = '/attendance/session';
  static const String createSession = '/attendance/session/create';
  static const String closeSession = '/attendance/session/close';
  static const String markAttendance = '/attendance/mark';
  static const String syncAttendances = '/attendance/sync';
  static String cancelAttendance(int userId) => '/attendance/cancel/$userId';
  
  // Timeouts
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
}
