import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class SyncProvider extends ChangeNotifier {
  bool _isSyncing = false;
  int _pendingCount = 0;
  String? _lastSyncTime;
  String? _syncError;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  final NotificationService _notificationService = NotificationService.instance;

  bool get isSyncing => _isSyncing;
  int get pendingCount => _pendingCount;
  String? get lastSyncTime => _lastSyncTime;
  String? get syncError => _syncError;
  bool get hasPendingRecords => _pendingCount > 0;

  SyncProvider() {
    _init();
  }

  Future<void> _init() async {
    await _notificationService.initialize();
    await _updatePendingCount();
    _startConnectivityListener();
  }

  void _startConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) async {
      // Check if any result is not "none"
      final hasConnection = results.any((result) => result != ConnectivityResult.none);
      if (hasConnection && _pendingCount > 0) {
        // اتصال متاح وهناك سجلات معلقة - محاولة المزامنة
        await Future.delayed(const Duration(seconds: 2)); // انتظار استقرار الاتصال
        await syncPendingRecords();
      }
    });
  }

  Future<void> _updatePendingCount() async {
    _pendingCount = await DatabaseService.instance.getUnsyncedCount();
    notifyListeners();
  }

  Future<bool> syncPendingRecords() async {
    if (_isSyncing) return false;

    final records = await DatabaseService.instance.getUnsyncedRecords();
    if (records.isEmpty) {
      _pendingCount = 0;
      notifyListeners();
      return true;
    }

    _isSyncing = true;
    _syncError = null;
    notifyListeners();

    try {
      // فحص الاتصال أولاً
      final isOnline = await ApiService.instance.checkConnection();
      if (!isOnline) {
        _syncError = 'لا يوجد اتصال بالإنترنت';
        _isSyncing = false;
        await _notificationService.vibrateWarning();
        notifyListeners();
        return false;
      }

      // إرسال السجلات
      final result = await ApiService.instance.syncAttendances(records);

      if (result['success'] == true) {
        // تحديث السجلات المحلية
        final syncedIds = records.map((r) => r.id!).toList();
        await DatabaseService.instance.markRecordsAsSynced(syncedIds);
        
        // حذف السجلات المتزامنة
        await DatabaseService.instance.clearSyncedRecords();

        _lastSyncTime = _getCurrentTime();
        final syncedCount = _pendingCount;
        _pendingCount = 0;
        _isSyncing = false;
        
        // إشعار نجاح المزامنة
        await _notificationService.showSyncSuccess(syncedCount);
        
        notifyListeners();
        return true;
      } else {
        _syncError = result['message'] ?? 'فشل في المزامنة';
        _isSyncing = false;
        
        // إشعار فشل المزامنة
        await _notificationService.showSyncFailed(_syncError!);
        
        notifyListeners();
        return false;
      }
    } catch (e) {
      _syncError = 'خطأ: $e';
      _isSyncing = false;
      
      await _notificationService.showSyncFailed(_syncError!);
      
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshPendingCount() async {
    await _updatePendingCount();
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  void clearError() {
    _syncError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
