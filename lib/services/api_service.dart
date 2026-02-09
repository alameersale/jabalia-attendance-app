import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '../config/api_config.dart';
import '../models/employee.dart';
import '../models/attendance_record.dart';

class ApiService {
  static final ApiService instance = ApiService._init();
  ApiService._init();

  String? get _token => Hive.box('settings').get('token');

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ==================== Auth ====================

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 30));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.logout}'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      // Ignore logout errors
    }
  }

  // ==================== Employees ====================

  Future<List<Employee>> getEmployees({String? search}) async {
    try {
      String url = '${ApiConfig.baseUrl}${ApiConfig.employees}';
      if (search != null && search.isNotEmpty) {
        url += '?search=$search';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);
      
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((e) => Employee.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('فشل في جلب الموظفين: $e');
    }
  }

  // ==================== Session ====================

  Future<Map<String, dynamic>> getCurrentSession() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.session}'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال'};
    }
  }

  Future<Map<String, dynamic>> createSession(String startTime, String sessionType) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.session}'),
        headers: _headers,
        body: jsonEncode({
          'start_time': startTime,
          'session_type': sessionType,
        }),
      ).timeout(const Duration(seconds: 30));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال'};
    }
  }

  Future<Map<String, dynamic>> closeSession() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.closeSession}'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال'};
    }
  }

  // ==================== Attendance ====================

  Future<Map<String, dynamic>> markAttendance(int userId, {bool isEarly = false}) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.markAttendance}'),
        headers: _headers,
        body: jsonEncode({
          'user_id': userId,
          'is_early': isEarly,
        }),
      ).timeout(const Duration(seconds: 30));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال', 'offline': true};
    }
  }

  Future<Map<String, dynamic>> syncAttendances(List<AttendanceRecord> records) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.syncAttendances}'),
        headers: _headers,
        body: jsonEncode({
          'records': records.map((r) => r.toSyncJson()).toList(),
        }),
      ).timeout(const Duration(seconds: 60));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال'};
    }
  }

  Future<Map<String, dynamic>> cancelAttendance(int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cancelAttendance(userId)}'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال'};
    }
  }

  // ==================== Connectivity Check ====================

  Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.session}'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
