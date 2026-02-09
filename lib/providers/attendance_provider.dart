import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../models/attendance_record.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';

class AttendanceProvider extends ChangeNotifier {
  List<Employee> _employees = [];
  List<AttendanceRecord> _todayRecords = [];
  Map<String, dynamic>? _currentSession;
  bool _isLoading = false;
  bool _isOnline = true;
  String? _error;
  String _searchQuery = '';

  List<Employee> get employees => _employees;
  List<AttendanceRecord> get todayRecords => _todayRecords;
  Map<String, dynamic>? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  bool get hasActiveSession => 
      _currentSession != null && 
      _currentSession!['session']?['status'] == 'active';

  int get presentCount => _todayRecords.length;

  // تحميل البيانات
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // فحص الاتصال
      _isOnline = await ApiService.instance.checkConnection();

      if (_isOnline) {
        // جلب الموظفين من السيرفر
        _employees = await ApiService.instance.getEmployees();
        // تخزين محلي
        await DatabaseService.instance.cacheEmployees(_employees);
        
        // جلب الجلسة الحالية
        final sessionResult = await ApiService.instance.getCurrentSession();
        if (sessionResult['success'] == true) {
          _currentSession = sessionResult['data'];
          _updateEmployeesAttendance();
        }
      } else {
        // جلب من التخزين المحلي
        _employees = await DatabaseService.instance.getCachedEmployees();
      }

      // جلب السجلات المحلية لليوم
      _todayRecords = await DatabaseService.instance.getTodayRecords();
      _updateLocalAttendance();

    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // البحث عن موظف
  Future<void> searchEmployees(String query) async {
    _searchQuery = query;
    
    if (_isOnline) {
      try {
        _employees = await ApiService.instance.getEmployees(search: query);
        _updateEmployeesAttendance();
        _updateLocalAttendance();
      } catch (e) {
        // استخدام البحث المحلي
        _employees = await DatabaseService.instance.getCachedEmployees(search: query);
        _updateLocalAttendance();
      }
    } else {
      _employees = await DatabaseService.instance.getCachedEmployees(search: query);
      _updateLocalAttendance();
    }
    
    notifyListeners();
  }

  // تسجيل حضور
  Future<bool> markAttendance(Employee employee, {bool isEarly = false}) async {
    try {
      if (_isOnline) {
        final result = await ApiService.instance.markAttendance(
          employee.id,
          isEarly: isEarly,
        );

        if (result['success'] == true) {
          employee.isPresent = true;
          employee.isEarly = isEarly;
          employee.checkInTime = isEarly ? '08:00' : _getCurrentTime();
          
          // حفظ محلي أيضاً
          await _saveLocalRecord(employee, isEarly);
          
          notifyListeners();
          return true;
        } else if (result['offline'] == true) {
          // حفظ محلي
          return await _saveOfflineRecord(employee, isEarly);
        }
        
        _error = result['message'];
        notifyListeners();
        return false;
      } else {
        // حفظ محلي
        return await _saveOfflineRecord(employee, isEarly);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // حفظ سجل محلي
  Future<bool> _saveOfflineRecord(Employee employee, bool isEarly) async {
    try {
      final record = AttendanceRecord(
        userId: employee.id,
        userName: employee.name,
        isEarly: isEarly,
        timestamp: DateTime.now(),
        isSynced: false,
      );

      await DatabaseService.instance.insertAttendanceRecord(record);
      
      employee.isPresent = true;
      employee.isEarly = isEarly;
      employee.checkInTime = isEarly ? '08:00' : _getCurrentTime();
      
      _todayRecords = await DatabaseService.instance.getTodayRecords();
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<void> _saveLocalRecord(Employee employee, bool isEarly) async {
    final record = AttendanceRecord(
      userId: employee.id,
      userName: employee.name,
      isEarly: isEarly,
      timestamp: DateTime.now(),
      isSynced: true,
    );

    await DatabaseService.instance.insertAttendanceRecord(record);
    _todayRecords = await DatabaseService.instance.getTodayRecords();
  }

  // إلغاء حضور
  Future<bool> cancelAttendance(Employee employee) async {
    try {
      if (_isOnline) {
        final result = await ApiService.instance.cancelAttendance(employee.id);
        
        if (result['success'] == true) {
          employee.isPresent = false;
          employee.isEarly = false;
          employee.checkInTime = null;
          notifyListeners();
          return true;
        }
        
        _error = result['message'];
        return false;
      }
      
      _error = 'لا يمكن الإلغاء بدون اتصال';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // إنشاء جلسة
  Future<bool> createSession(String startTime, String sessionType) async {
    if (!_isOnline) {
      _error = 'لا يمكن إنشاء جلسة بدون اتصال';
      notifyListeners();
      return false;
    }

    try {
      final result = await ApiService.instance.createSession(startTime, sessionType);
      
      if (result['success'] == true) {
        _currentSession = {'session': result['data']};
        notifyListeners();
        return true;
      }
      
      _error = result['message'];
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // إغلاق جلسة
  Future<bool> closeSession() async {
    if (!_isOnline) {
      _error = 'لا يمكن إغلاق الجلسة بدون اتصال';
      notifyListeners();
      return false;
    }

    try {
      final result = await ApiService.instance.closeSession();
      
      if (result['success'] == true) {
        await loadData();
        return true;
      }
      
      _error = result['message'];
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // تحديث حالة الاتصال
  Future<void> checkConnection() async {
    _isOnline = await ApiService.instance.checkConnection();
    notifyListeners();
  }

  // تحديث حالة الحضور من السيرفر
  void _updateEmployeesAttendance() {
    if (_currentSession == null) return;
    
    final attendances = _currentSession!['attendances'] as List? ?? [];
    
    for (var emp in _employees) {
      final attendance = attendances.firstWhere(
        (a) => a['user_id'] == emp.id,
        orElse: () => null,
      );
      
      if (attendance != null) {
        emp.isPresent = true;
        emp.isEarly = attendance['is_early'] == true || attendance['is_early'] == 1;
        emp.checkInTime = attendance['check_in_time']?.toString().substring(0, 5);
      }
    }
  }

  // تحديث حالة الحضور من السجلات المحلية
  void _updateLocalAttendance() {
    for (var emp in _employees) {
      final localRecord = _todayRecords.where((r) => r.userId == emp.id).firstOrNull;
      if (localRecord != null && !emp.isPresent) {
        emp.isPresent = true;
        emp.isEarly = localRecord.isEarly;
        emp.checkInTime = localRecord.isEarly ? '08:00' : 
            '${localRecord.timestamp.hour.toString().padLeft(2, '0')}:${localRecord.timestamp.minute.toString().padLeft(2, '0')}';
      }
    }
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
