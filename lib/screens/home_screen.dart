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
import '../widgets/custom_snackbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  Timer? _refreshTimer;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _refreshTimer?.cancel();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // تحديث البيانات عند العودة للتطبيق
      _loadData();
    }
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
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, size: 28),
            SizedBox(width: 8),
            Text('الحضور والانصراف'),
          ],
        ),
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // مؤشر المزامنة
          const SyncIndicator(),
          
          // تسجيل الخروج
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: () => _showLogoutDialog(),
          ),
        ],
      ),
      body: Consumer<AttendanceProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF0D9488),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'جاري التحميل...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            color: const Color(0xFF0D9488),
            child: Column(
              children: [
                // حالة الاتصال
                _buildConnectionStatus(provider),
                
                // بطاقة الجلسة
                const SessionCard(),
                
                // البحث
                _buildSearchBar(),
                
                // عداد الموظفين
                _buildEmployeeCounter(provider),
                
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: provider.isOnline 
              ? [const Color(0xFF10B981), const Color(0xFF059669)]
              : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        ),
        boxShadow: [
          BoxShadow(
            color: (provider.isOnline ? Colors.green : Colors.orange).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              provider.isOnline ? Icons.wifi : Icons.wifi_off,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            provider.isOnline ? '🟢 متصل بالإنترنت' : '🔴 وضع عدم الاتصال',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'ابحث بالاسم أو الرقم الوظيفي أو رقم الهوية...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF0D9488)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    context.read<AttendanceProvider>().searchEmployees('');
                    setState(() {});
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildEmployeeCounter(AttendanceProvider provider) {
    final totalEmployees = provider.employees.length;
    final presentEmployees = provider.employees.where((e) => e.isPresent).length;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildCounterChip(
            icon: Icons.people,
            label: 'الكل',
            count: totalEmployees,
            color: Colors.blue,
          ),
          const SizedBox(width: 12),
          _buildCounterChip(
            icon: Icons.check_circle,
            label: 'حاضر',
            count: presentEmployees,
            color: Colors.green,
          ),
          const SizedBox(width: 12),
          _buildCounterChip(
            icon: Icons.schedule,
            label: 'منتظر',
            count: totalEmployees - presentEmployees,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildCounterChip({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
          ],
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'لا يوجد موظفين',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'جرب البحث باسم مختلف',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    
    // التحقق من وجود جلسة نشطة
    if (!provider.hasActiveSession && provider.isOnline) {
      if (mounted) {
        CustomSnackBar.noActiveSession(context);
      }
      return;
    }
    
    final result = await provider.markAttendance(employee, isEarly: isEarly);

    if (mounted) {
      if (result['success'] == true) {
        if (result['offline'] == true) {
          CustomSnackBar.offlineSaved(context, employee.name);
        } else if (result['isEarly'] == true) {
          CustomSnackBar.earlyAttendanceSuccess(context, employee.name);
        } else {
          CustomSnackBar.attendanceSuccess(context, employee.name);
        }
      } else {
        CustomSnackBar.error(context, result['message'] ?? 'فشل في التسجيل');
      }
    }

    // تحديث عداد المزامنة
    context.read<SyncProvider>().refreshPendingCount();
  }

  Future<void> _cancelAttendance(Employee employee) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
            ),
            const SizedBox(width: 12),
            const Text('إلغاء الحضور'),
          ],
        ),
        content: Text(
          'هل تريد إلغاء حضور ${employee.name}؟',
          style: const TextStyle(fontSize: 16),
        ),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('نعم، إلغاء'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final provider = context.read<AttendanceProvider>();
    final result = await provider.cancelAttendance(employee);

    if (mounted) {
      if (result['success'] == true) {
        CustomSnackBar.attendanceCancelled(context, employee.name);
      } else {
        CustomSnackBar.error(context, result['message'] ?? 'فشل في الإلغاء');
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.logout, color: Colors.orange.shade600),
            ),
            const SizedBox(width: 12),
            const Text('تسجيل الخروج'),
          ],
        ),
        content: Consumer<SyncProvider>(
          builder: (context, sync, _) {
            if (sync.hasPendingRecords) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('هل تريد تسجيل الخروج؟'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'لديك ${sync.pendingCount} سجل غير متزامن',
                            style: TextStyle(color: Colors.orange.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            return const Text('هل تريد تسجيل الخروج؟');
          },
        ),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
  }
}
