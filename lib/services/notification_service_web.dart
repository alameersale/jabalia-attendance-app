// Web implementation - notifications and vibration are limited on web
class NotificationPlatform {
  bool _isInitialized = false;

  Future<void> initialize() async {
    _isInitialized = true;
  }

  // Vibration not supported on web
  Future<void> vibrateSuccess() async {}
  Future<void> vibrateWarning() async {}
  Future<void> vibrateError() async {}
  Future<void> vibrateTap() async {}
  Future<void> vibrateMedium() async {}
  Future<void> vibrateHeavy() async {}
  
  Future<void> playSuccessSound() async {}
  Future<void> playAlertSound() async {}

  // Web notifications - just print to console for now
  Future<void> showAttendanceSuccess(String employeeName) async {
    print('✅ تم تسجيل حضور $employeeName');
  }

  Future<void> showEarlyAttendanceSuccess(String employeeName) async {
    print('🌅 حضور مبكر لـ $employeeName');
  }

  Future<void> showOfflineSaved(String employeeName) async {
    print('📱 تم الحفظ محلياً: $employeeName');
  }

  Future<void> showSyncSuccess(int count) async {
    print('🔄 تمت مزامنة $count سجل');
  }

  Future<void> showSyncFailed(String error) async {
    print('❌ فشل المزامنة: $error');
  }

  Future<void> showConnectionRestored() async {
    print('🌐 عاد الاتصال');
  }

  Future<void> showConnectionLost() async {
    print('📴 انقطع الاتصال');
  }

  Future<void> showSessionStarted() async {
    print('🟢 بدأت الجلسة');
  }

  Future<void> showSessionClosed(int presentCount, int absentCount) async {
    print('🔴 انتهت الجلسة - حاضر: $presentCount | غائب: $absentCount');
  }

  Future<void> showAttendanceCancelled(String employeeName) async {
    print('🗑️ تم إلغاء حضور $employeeName');
  }

  Future<void> cancelAll() async {}
}
