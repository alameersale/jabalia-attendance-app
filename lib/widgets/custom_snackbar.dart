import 'package:flutter/material.dart';

enum SnackBarType { success, error, warning, info }

class CustomSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    required SnackBarType type,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final config = _getConfig(type);
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                config.icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: config.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: duration,
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction ?? () {},
              )
            : null,
      ),
    );
  }

  static _SnackBarConfig _getConfig(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return _SnackBarConfig(
          color: const Color(0xFF10B981), // Green
          icon: Icons.check_circle_rounded,
        );
      case SnackBarType.error:
        return _SnackBarConfig(
          color: const Color(0xFFEF4444), // Red
          icon: Icons.error_rounded,
        );
      case SnackBarType.warning:
        return _SnackBarConfig(
          color: const Color(0xFFF59E0B), // Amber
          icon: Icons.warning_rounded,
        );
      case SnackBarType.info:
        return _SnackBarConfig(
          color: const Color(0xFF3B82F6), // Blue
          icon: Icons.info_rounded,
        );
    }
  }

  // ==================== Quick Methods ====================

  static void success(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.success);
  }

  static void error(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.error);
  }

  static void warning(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.warning);
  }

  static void info(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.info);
  }

  // ==================== Specific Messages ====================

  static void attendanceSuccess(BuildContext context, String name) {
    show(
      context,
      message: 'تم تسجيل حضور $name ✓',
      type: SnackBarType.success,
    );
  }

  static void earlyAttendanceSuccess(BuildContext context, String name) {
    show(
      context,
      message: '🌅 تم تسجيل حضور مبكر لـ $name (08:00)',
      type: SnackBarType.success,
    );
  }

  static void offlineSaved(BuildContext context, String name) {
    show(
      context,
      message: '📱 تم حفظ حضور $name - سيتم المزامنة لاحقاً',
      type: SnackBarType.warning,
      duration: const Duration(seconds: 4),
    );
  }

  static void syncSuccess(BuildContext context, int count) {
    show(
      context,
      message: '🔄 تم مزامنة $count سجل بنجاح',
      type: SnackBarType.success,
    );
  }

  static void syncFailed(BuildContext context, String error) {
    show(
      context,
      message: '❌ فشل المزامنة: $error',
      type: SnackBarType.error,
    );
  }

  static void connectionRestored(BuildContext context) {
    show(
      context,
      message: '🌐 تم استعادة الاتصال بالإنترنت',
      type: SnackBarType.success,
    );
  }

  static void connectionLost(BuildContext context) {
    show(
      context,
      message: '📴 انقطع الاتصال - وضع عدم الاتصال',
      type: SnackBarType.warning,
    );
  }

  static void sessionStarted(BuildContext context) {
    show(
      context,
      message: '🟢 تم بدء جلسة حضور جديدة',
      type: SnackBarType.success,
    );
  }

  static void sessionClosed(BuildContext context, int present, int absent) {
    show(
      context,
      message: '🔴 انتهت الجلسة | حاضر: $present | غائب: $absent',
      type: SnackBarType.info,
      duration: const Duration(seconds: 5),
    );
  }

  static void attendanceCancelled(BuildContext context, String name) {
    show(
      context,
      message: '🗑️ تم إلغاء حضور $name',
      type: SnackBarType.info,
    );
  }

  static void alreadyRegistered(BuildContext context, String name) {
    show(
      context,
      message: '⚠️ $name مسجل مسبقاً',
      type: SnackBarType.warning,
    );
  }

  static void noActiveSession(BuildContext context) {
    show(
      context,
      message: '⚠️ لا توجد جلسة نشطة - ابدأ جلسة أولاً',
      type: SnackBarType.warning,
    );
  }
}

class _SnackBarConfig {
  final Color color;
  final IconData icon;

  _SnackBarConfig({required this.color, required this.icon});
}
