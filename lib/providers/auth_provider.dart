import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  String? _userName;
  String? _userEmail;
  int?    _userId;
  String? _error;

  bool    get isLoading       => _isLoading;
  bool    get isAuthenticated => _isAuthenticated;
  String? get userName        => _userName;
  String? get userEmail       => _userEmail;
  int?    get userId          => _userId;
  String? get error           => _error;

  AuthProvider() {
    _restoreSession();
  }

  /// استعادة الجلسة المحفوظة محلياً — بدون أي اتصال بالشبكة
  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null && token.isNotEmpty) {
        _isAuthenticated = true;
        _userName  = prefs.getString('auth_user_name');
        _userEmail = prefs.getString('auth_user_email');
        _userId    = prefs.getInt('auth_user_id');
      }
    } catch (_) {
      // في حالة فشل القراءة، نعرض شاشة الدخول
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// تسجيل الدخول عبر API
  Future<bool> login(String employeeNumber, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.instance.login(employeeNumber, password);

      if (result['success'] == true) {
        final data = result['data'];

        // استخراج التوكن — يدعم هياكل مختلفة للاستجابة
        final String? token = data is Map
            ? (data['token'] ?? data['access_token'])?.toString()
            : null;

        final userMap = data is Map ? (data['user'] ?? data) : {};
        final String userName  = (userMap['name']  ?? userMap['username'] ?? '').toString();
        final String userEmail = (userMap['email']  ?? '').toString();
        final int    userId    = int.tryParse(userMap['id']?.toString() ?? '0') ?? 0;

        // حفظ الجلسة محلياً
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token',      token ?? '');
        await prefs.setString('auth_user_name',  userName);
        await prefs.setString('auth_user_email', userEmail);
        await prefs.setInt   ('auth_user_id',    userId);

        _isAuthenticated = true;
        _userName  = userName;
        _userEmail = userEmail;
        _userId    = userId;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error     = (result['message'] ?? 'بيانات الدخول غير صحيحة').toString();
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error     = 'خطأ في الاتصال بالسيرفر';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    try {
      await ApiService.instance.logout();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user_name');
    await prefs.remove('auth_user_email');
    await prefs.remove('auth_user_id');

    _isAuthenticated = false;
    _userName  = null;
    _userEmail = null;
    _userId    = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
