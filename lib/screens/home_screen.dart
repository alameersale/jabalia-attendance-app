import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/sync_provider.dart';
import '../models/employee.dart';
import '../widgets/employee_card.dart';
import '../widgets/session_card.dart';
import '../widgets/sync_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  Timer? _refreshTimer;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshTimer?.cancel();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    await context.read<AttendanceProvider>().loadData();
    await context.read<SyncProvider>().refreshPendingCount();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      context.read<AttendanceProvider>().checkConnection();
      context.read<SyncProvider>().syncPendingRecords();
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      context.read<AttendanceProvider>().searchEmployees(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الحضور والانصراف'),
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        actions: [
          // مؤشر المزامنة
          const SyncIndicator(),
          
          // تسجيل الخروج
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(),
          ),
        ],
      ),
      body: Consumer<AttendanceProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: Column(
              children: [
                // حالة الاتصال
                _buildConnectionStatus(provider),
                
                // بطاقة الجلسة
                const SessionCard(),
                
                // البحث
                _buildSearchBar(),
                
                // قائمة الموظفين
                Expanded(
                  child: _buildEmployeeList(provider),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionStatus(AttendanceProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: provider.isOnline ? Colors.green.shade100 : Colors.orange.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            provider.isOnline ? Icons.wifi : Icons.wifi_off,
            size: 18,
            color: provider.isOnline ? Colors.green.shade700 : Colors.orange.shade700,
          ),
          const SizedBox(width: 8),
          Text(
            provider.isOnline ? 'متصل بالإنترنت' : 'وضع عدم الاتصال',
            style: TextStyle(
              color: provider.isOnline ? Colors.green.shade700 : Colors.orange.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'ابحث بالاسم أو الرقم الوظيفي...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<AttendanceProvider>().searchEmployees('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }

  Widget _buildEmployeeList(AttendanceProvider provider) {
    if (provider.employees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'لا يوجد موظفين',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: provider.employees.length,
      itemBuilder: (context, index) {
        final employee = provider.employees[index];
        return EmployeeCard(
          employee: employee,
          onMarkPresent: () => _markAttendance(employee, false),
          onMarkEarly: () => _markAttendance(employee, true),
          onCancel: () => _cancelAttendance(employee),
        );
      },
    );
  }

  Future<void> _markAttendance(Employee employee, bool isEarly) async {
    final provider = context.read<AttendanceProvider>();
    final success = await provider.markAttendance(employee, isEarly: isEarly);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'تم تسجيل حضور ${employee.name}${isEarly ? ' (مبكر)' : ''}'
                : provider.error ?? 'فشل في التسجيل',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // تحديث عداد المزامنة
    context.read<SyncProvider>().refreshPendingCount();
  }

  Future<void> _cancelAttendance(Employee employee) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء الحضور'),
        content: Text('هل تريد إلغاء حضور ${employee.name}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لا'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('نعم، إلغاء'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final provider = context.read<AttendanceProvider>();
    final success = await provider.cancelAttendance(employee);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'تم إلغاء الحضور' : provider.error ?? 'فشل في الإلغاء',
          ),
          backgroundColor: success ? Colors.orange : Colors.red,
        ),
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
  }
}
