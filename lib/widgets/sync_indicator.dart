import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sync_provider.dart';

class SyncIndicator extends StatelessWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, sync, _) {
        if (sync.isSyncing) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          );
        }

        if (sync.hasPendingRecords) {
          return GestureDetector(
            onTap: () => _showSyncDialog(context, sync),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade600,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_upload, size: 18, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    '${sync.pendingCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // لا يوجد سجلات معلقة
        return IconButton(
          onPressed: () => _showSyncStatus(context, sync),
          icon: const Icon(Icons.cloud_done),
          tooltip: 'متزامن',
        );
      },
    );
  }

  void _showSyncDialog(BuildContext context, SyncProvider sync) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cloud_upload, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text('سجلات غير متزامنة'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'يوجد ${sync.pendingCount} سجل بانتظار المزامنة',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'سيتم المزامنة تلقائياً عند توفر الاتصال',
              style: TextStyle(color: Colors.grey),
            ),
            if (sync.syncError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sync.syncError!,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              sync.syncPendingRecords().then((success) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? 'تمت المزامنة بنجاح' : 'فشل في المزامنة',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              });
            },
            icon: const Icon(Icons.sync),
            label: const Text('مزامنة الآن'),
          ),
        ],
      ),
    );
  }

  void _showSyncStatus(BuildContext context, SyncProvider sync) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cloud_done, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              sync.lastSyncTime != null
                  ? 'آخر مزامنة: ${sync.lastSyncTime}'
                  : 'جميع السجلات متزامنة',
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
