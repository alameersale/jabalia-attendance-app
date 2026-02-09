import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

class NotificationPlatform {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@drawable/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    
    await _notifications.initialize(initSettings);
    _isInitialized = true;
  }

  Future<void> vibrateSuccess() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100);
    }
  }

  Future<void> vibrateWarning() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 100, 100, 100]);
    }
  }

  Future<void> vibrateError() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 200, 100, 200, 100, 200]);
    }
  }

  Future<void> vibrateTap() async {
    HapticFeedback.lightImpact();
  }

  Future<void> vibrateMedium() async {
    HapticFeedback.mediumImpact();
  }

  Future<void> vibrateHeavy() async {
    HapticFeedback.heavyImpact();
  }

  Future<void> playSuccessSound() async {
    await SystemSound.play(SystemSoundType.click);
    await vibrateSuccess();
  }

  Future<void> playAlertSound() async {
    await SystemSound.play(SystemSoundType.alert);
    await vibrateWarning();
  }

  Future<void> showAttendanceSuccess(String employeeName) async {
    await _showNotification(
      id: 1,
      title: '✅ تم تسجيل الحضور',
      body: 'تم تسجيل حضور $employeeName بنجاح',
      channelId: 'attendance',
      channelName: 'الحضور والانصراف',
    );
    await vibrateSuccess();
  }

  Future<void> showEarlyAttendanceSuccess(String employeeName) async {
    await _showNotification(
      id: 2,
      title: '🌅 حضور مبكر',
      body: 'تم تسجيل حضور مبكر لـ $employeeName (08:00)',
      channelId: 'attendance',
      channelName: 'الحضور والانصراف',
    );
    await vibrateSuccess();
  }

  Future<void> showOfflineSaved(String employeeName) async {
    await _showNotification(
      id: 3,
      title: '📱 تم الحفظ محلياً',
      body: 'سيتم مزامنة حضور $employeeName عند عودة الاتصال',
      channelId: 'sync',
      channelName: 'المزامنة',
    );
    await vibrateWarning();
  }

  Future<void> showSyncSuccess(int count) async {
    await _showNotification(
      id: 4,
      title: '🔄 تمت المزامنة',
      body: 'تم مزامنة $count سجل بنجاح',
      channelId: 'sync',
      channelName: 'المزامنة',
    );
    await vibrateSuccess();
  }

  Future<void> showSyncFailed(String error) async {
    await _showNotification(
      id: 5,
      title: '❌ فشل المزامنة',
      body: error,
      channelId: 'sync',
      channelName: 'المزامنة',
    );
    await vibrateError();
  }

  Future<void> showConnectionRestored() async {
    await _showNotification(
      id: 6,
      title: '🌐 عاد الاتصال',
      body: 'تم استعادة الاتصال بالإنترنت',
      channelId: 'connection',
      channelName: 'حالة الاتصال',
    );
    await vibrateSuccess();
  }

  Future<void> showConnectionLost() async {
    await _showNotification(
      id: 7,
      title: '📴 انقطع الاتصال',
      body: 'أنت الآن في وضع عدم الاتصال',
      channelId: 'connection',
      channelName: 'حالة الاتصال',
    );
    await vibrateWarning();
  }

  Future<void> showSessionStarted() async {
    await _showNotification(
      id: 8,
      title: '🟢 بدأت الجلسة',
      body: 'تم بدء جلسة حضور جديدة',
      channelId: 'session',
      channelName: 'الجلسات',
    );
    await vibrateSuccess();
  }

  Future<void> showSessionClosed(int presentCount, int absentCount) async {
    await _showNotification(
      id: 9,
      title: '🔴 انتهت الجلسة',
      body: 'حاضر: $presentCount | غائب: $absentCount',
      channelId: 'session',
      channelName: 'الجلسات',
    );
    await vibrateSuccess();
  }

  Future<void> showAttendanceCancelled(String employeeName) async {
    await _showNotification(
      id: 10,
      title: '🗑️ تم إلغاء الحضور',
      body: 'تم إلغاء حضور $employeeName',
      channelId: 'attendance',
      channelName: 'الحضور والانصراف',
    );
    await vibrateTap();
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
  }) async {
    if (!_isInitialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    final details = NotificationDetails(android: androidDetails);
    
    await _notifications.show(id, title, body, details);
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
