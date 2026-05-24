import '../repositories/preferences_repository.dart';
import '../models/notification_item.dart';
import 'auth_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _prefs = PreferencesRepository.instance;
  final _auth = AuthService.instance;

  String? get _userEmail => _auth.currentUser?.email;

  Future<bool> isEnabled() => _prefs.getNotificationsEnabled();

  Future<void> setEnabled(bool enabled) =>
      _prefs.setNotificationsEnabled(enabled);

  Future<List<NotificationItem>> getNotifications() async {
    final email = _userEmail;
    if (email == null) return [];
    final data = await _prefs.getNotifications(email);
    return data.map((e) => NotificationItem.fromMap(e)).toList();
  }

  Future<void> saveNotifications(List<NotificationItem> notifications) async {
    final email = _userEmail;
    if (email == null) return;
    await _prefs.saveNotifications(email, notifications.map((e) => e.toMap()).toList());
  }
}
