import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/sync_provider.dart';
import '../models/employee.dart';
import '../main.dart';

/// الواجهة الرئيسية - تصميم بسيط يعمل على جميع أجهزة أندرويد
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
    if (state == AppLifecycleState.resumed) _loadData();
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
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: _buildAppBar(),
      body: Consumer<AttendanceProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return _buildLoading();
          return RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSessionCard(provider),
                  const SizedBox(height: 16),
                  _buildStats(provider),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  _buildEmployeeList(provider),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Image.asset('assets/images/logo.png', fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.account_balance, color: AppColors.primary)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('الحضور والانصراف', style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('بلدية جباليا النزلة', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.primary,
      elevation: 0,
      actions: [
        Consumer<AttendanceProvider>(
          builder: (context, prov, _) => Container(
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: prov.isOnline ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: prov.isOnline ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(prov.isOnline ? 'متصل' : 'غير متصل',
                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        Consumer<SyncProvider>(
          builder: (context, sync, _) {
            if (!sync.hasPendingRecords) return const SizedBox.shrink();
            return IconButton(
              icon: Badge(
                label: Text('${sync.pendingCount}', style: const TextStyle(fontSize: 10)),
                child: sync.isSyncing
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.cloud_upload_rounded, size: 24),
              ),
              onPressed: () => sync.syncPendingRecords(),
            );
          },
        ),
        IconButton(icon: const Icon(Icons.logout_rounded, size: 24), onPressed: _showLogoutDialog),
      ],
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text('جاري التحميل...', style: GoogleFonts.cairo(fontSize: 16, color: AppColors.gray600)),
        ],
      ),
    );
  }

  Widget _buildSessionCard(AttendanceProvider provider) {
    final session = provider.currentSession?['session'];
    final hasSession = session != null;
    final isActive = session?['status'] == 'active';
    final startTime = session?['start_time']?.toString().substring(0, 5) ?? '--:--';

    final bgColor = hasSession
        ? (isActive ? AppColors.success : AppColors.gray600)
        : AppColors.primary;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasSession ? (isActive ? Icons.play_circle_fill : Icons.stop_circle) : Icons.add_circle_outline,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasSession ? (isActive ? 'جلسة نشطة' : 'جلسة مغلقة') : 'لا توجد جلسة',
                        style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (hasSession)
                        Text('بدأت: $startTime',
                            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text('${provider.presentCount}', style: GoogleFonts.cairo(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                    Text('حاضر', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
            if (provider.isOnline) ...[
              const SizedBox(height: 16),
              if (!hasSession || !isActive)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showCreateSessionDialog,
                    icon: const Icon(Icons.play_arrow, size: 22),
                    label: Text('بدء جلسة جديدة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              if (hasSession && isActive)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showCloseSessionDialog,
                    icon: const Icon(Icons.stop, size: 22),
                    label: Text('إغلاق الجلسة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.danger,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStats(AttendanceProvider provider) {
    final total = provider.employees.length;
    final present = provider.employees.where((e) => e.isPresent).length;
    final waiting = total - present;

    return Row(
      children: [
        _statCard('الكل', total, const Color(0xFF3B82F6)),
        const SizedBox(width: 10),
        _statCard('حاضر', present, AppColors.success),
        const SizedBox(width: 10),
        _statCard('منتظر', waiting, AppColors.warning),
      ],
    );
  }

  Widget _statCard(String label, int value, Color color) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            children: [
              Text('$value', style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(label, style: GoogleFonts.cairo(fontSize: 13, color: const Color(0xFF666666))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (v) {
        _onSearchChanged(v);
        setState(() {});
      },
      cursorColor: AppColors.primary,
      style: GoogleFonts.cairo(fontSize: 15, color: const Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        hintText: 'ابحث بالاسم أو الرقم...',
        hintStyle: GoogleFonts.cairo(fontSize: 14, color: const Color(0xFF888888)),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, color: Color(0xFF666666), size: 22),
                onPressed: () {
                  _searchController.clear();
                  context.read<AttendanceProvider>().searchEmployees('');
                  setState(() {});
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildEmployeeList(AttendanceProvider provider) {
    if (provider.employees.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.people_outline_rounded, size: 56, color: AppColors.gray400),
              const SizedBox(height: 16),
              Text('لا يوجد موظفين', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray600)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('قائمة الموظفين (${provider.employees.length})', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF333333))),
        const SizedBox(height: 12),
        ...provider.employees.map((e) => _buildEmployeeCard(e, provider)),
      ],
    );
  }

  Widget _buildEmployeeCard(Employee employee, AttendanceProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: employee.isPresent ? Border.all(color: AppColors.success, width: 2) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: employee.isPresent ? AppColors.success : AppColors.gray500,
              child: Text(
                employee.name.isNotEmpty ? employee.name[0] : '?',
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(employee.name, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (employee.isPresent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: employee.isEarly ? Colors.amber.shade100 : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(employee.isEarly ? 'مبكر' : 'حاضر', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600, color: employee.isEarly ? Colors.amber.shade800 : AppColors.success)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (employee.employeeNumber != null) ...[
                        Icon(Icons.badge_outlined, size: 14, color: AppColors.gray500),
                        const SizedBox(width: 4),
                        Text(employee.employeeNumber!, style: GoogleFonts.cairo(fontSize: 13, color: AppColors.gray600)),
                        const SizedBox(width: 12),
                      ],
                      if (employee.checkInTime != null) ...[
                        Icon(Icons.access_time, size: 14, color: AppColors.gray500),
                        const SizedBox(width: 4),
                        Text(employee.checkInTime!, style: GoogleFonts.cairo(fontSize: 13, color: AppColors.gray600)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (!employee.isPresent) ...[
              _actionBtn(Icons.wb_sunny_rounded, AppColors.warning, () => _markAttendance(employee, true)),
              const SizedBox(width: 8),
              _actionBtn(Icons.check_rounded, AppColors.success, () => _markAttendance(employee, false)),
            ] else
              _actionBtn(Icons.close_rounded, AppColors.danger, () => _cancelAttendance(employee)),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onPressed) {
    return Material(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () { HapticFeedback.lightImpact(); onPressed(); },
        borderRadius: BorderRadius.circular(10),
        child: Padding(padding: const EdgeInsets.all(10), child: Icon(icon, size: 22, color: color)),
      ),
    );
  }

  Future<void> _markAttendance(Employee employee, bool isEarly) async {
    final provider = context.read<AttendanceProvider>();
    if (provider.isOnline && !provider.hasActiveSession) {
      _showSnackBar('لا توجد جلسة نشطة', isError: true);
      return;
    }
    if (!provider.isOnline && !provider.hasActiveSession) {
      _showSnackBar('لا توجد جلسة نشطة محلياً', isError: true);
      return;
    }
    final result = await provider.markAttendance(employee, isEarly: isEarly);
    if (!mounted) return;
    if (result['success'] == true) {
      HapticFeedback.mediumImpact();
      _showSnackBar(result['offline'] == true ? 'تم الحفظ محلياً' : 'تم تسجيل حضور ${employee.name}');
    } else {
      _showSnackBar(result['message'] ?? 'فشل', isError: true);
    }
    context.read<SyncProvider>().refreshPendingCount();
  }

  Future<void> _cancelAttendance(Employee employee) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إلغاء الحضور', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text('هل تريد إلغاء حضور ${employee.name}؟', style: GoogleFonts.cairo()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('لا', style: GoogleFonts.cairo())),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger), child: Text('نعم', style: GoogleFonts.cairo(color: Colors.white))),
        ],
      ),
    );
    if (ok != true) return;
    final result = await context.read<AttendanceProvider>().cancelAttendance(employee);
    if (!mounted) return;
    _showSnackBar(result['success'] == true ? 'تم الإلغاء' : (result['message'] ?? 'فشل'), isError: result['success'] != true);
  }

  void _showCreateSessionDialog() {
    String sessionType = 'attendance_only';
    final timeController = TextEditingController(
      text: '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('بدء جلسة جديدة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: timeController,
                readOnly: true,
                onTap: () async {
                  final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
                  if (time != null)
                    timeController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                },
                style: GoogleFonts.cairo(fontSize: 16, color: const Color(0xFF1A1A1A)),
                decoration: InputDecoration(
                  labelText: 'وقت البدء',
                  labelStyle: GoogleFonts.cairo(),
                  prefixIcon: const Icon(Icons.access_time_rounded, color: AppColors.primary),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              Text('نوع الجلسة:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
              RadioListTile<String>(title: Text('حضور فقط', style: GoogleFonts.cairo()), value: 'attendance_only', groupValue: sessionType, activeColor: AppColors.primary, onChanged: (v) => setState(() => sessionType = v!), contentPadding: EdgeInsets.zero),
              RadioListTile<String>(title: Text('حضور وانصراف', style: GoogleFonts.cairo()), value: 'attendance_departure', groupValue: sessionType, activeColor: AppColors.primary, onChanged: (v) => setState(() => sessionType = v!), contentPadding: EdgeInsets.zero),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.cairo())),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final result = await context.read<AttendanceProvider>().createSession(timeController.text, sessionType);
                if (mounted) _showSnackBar(result['success'] == true ? 'تم إنشاء الجلسة' : (result['message'] ?? 'فشل'), isError: result['success'] != true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              child: Text('إنشاء', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCloseSessionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إغلاق الجلسة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text('هل تريد إغلاق الجلسة؟ سيُسجّل الغياب لمن لم يحضر.', style: GoogleFonts.cairo()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.cairo())),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await context.read<AttendanceProvider>().closeSession();
              if (mounted) _showSnackBar(result['success'] == true ? 'تم إغلاق الجلسة' : (result['message'] ?? 'فشل'), isError: result['success'] != true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text('إغلاق', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Consumer<SyncProvider>(
        builder: (context, sync, _) => AlertDialog(
          title: Text('تسجيل الخروج', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('هل تريد تسجيل الخروج؟', style: GoogleFonts.cairo()),
              if (sync.hasPendingRecords) ...[
                const SizedBox(height: 12),
                Text('لديك ${sync.pendingCount} سجل غير متزامن', style: GoogleFonts.cairo(fontSize: 13, color: AppColors.warningDark)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.cairo())),
            ElevatedButton(
              onPressed: () { Navigator.pop(ctx); context.read<AuthProvider>().logout(); },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              child: Text('خروج', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo(fontWeight: FontWeight.w500)),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
