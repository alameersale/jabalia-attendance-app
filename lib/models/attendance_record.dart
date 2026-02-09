class AttendanceRecord {
  final int? id;
  final int userId;
  final String userName;
  final bool isEarly;
  final DateTime timestamp;
  bool isSynced;

  AttendanceRecord({
    this.id,
    required this.userId,
    required this.userName,
    required this.isEarly,
    required this.timestamp,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'is_early': isEarly ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'],
      userId: map['user_id'],
      userName: map['user_name'],
      isEarly: map['is_early'] == 1,
      timestamp: DateTime.parse(map['timestamp']),
      isSynced: map['is_synced'] == 1,
    );
  }

  Map<String, dynamic> toSyncJson() {
    return {
      'user_id': userId,
      'is_early': isEarly,
      'timestamp': timestamp.toIso8601String().replaceAll('T', ' ').substring(0, 19),
    };
  }
}
