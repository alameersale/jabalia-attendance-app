import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/employee.dart';
import '../models/attendance_record.dart';

class DatabasePlatform {
  static Database? _database;

  Future<void> initialize() async {
    if (_database != null) return;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'attendance.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE employees (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        employee_number TEXT,
        id_number TEXT,
        phone TEXT,
        department_name TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        user_name TEXT NOT NULL,
        is_early INTEGER DEFAULT 0,
        timestamp TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> cacheEmployees(List<Employee> employees) async {
    final db = _database!;
    await db.delete('employees');
    
    final batch = db.batch();
    for (var emp in employees) {
      batch.insert('employees', emp.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<Employee>> getCachedEmployees({String? search}) async {
    final db = _database!;
    
    List<Map<String, dynamic>> maps;
    
    if (search != null && search.isNotEmpty) {
      maps = await db.query(
        'employees',
        where: 'name LIKE ? OR employee_number LIKE ? OR id_number LIKE ? OR phone LIKE ?',
        whereArgs: ['%$search%', '%$search%', '%$search%', '%$search%'],
        orderBy: 'name',
      );
    } else {
      maps = await db.query('employees', orderBy: 'name');
    }

    return maps.map((map) => Employee.fromMap(map)).toList();
  }

  Future<int> insertAttendanceRecord(AttendanceRecord record) async {
    final db = _database!;
    return await db.insert('attendance_records', record.toMap());
  }

  Future<List<AttendanceRecord>> getUnsyncedRecords() async {
    final db = _database!;
    final maps = await db.query(
      'attendance_records',
      where: 'is_synced = 0',
    );
    return maps.map((map) => AttendanceRecord.fromMap(map)).toList();
  }

  Future<void> markRecordsAsSynced(List<int> ids) async {
    final db = _database!;
    await db.update(
      'attendance_records',
      {'is_synced': 1},
      where: 'id IN (${ids.join(',')})',
    );
  }

  Future<List<AttendanceRecord>> getTodayRecords() async {
    final db = _database!;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    final maps = await db.query(
      'attendance_records',
      where: 'timestamp LIKE ?',
      whereArgs: ['$today%'],
    );
    return maps.map((map) => AttendanceRecord.fromMap(map)).toList();
  }

  Future<void> deleteRecord(int id) async {
    final db = _database!;
    await db.delete(
      'attendance_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearSyncedRecords() async {
    final db = _database!;
    await db.delete(
      'attendance_records',
      where: 'is_synced = 1',
    );
  }

  Future<int> getUnsyncedCount() async {
    final db = _database!;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM attendance_records WHERE is_synced = 0'
    );
    return result.first['count'] as int;
  }
}
