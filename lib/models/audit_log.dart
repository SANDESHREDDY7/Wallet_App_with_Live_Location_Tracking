class AuditLog {
  final String id;
  final String action;
  final String description;
  final DateTime timestamp;

  AuditLog({
    required this.id,
    required this.action,
    required this.description,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id'],
      action: map['action'],
      description: map['description'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
