import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import '../models/notification_item.dart';

class NotificationProvider extends ChangeNotifier {
  final _service = NotificationService.instance;

  int _unreadCount = 0;
  bool _enabled = true;
  List<NotificationItem> _notifications = [];

  int get unreadCount => _unreadCount;
  bool get enabled => _enabled;
  bool get hasUnread => _unreadCount > 0;
  List<NotificationItem> get notifications => _notifications;

  Future<void> load() async {
    _enabled = await _service.isEnabled();
    _notifications = await _service.getNotifications();
    _unreadCount = _notifications.where((n) => !n.isRead).length;
    notifyListeners();
  }

  Future<void> markAllRead() async {
    _unreadCount = 0;
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    await _service.saveNotifications(_notifications);
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      await _service.saveNotifications(_notifications);
      notifyListeners();
    }
  }

  Future<void> setEnabled(bool value) async {
    await _service.setEnabled(value);
    _enabled = value;
    notifyListeners();
  }

  void addNotification(String title, String message, {String type = 'system'}) {
    final newItem = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type,
      isRead: false,
    );
    _notifications.insert(0, newItem);
    _unreadCount++;
    _service.saveNotifications(_notifications);
    notifyListeners();
  }
}
