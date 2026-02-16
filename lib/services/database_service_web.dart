import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/employee.dart';
import '../models/attendance_record.dart';

class DatabasePlatform {
  SharedPreferences? _prefs;
  int _nextId = 1;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _nextId = _prefs!.getInt('next_record_id') ?? 1;
  }

  Future<void> cacheEmployees(List<Employee> employees) async {
    final data = employees.map((e) => e.toMap()).toList();
    await _prefs!.setString('cached_employees', jsonEncode(data));
  }

  Future<List<Employee>> getCachedEmployees({String? search}) async {
    final data = _prefs!.getString('cached_employees');
    if (data == null) return [];
    
    final List<dynamic> list = jsonDecode(data);
    List<Employee> employees = list.map((map) => Employee.fromMap(Map<String, dynamic>.from(map))).toList();
    
    if (search != null && search.isNotEmpty) {
      final query = search.toLowerCase();
      employees = employees.where((emp) =>
        emp.name.toLowerCase().contains(query) ||
        (emp.employeeNumber?.toLowerCase().contains(query) ?? false) ||
        (emp.idNumber?.toLowerCase().contains(query) ?? false) ||
        (emp.phone?.toLowerCase().contains(query) ?? false)
      ).toList();
    }
    
    employees.sort((a, b) => a.name.compareTo(b.name));
    return employees;
  }

  Future<int> insertAttendanceRecord(AttendanceRecord record) async {
    final records = await _getAllRecords();
    final newRecord = AttendanceRecord(
      id: _nextId,
      userId: record.userId,
      userName: record.userName,
      isEarly: record.isEarly,
      timestamp: record.timestamp,
      isSynced: record.isSynced,
    );
    records.add(newRecord);
    await _saveAllRecords(records);
    
    _nextId++;
    await _prefs!.setInt('next_record_id', _nextId);
    
    return newRecord.id!;
  }

  Future<List<AttendanceRecord>> getUnsyncedRecords() async {
    final records = await _getAllRecords();
    return records.where((r) => !r.isSynced).toList();
  }

  Future<void> markRecordsAsSynced(List<int> ids) async {
    final records = await _getAllRecords();
    for (var record in records) {
      if (ids.contains(record.id)) {
        record.isSynced = true;
      }
    }
    await _saveAllRecords(records);
  }

  Future<List<AttendanceRecord>> getTodayRecords() async {
    final records = await _getAllRecords();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return records.where((r) => r.timestamp.toIso8601String().startsWith(today)).toList();
  }

  Future<void> deleteRecord(int id) async {
    final records = await _getAllRecords();
    records.removeWhere((r) => r.id == id);
    await _saveAllRecords(records);
  }

  Future<void> clearSyncedRecords() async {
    final records = await _getAllRecords();
    records.removeWhere((r) => r.isSynced);
    await _saveAllRecords(records);
  }

  Future<int> getUnsyncedCount() async {
    final records = await _getAllRecords();
    return records.where((r) => !r.isSynced).length;
  }

  // ==================== Sessions ====================

  Future<void> saveSession(Map<String, dynamic> session) async {
    final sessions = await _getAllSessions();
    final deviceId = await _getDeviceId();
    
    final newSession = {
      'id': session['id'],
      'session_date': session['session_date'] ?? DateTime.now().toIso8601String().substring(0, 10),
      'start_time': session['start_time'],
      'session_type': session['session_type'],
      'status': session['status'],
      'created_at': DateTime.now().toIso8601String(),
      'device_id': deviceId,
    };
    
    // تحديث أو إضافة الجلسة
    sessions.removeWhere((s) => s['session_date'] == newSession['session_date'] && s['device_id'] == deviceId);
    sessions.add(newSession);
    
    await _saveAllSessions(sessions);
  }

  Future<Map<String, dynamic>?> getCurrentSession() async {
    final sessions = await _getAllSessions();
    final deviceId = await _getDeviceId();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    final session = sessions.firstWhere(
      (s) => s['session_date'] == today && s['device_id'] == deviceId,
      orElse: () => null,
    );
    
    if (session != null) {
      return {
        'id': session['id'],
        'session': {
          'id': session['id'],
          'session_date': session['session_date'],
          'start_time': session['start_time'],
          'session_type': session['session_type'],
          'status': session['status'],
        },
      };
    }
    return null;
  }

  Future<void> updateSessionStatus(int sessionId, String status) async {
    final sessions = await _getAllSessions();
    for (var session in sessions) {
      if (session['id'] == sessionId) {
        session['status'] = status;
        break;
      }
    }
    await _saveAllSessions(sessions);
  }

  Future<void> clearOldSessions() async {
    final sessions = await _getAllSessions();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    sessions.removeWhere((s) => s['session_date'] != today);
    await _saveAllSessions(sessions);
  }

  Future<List<Map<String, dynamic>>> _getAllSessions() async {
    final data = _prefs!.getString('sessions');
    if (data == null) return [];
    
    final List<dynamic> list = jsonDecode(data);
    return list.map((map) => Map<String, dynamic>.from(map)).toList();
  }

  Future<void> _saveAllSessions(List<Map<String, dynamic>> sessions) async {
    await _prefs!.setString('sessions', jsonEncode(sessions));
  }

  Future<String> _getDeviceId() async {
    return 'web_device';
  }

  Future<List<AttendanceRecord>> _getAllRecords() async {
    final data = _prefs!.getString('attendance_records');
    if (data == null) return [];
    
    final List<dynamic> list = jsonDecode(data);
    return list.map((map) => AttendanceRecord.fromMap(Map<String, dynamic>.from(map))).toList();
  }

  Future<void> _saveAllRecords(List<AttendanceRecord> records) async {
    final data = records.map((r) => r.toMap()).toList();
    await _prefs!.setString('attendance_records', jsonEncode(data));
  }
}
