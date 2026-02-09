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
      backgroundColor: AppColors.gray50,
      body: Consumer<AttendanceProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return _buildLoadingScreen();
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.primary,
            backgroundColor: Colors.white,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // Header
                _buildAppBar(provider),
                
                // Content
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // بطاقة الجلسة
                      _buildSessionCard(provider),
                      
                      // إحصائيات سريعة
                      _buildQuickStats(provider),
                      
                      // البحث
                      _buildSearchBar(),
                    ],
                  ),
                ),
                
                // قائمة الموظفين
                _buildEmployeeList(provider),
                
                // مسافة سفلية
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
            AppColors.primaryDark,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // شعار
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.network(
                    'https://jabalia.ps/social-media/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.access_time_filled_rounded,
                        size: 55,
                        color: AppColors.primary,
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'جاري تحميل البيانات...',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(AttendanceProvider provider) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryLight,
                AppColors.primaryDark,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 55, 20, 20),
              child: Row(
                children: [
                  // Logo
                  Hero(
                    tag: 'app_logo',
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Image.network(
                            'https://jabalia.ps/social-media/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.access_time_filled_rounded,
                                color: AppColors.primary,
                                size: 32,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'الحضور والانصراف',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'بلدية جباليا النزلة',
                          style: GoogleFonts.cairo(
                            color: AppColors.secondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Connection Status
                  _buildConnectionBadge(provider),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        // Sync indicator
        Consumer<SyncProvider>(
          builder: (context, sync, _) {
            if (sync.hasPendingRecords) {
              return Container(
                margin: const EdgeInsets.only(left: 8),
                child: Badge(
                  label: Text(
                    '${sync.pendingCount}',
                    style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: AppColors.warning,
                  child: IconButton(
                    icon: sync.isSyncing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.cloud_upload_rounded, size: 26),
                    onPressed: () => sync.syncPendingRecords(),
                    tooltip: 'مزامنة ${sync.pendingCount} سجل',
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        // Logout
        IconButton(
          icon: const Icon(Icons.logout_rounded, size: 26),
          onPressed: _showLogoutDialog,
          tooltip: 'تسجيل الخروج',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildConnectionBadge(AttendanceProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: provider.isOnline 
            ? AppColors.success.withOpacity(0.2) 
            : AppColors.warning.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: provider.isOnline 
              ? AppColors.success.withOpacity(0.5) 
              : AppColors.warning.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: provider.isOnline 
                  ? AppColors.success 
                  : AppColors.warning,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (provider.isOnline 
                      ? AppColors.success 
                      : AppColors.warning).withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            provider.isOnline ? 'متصل' : 'غير متصل',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(AttendanceProvider provider) {
    final session = provider.currentSession?['session'];
    final hasSession = session != null;
    final isActive = session?['status'] == 'active';

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: hasSession
                  ? (isActive
                      ? [AppColors.success, AppColors.successLight]
                      : [AppColors.gray500, AppColors.gray600])
                  : [AppColors.primary, AppColors.primaryLight],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    // Icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        hasSession
                            ? (isActive ? Icons.play_circle_fill_rounded : Icons.stop_circle_rounded)
                            : Icons.add_circle_outline_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 18),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasSession
                                ? (isActive ? 'جلسة نشطة' : 'جلسة مغلقة')
                                : 'لا توجد جلسة',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (hasSession) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 16,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'بدأت: ${session['start_time']?.toString().substring(0, 5) ?? '--:--'}',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Counter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${provider.presentCount}',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'حاضر',
                            style: GoogleFonts.cairo(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Action Buttons
                if (provider.isOnline) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (!hasSession || !isActive)
                        Expanded(
                          child: _buildSessionButton(
                            icon: Icons.play_arrow_rounded,
                            label: 'بدء جلسة جديدة',
                            onPressed: () => _showCreateSessionDialog(),
                          ),
                        ),
                      if (hasSession && isActive) ...[
                        Expanded(
                          child: _buildSessionButton(
                            icon: Icons.stop_rounded,
                            label: 'إغلاق الجلسة',
                            onPressed: () => _showCloseSessionDialog(),
                            isDestructive: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: isDestructive ? AppColors.danger : AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(AttendanceProvider provider) {
    final total = provider.employees.length;
    final present = provider.employees.where((e) => e.isPresent).length;
    final waiting = total - present;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatCard(
            icon: Icons.groups_rounded,
            label: 'الكل',
            value: total,
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.check_circle_rounded,
            label: 'حاضر',
            value: present,
            color: AppColors.success,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.hourglass_empty_rounded,
            label: 'منتظر',
            value: waiting,
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              '$value',
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: AppColors.gray600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: GoogleFonts.cairo(
            fontSize: 15,
            color: AppColors.gray900,
          ),
          decoration: InputDecoration(
            hintText: 'ابحث بالاسم أو الرقم الوظيفي أو رقم الهوية...',
            hintStyle: GoogleFonts.cairo(
              color: AppColors.gray500,
              fontSize: 14,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear_rounded,
                      color: AppColors.gray500,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      context.read<AttendanceProvider>().searchEmployees('');
                      setState(() {});
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeList(AttendanceProvider provider) {
    if (provider.employees.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: const BoxDecoration(
                  color: AppColors.gray100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 56,
                  color: AppColors.gray500,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'لا يوجد موظفين',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'جرب البحث بكلمات مختلفة',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final employee = provider.employees[index];
            return _buildEmployeeCard(employee, provider);
          },
          childCount: provider.employees.length,
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(Employee employee, AttendanceProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: employee.isPresent 
            ? Border.all(color: AppColors.success, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: employee.isPresent 
                ? AppColors.success.withOpacity(0.15)
                : Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: employee.isPresent
                      ? [AppColors.success, AppColors.successLight]
                      : [AppColors.gray500, AppColors.gray600],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (employee.isPresent
                        ? AppColors.success
                        : AppColors.gray500).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  employee.name.isNotEmpty ? employee.name[0] : '?',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          employee.name,
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (employee.isPresent) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: employee.isEarly
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                employee.isEarly ? Icons.wb_sunny_rounded : Icons.check_rounded,
                                size: 15,
                                color: employee.isEarly
                                    ? AppColors.warningDark
                                    : AppColors.success,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                employee.isEarly ? 'مبكر' : 'حاضر',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: employee.isEarly
                                      ? AppColors.warningDark
                                      : AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (employee.employeeNumber != null) ...[
                        const Icon(Icons.badge_rounded, size: 15, color: AppColors.gray500),
                        const SizedBox(width: 5),
                        Text(
                          employee.employeeNumber!,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: AppColors.gray600,
                          ),
                        ),
                        const SizedBox(width: 14),
                      ],
                      if (employee.checkInTime != null) ...[
                        const Icon(Icons.access_time_rounded, size: 15, color: AppColors.gray500),
                        const SizedBox(width: 5),
                        Text(
                          employee.checkInTime!,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: AppColors.gray600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            const SizedBox(width: 10),
            if (!employee.isPresent) ...[
              _buildActionButton(
                icon: Icons.wb_sunny_rounded,
                color: AppColors.warning,
                tooltip: 'حضور مبكر',
                onPressed: () => _markAttendance(employee, true),
              ),
              const SizedBox(width: 10),
              _buildActionButton(
                icon: Icons.check_rounded,
                color: AppColors.success,
                tooltip: 'تسجيل حضور',
                onPressed: () => _markAttendance(employee, false),
              ),
            ] else ...[
              _buildActionButton(
                icon: Icons.close_rounded,
                color: AppColors.danger,
                tooltip: 'إلغاء',
                onPressed: () => _cancelAttendance(employee),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        borderRadius: BorderRadius.circular(12),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 22),
          ),
        ),
      ),
    );
  }

  Future<void> _markAttendance(Employee employee, bool isEarly) async {
    final provider = context.read<AttendanceProvider>();
    
    if (!provider.hasActiveSession && provider.isOnline) {
      _showSnackBar('لا توجد جلسة نشطة', isError: true);
      return;
    }
    
    final result = await provider.markAttendance(employee, isEarly: isEarly);

    if (mounted) {
      if (result['success'] == true) {
        HapticFeedback.mediumImpact();
        _showSnackBar(
          result['offline'] == true
              ? 'تم الحفظ محلياً - ${employee.name}'
              : 'تم تسجيل حضور ${employee.name}',
          icon: Icons.check_circle_rounded,
        );
      } else {
        _showSnackBar(result['message'] ?? 'فشل في التسجيل', isError: true);
      }
    }

    context.read<SyncProvider>().refreshPendingCount();
  }

  Future<void> _cancelAttendance(Employee employee) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.cancel_rounded, color: AppColors.danger),
            ),
            const SizedBox(width: 12),
            Text(
              'إلغاء الحضور',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'هل تريد إلغاء حضور ${employee.name}؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('لا', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('نعم، إلغاء', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final provider = context.read<AttendanceProvider>();
    final result = await provider.cancelAttendance(employee);

    if (mounted) {
      if (result['success'] == true) {
        _showSnackBar('تم إلغاء حضور ${employee.name}', icon: Icons.info_rounded);
      } else {
        _showSnackBar(result['message'] ?? 'فشل في الإلغاء', isError: true);
      }
    }
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.play_circle_rounded, color: AppColors.success),
              ),
              const SizedBox(width: 12),
              Text(
                'بدء جلسة جديدة',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: timeController,
                style: GoogleFonts.cairo(),
                decoration: InputDecoration(
                  labelText: 'وقت البدء',
                  labelStyle: GoogleFonts.cairo(),
                  prefixIcon: const Icon(Icons.access_time_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                readOnly: true,
                onTap: () async {
                  final time = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    timeController.text =
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                  }
                },
              ),
              const SizedBox(height: 20),
              Text(
                'نوع الجلسة:',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              RadioListTile<String>(
                title: Text('حضور فقط', style: GoogleFonts.cairo()),
                value: 'attendance_only',
                groupValue: sessionType,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => sessionType = v!),
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<String>(
                title: Text('حضور وانصراف', style: GoogleFonts.cairo()),
                value: 'attendance_departure',
                groupValue: sessionType,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => sessionType = v!),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final provider = context.read<AttendanceProvider>();
                final result = await provider.createSession(timeController.text, sessionType);
                if (mounted) {
                  _showSnackBar(
                    result['success'] == true 
                        ? 'تم إنشاء الجلسة بنجاح' 
                        : (result['message'] ?? 'فشل'),
                    isError: result['success'] != true,
                    icon: result['success'] == true ? Icons.check_circle_rounded : null,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('إنشاء', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.stop_circle_rounded, color: AppColors.danger),
            ),
            const SizedBox(width: 12),
            Text(
              'إغلاق الجلسة',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل تريد إغلاق الجلسة؟',
              style: GoogleFonts.cairo(fontSize: 15),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.warningDark),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'سيتم تسجيل الغياب لمن لم يحضر',
                      style: GoogleFonts.cairo(
                        color: AppColors.warningDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<AttendanceProvider>();
              final result = await provider.closeSession();
              if (mounted) {
                _showSnackBar(
                  result['success'] == true 
                      ? 'تم إغلاق الجلسة' 
                      : (result['message'] ?? 'فشل'),
                  isError: result['success'] != true,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('إغلاق', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout_rounded, color: AppColors.warning),
            ),
            const SizedBox(width: 12),
            Text(
              'تسجيل الخروج',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Consumer<SyncProvider>(
          builder: (context, sync, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'هل تريد تسجيل الخروج؟',
                  style: GoogleFonts.cairo(fontSize: 15),
                ),
                if (sync.hasPendingRecords) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.warningDark),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'لديك ${sync.pendingCount} سجل غير متزامن',
                            style: GoogleFonts.cairo(
                              color: AppColors.warningDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('خروج', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false, IconData? icon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null || isError) ...[
              Icon(
                icon ?? Icons.error_outline_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.cairo(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
