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
