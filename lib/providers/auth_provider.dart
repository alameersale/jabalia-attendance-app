import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  String? _userName;
  String? _userEmail;
  String? _error;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get error => _error;

  AuthProvider() {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final box = Hive.box('settings');
    final token = box.get('token');
    final name = box.get('userName');
    final email = box.get('userEmail');

    if (token != null) {
      _isAuthenticated = true;
      _userName = name;
      _userEmail = email;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.instance.login(email, password);

      if (result['success'] == true) {
        final data = result['data'];
        final box = Hive.box('settings');
        
        await box.put('token', data['token']);
        await box.put('userName', data['user']['name']);
        await box.put('userEmail', data['user']['email']);
        await box.put('userId', data['user']['id']);

        _isAuthenticated = true;
        _userName = data['user']['name'];
        _userEmail = data['user']['email'];
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'فشل تسجيل الدخول';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'خطأ في الاتصال بالسيرفر';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await ApiService.instance.logout();
    
    final box = Hive.box('settings');
    await box.delete('token');
    await box.delete('userName');
    await box.delete('userEmail');
    await box.delete('userId');

    _isAuthenticated = false;
    _userName = null;
    _userEmail = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
