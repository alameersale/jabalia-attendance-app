import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../models/attendance_record.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class AttendanceProvider extends ChangeNotifier {
  List<Employee> _employees = [];
  List<AttendanceRecord> _todayRecords = [];
  Map<String, dynamic>? _currentSession;
  bool _isLoading = false;
  bool _isOnline = true;
  bool _wasOnline = true; // لتتبع تغير حالة الاتصال
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

  final NotificationService _notificationService = NotificationService.instance;

  // تحميل البيانات
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // فحص الاتصال
      final wasOnlineBefore = _isOnline;
      _isOnline = await ApiService.instance.checkConnection();
      
      // إشعار بتغير حالة الاتصال
      if (wasOnlineBefore != _isOnline) {
        if (_isOnline) {
          await _notificationService.showConnectionRestored();
        } else {
          await _notificationService.showConnectionLost();
        }
      }
      _wasOnline = _isOnline;

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
        } else {
          // إذا لم توجد جلسة على السيرفر، جرب الجلسة المحلية
          final localSession = await DatabaseService.instance.getCurrentSession();
          if (localSession != null && localSession['session']?['status'] == 'active') {
            _currentSession = localSession;
            _updateLocalAttendance();
          }
        }
      } else {
        // جلب من التخزين المحلي
        _employees = await DatabaseService.instance.getCachedEmployees();
        
        // جلب الجلسة المحلية
        final localSession = await DatabaseService.instance.getCurrentSession();
        if (localSession != null && localSession['session']?['status'] == 'active') {
          _currentSession = localSession;
        } else {
          _currentSession = null;
        }
      }

      // جلب السجلات المحلية لليوم
      _todayRecords = await DatabaseService.instance.getTodayRecords();
      _updateLocalAttendance();

    } catch (e) {
      _error = e.toString();
      
      // في حالة الخطأ، جرب استخدام البيانات المحلية
      try {
        _employees = await DatabaseService.instance.getCachedEmployees();
        final localSession = await DatabaseService.instance.getCurrentSession();
        if (localSession != null && localSession['session']?['status'] == 'active') {
          _currentSession = localSession;
        } else {
          _currentSession = null;
        }
        _todayRecords = await DatabaseService.instance.getTodayRecords();
        _updateLocalAttendance();
      } catch (e2) {
        print('Error loading local data: $e2');
      }
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
  Future<Map<String, dynamic>> markAttendance(Employee employee, {bool isEarly = false}) async {
    try {
      await _notificationService.vibrateTap(); // اهتزاز عند الضغط
      
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
          
          // إشعار نجاح
          if (isEarly) {
            await _notificationService.showEarlyAttendanceSuccess(employee.name);
          } else {
            await _notificationService.showAttendanceSuccess(employee.name);
          }
          
          notifyListeners();
          return {'success': true, 'offline': false, 'isEarly': isEarly};
        } else if (result['offline'] == true) {
          // حفظ محلي
          final saved = await _saveOfflineRecord(employee, isEarly);
          if (saved) {
            await _notificationService.showOfflineSaved(employee.name);
            return {'success': true, 'offline': true, 'isEarly': isEarly};
          }
        }
        
        _error = result['message'];
        await _notificationService.vibrateError();
        notifyListeners();
        return {'success': false, 'message': result['message']};
      } else {
        // حفظ محلي
        final saved = await _saveOfflineRecord(employee, isEarly);
        if (saved) {
          await _notificationService.showOfflineSaved(employee.name);
          return {'success': true, 'offline': true, 'isEarly': isEarly};
        }
        return {'success': false, 'message': 'فشل الحفظ المحلي'};
      }
    } catch (e) {
      _error = e.toString();
      await _notificationService.vibrateError();
      notifyListeners();
      return {'success': false, 'message': e.toString()};
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
  Future<Map<String, dynamic>> cancelAttendance(Employee employee) async {
    try {
      await _notificationService.vibrateTap();
      
      if (_isOnline) {
        final result = await ApiService.instance.cancelAttendance(employee.id);
        
        if (result['success'] == true) {
          employee.isPresent = false;
          employee.isEarly = false;
          employee.checkInTime = null;
          
          await _notificationService.showAttendanceCancelled(employee.name);
          
          notifyListeners();
          return {'success': true};
        }
        
        _error = result['message'];
        await _notificationService.vibrateError();
        return {'success': false, 'message': result['message']};
      }
      
      _error = 'لا يمكن الإلغاء بدون اتصال';
      await _notificationService.vibrateWarning();
      return {'success': false, 'message': 'لا يمكن الإلغاء بدون اتصال'};
    } catch (e) {
      _error = e.toString();
      await _notificationService.vibrateError();
      return {'success': false, 'message': e.toString()};
    }
  }

  // إنشاء جلسة
  Future<Map<String, dynamic>> createSession(String startTime, String sessionType) async {
    if (!_isOnline) {
      _error = 'لا يمكن إنشاء جلسة بدون اتصال';
      await _notificationService.vibrateWarning();
      notifyListeners();
      return {'success': false, 'message': 'لا يمكن إنشاء جلسة بدون اتصال'};
    }

    try {
      await _notificationService.vibrateTap();
      
      final result = await ApiService.instance.createSession(startTime, sessionType);
      
      if (result['success'] == true) {
        final sessionData = result['data'];
        _currentSession = {'session': sessionData};
        
        // حفظ الجلسة محلياً
        try {
          await DatabaseService.instance.saveSession(sessionData);
        } catch (e) {
          // تجاهل خطأ الحفظ المحلي
          print('Error saving session locally: $e');
        }
        
        await _notificationService.showSessionStarted();
        
        notifyListeners();
        return {'success': true};
      }
      
      _error = result['message'];
      await _notificationService.vibrateError();
      notifyListeners();
      return {'success': false, 'message': result['message']};
    } catch (e) {
      _error = e.toString();
      await _notificationService.vibrateError();
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  // إغلاق جلسة
  Future<Map<String, dynamic>> closeSession() async {
    if (!_isOnline) {
      _error = 'لا يمكن إغلاق الجلسة بدون اتصال';
      await _notificationService.vibrateWarning();
      notifyListeners();
      return {'success': false, 'message': 'لا يمكن إغلاق الجلسة بدون اتصال'};
    }

    try {
      await _notificationService.vibrateTap();
      
      final result = await ApiService.instance.closeSession();
      
      if (result['success'] == true) {
        final presentCount = result['data']?['present_count'] ?? 0;
        final absentCount = result['data']?['absent_count'] ?? 0;
        
        // تحديث حالة الجلسة المحلية
        if (_currentSession != null && _currentSession!['session'] != null) {
          try {
            await DatabaseService.instance.updateSessionStatus(
              _currentSession!['session']['id'],
              'closed',
            );
          } catch (e) {
            print('Error updating session status locally: $e');
          }
        }
        
        await _notificationService.showSessionClosed(presentCount, absentCount);
        
        await loadData();
        return {'success': true, 'presentCount': presentCount, 'absentCount': absentCount};
      }
      
      _error = result['message'];
      await _notificationService.vibrateError();
      notifyListeners();
      return {'success': false, 'message': result['message']};
    } catch (e) {
      _error = e.toString();
      await _notificationService.vibrateError();
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  // تحديث حالة الاتصال
  Future<void> checkConnection() async {
    final wasOnlineBefore = _isOnline;
    _isOnline = await ApiService.instance.checkConnection();
    
    // إشعار بتغير حالة الاتصال
    if (wasOnlineBefore != _isOnline) {
      if (_isOnline) {
        await _notificationService.showConnectionRestored();
      } else {
        await _notificationService.showConnectionLost();
      }
    }
    
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
