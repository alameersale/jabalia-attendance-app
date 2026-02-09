import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/employee.dart';
import '../models/attendance_record.dart';

// Conditional import for sqflite
import 'database_service_mobile.dart' if (dart.library.html) 'database_service_web.dart' as platform;

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  DatabaseService._init();

  final platform.DatabasePlatform _platform = platform.DatabasePlatform();

  Future<void> get database async {
    await _platform.initialize();
  }

  // ==================== Employees ====================

  Future<void> cacheEmployees(List<Employee> employees) async {
    await _platform.cacheEmployees(employees);
  }

  Future<List<Employee>> getCachedEmployees({String? search}) async {
    return await _platform.getCachedEmployees(search: search);
  }

  // ==================== Attendance Records ====================

  Future<int> insertAttendanceRecord(AttendanceRecord record) async {
    return await _platform.insertAttendanceRecord(record);
  }

  Future<List<AttendanceRecord>> getUnsyncedRecords() async {
    return await _platform.getUnsyncedRecords();
  }

  Future<void> markRecordsAsSynced(List<int> ids) async {
    await _platform.markRecordsAsSynced(ids);
  }

  Future<List<AttendanceRecord>> getTodayRecords() async {
    return await _platform.getTodayRecords();
  }

  Future<void> deleteRecord(int id) async {
    await _platform.deleteRecord(id);
  }

  Future<void> clearSyncedRecords() async {
    await _platform.clearSyncedRecords();
  }

  Future<int> getUnsyncedCount() async {
    return await _platform.getUnsyncedCount();
  }
}
