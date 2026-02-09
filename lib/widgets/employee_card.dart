import 'package:flutter/material.dart';
import '../models/employee.dart';

class EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback onMarkPresent;
  final VoidCallback onMarkEarly;
  final VoidCallback onCancel;

  const EmployeeCard({
    super.key,
    required this.employee,
    required this.onMarkPresent,
    required this.onMarkEarly,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: employee.isPresent
              ? (employee.isEarly ? Colors.amber.shade300 : Colors.green.shade300)
              : Colors.grey.shade200,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 25,
              backgroundColor: employee.isPresent
                  ? (employee.isEarly ? Colors.amber.shade100 : Colors.green.shade100)
                  : Colors.grey.shade200,
              child: Text(
                employee.name.isNotEmpty ? employee.name[0] : '؟',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: employee.isPresent
                      ? (employee.isEarly ? Colors.amber.shade700 : Colors.green.shade700)
                      : Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (employee.departmentName != null) ...[
                        Icon(Icons.business, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          employee.departmentName!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      if (employee.employeeNumber != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.badge, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          employee.employeeNumber!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          textDirection: TextDirection.ltr,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            if (employee.isPresent) ...[
              // وقت الحضور
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: employee.isEarly ? Colors.amber.shade100 : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          employee.isEarly ? Icons.wb_sunny : Icons.check_circle,
                          size: 16,
                          color: employee.isEarly ? Colors.amber.shade700 : Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          employee.checkInTime ?? '--:--',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: employee.isEarly ? Colors.amber.shade700 : Colors.green.shade700,
                          ),
                          textDirection: TextDirection.ltr,
                        ),
                      ],
                    ),
                  ),
                  if (employee.isEarly)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'مبكر',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.amber.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              // زر الإلغاء
              IconButton(
                onPressed: onCancel,
                icon: const Icon(Icons.close),
                color: Colors.red,
                tooltip: 'إلغاء',
              ),
            ] else ...[
              // أزرار التسجيل
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // زر الحضور العادي
                  ElevatedButton(
                    onPressed: onMarkPresent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 18),
                        SizedBox(width: 4),
                        Text('حضور'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // زر الحضور المبكر
                  ElevatedButton(
                    onPressed: onMarkEarly,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wb_sunny, size: 18),
                        SizedBox(width: 4),
                        Text('مبكر'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
