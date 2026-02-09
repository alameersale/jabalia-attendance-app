import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';

class SessionCard extends StatelessWidget {
  const SessionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AttendanceProvider>(
      builder: (context, provider, _) {
        final session = provider.currentSession?['session'];
        final hasSession = session != null;
        final isActive = session?['status'] == 'active';

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: hasSession
                  ? (isActive
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : [Colors.grey.shade400, Colors.grey.shade600])
                  : [Colors.blue.shade400, Colors.blue.shade600],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    hasSession
                        ? (isActive ? Icons.play_circle : Icons.stop_circle)
                        : Icons.add_circle,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasSession
                              ? (isActive ? 'جلسة نشطة' : 'جلسة مغلقة')
                              : 'لا توجد جلسة',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (hasSession) ...[
                          const SizedBox(height: 4),
                          Text(
                            'بدأت: ${session['start_time']?.toString().substring(0, 5) ?? '--:--'}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // عداد الحضور
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.people, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${provider.presentCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // أزرار التحكم
              if (provider.isOnline) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (!hasSession || !isActive)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showCreateSessionDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('بدء جلسة جديدة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.green.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    if (hasSession && isActive) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showCloseSessionDialog(context),
                          icon: const Icon(Icons.stop),
                          label: const Text('إغلاق الجلسة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showCreateSessionDialog(BuildContext context) {
    String sessionType = 'attendance_only';
    final timeController = TextEditingController(
      text: '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('بدء جلسة جديدة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  labelText: 'وقت البدء',
                  prefixIcon: Icon(Icons.access_time),
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    timeController.text =
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text('نوع الجلسة:', style: TextStyle(fontWeight: FontWeight.bold)),
              RadioListTile<String>(
                title: const Text('حضور فقط'),
                value: 'attendance_only',
                groupValue: sessionType,
                onChanged: (v) => setState(() => sessionType = v!),
              ),
              RadioListTile<String>(
                title: const Text('حضور وانصراف'),
                value: 'attendance_departure',
                groupValue: sessionType,
                onChanged: (v) => setState(() => sessionType = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final provider = context.read<AttendanceProvider>();
                final success = await provider.createSession(
                  timeController.text,
                  sessionType,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? 'تم إنشاء الجلسة' : provider.error ?? 'فشل',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('إنشاء'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCloseSessionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إغلاق الجلسة'),
        content: const Text(
          'هل تريد إغلاق الجلسة؟\nسيتم تسجيل الغياب لمن لم يحضر.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<AttendanceProvider>();
              final success = await provider.closeSession();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'تم إغلاق الجلسة' : provider.error ?? 'فشل',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
