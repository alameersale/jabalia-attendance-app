import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

// Conditional imports
import 'notification_service_mobile.dart' if (dart.library.html) 'notification_service_web.dart' as platform;

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  NotificationService._init();

  final platform.NotificationPlatform _platform = platform.NotificationPlatform();

  Future<void> initialize() async {
    await _platform.initialize();
  }

  Future<void> vibrateSuccess() async => await _platform.vibrateSuccess();
  Future<void> vibrateWarning() async => await _platform.vibrateWarning();
  Future<void> vibrateError() async => await _platform.vibrateError();
  Future<void> vibrateTap() async => await _platform.vibrateTap();
  Future<void> vibrateMedium() async => await _platform.vibrateMedium();
  Future<void> vibrateHeavy() async => await _platform.vibrateHeavy();
  
  Future<void> playSuccessSound() async => await _platform.playSuccessSound();
  Future<void> playAlertSound() async => await _platform.playAlertSound();

  Future<void> showAttendanceSuccess(String employeeName) async =>
      await _platform.showAttendanceSuccess(employeeName);
  Future<void> showEarlyAttendanceSuccess(String employeeName) async =>
      await _platform.showEarlyAttendanceSuccess(employeeName);
  Future<void> showOfflineSaved(String employeeName) async =>
      await _platform.showOfflineSaved(employeeName);
  Future<void> showSyncSuccess(int count) async =>
      await _platform.showSyncSuccess(count);
  Future<void> showSyncFailed(String error) async =>
      await _platform.showSyncFailed(error);
  Future<void> showConnectionRestored() async =>
      await _platform.showConnectionRestored();
  Future<void> showConnectionLost() async =>
      await _platform.showConnectionLost();
  Future<void> showSessionStarted() async =>
      await _platform.showSessionStarted();
  Future<void> showSessionClosed(int presentCount, int absentCount) async =>
      await _platform.showSessionClosed(presentCount, absentCount);
  Future<void> showAttendanceCancelled(String employeeName) async =>
      await _platform.showAttendanceCancelled(employeeName);
  Future<void> cancelAll() async => await _platform.cancelAll();
}
