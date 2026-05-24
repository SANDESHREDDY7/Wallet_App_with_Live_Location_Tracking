import 'package:flutter/foundation.dart';
import '../models/audit_log.dart';

class AuditLogProvider extends ChangeNotifier {
  List<AuditLog> get logs => [];

  Future<void> load() async {
    // Noop - Audit Logging has been completely removed.
  }

  Future<void> logAction(String action, String description) async {
    // Noop - Audit Logging has been completely removed.
  }

  Future<void> clearLogs() async {
    // Noop - Audit Logging has been completely removed.
  }
}
