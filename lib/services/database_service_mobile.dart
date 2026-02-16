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
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
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

    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY,
        session_date TEXT NOT NULL,
        start_time TEXT NOT NULL,
        session_type TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        device_id TEXT,
        UNIQUE(session_date, device_id)
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sessions (
          id INTEGER PRIMARY KEY,
          session_date TEXT NOT NULL,
          start_time TEXT NOT NULL,
          session_type TEXT NOT NULL,
          status TEXT NOT NULL,
          created_at TEXT NOT NULL,
          device_id TEXT,
          UNIQUE(session_date, device_id)
        )
      ''');
    }
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

  // ==================== Sessions ====================

  Future<void> saveSession(Map<String, dynamic> session) async {
    final db = _database!;
    final deviceId = await _getDeviceId();
    
    await db.insert(
      'sessions',
      {
        'id': session['id'],
        'session_date': session['session_date'] ?? DateTime.now().toIso8601String().substring(0, 10),
        'start_time': session['start_time'],
        'session_type': session['session_type'],
        'status': session['status'],
        'created_at': DateTime.now().toIso8601String(),
        'device_id': deviceId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getCurrentSession() async {
    final db = _database!;
    final deviceId = await _getDeviceId();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    final maps = await db.query(
      'sessions',
      where: 'session_date = ? AND device_id = ?',
      whereArgs: [today, deviceId],
    );
    
    if (maps.isNotEmpty) {
      final session = maps.first;
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
    final db = _database!;
    await db.update(
      'sessions',
      {'status': status},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> clearOldSessions() async {
    final db = _database!;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await db.delete(
      'sessions',
      where: 'session_date < ?',
      whereArgs: [today],
    );
  }

  Future<String> _getDeviceId() async {
    // استخدام معرف فريد للجهاز
    return 'mobile_device';
  }
}
