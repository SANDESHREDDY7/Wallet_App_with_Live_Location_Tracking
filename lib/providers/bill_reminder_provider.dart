import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bill_reminder.dart';
import 'notification_provider.dart';
import '../services/local_notification_service.dart';

class BillReminderProvider extends ChangeNotifier {
  List<BillReminder> _reminders = [];
  bool _isLoading = false;

  List<BillReminder> get reminders => _reminders;
  bool get isLoading => _isLoading;

  /// Generate a safe notification ID from a reminder ID string.
  int _notifId(String id) => id.hashCode.abs() % 100000;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersJson = prefs.getStringList('bill_reminders') ?? [];
      _reminders = remindersJson.map((r) => BillReminder.fromJson(r)).toList();
      _reminders.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    } catch (e) {
      debugPrint('Error loading reminders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = _reminders.map((r) => r.toJson()).toList();
    await prefs.setStringList('bill_reminders', remindersJson);
    notifyListeners();
  }

  Future<void> addReminder(BillReminder reminder) async {
    _reminders.add(reminder);
    _reminders.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    await _save();
    
    // Schedule real system push notification
    final notifService = LocalNotificationService.instance;
    await notifService.scheduleNotification(
      id: _notifId(reminder.id),
      title: '💸 Bill Payment Reminder',
      body: 'Your bill for ${reminder.billerName} of ₹${reminder.amount.toStringAsFixed(2)} is due now!',
      scheduledDate: reminder.dueDate,
    );
  }

  Future<void> updateReminder(BillReminder reminder) async {
    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      _reminders[index] = reminder;
      _reminders.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      await _save();
    }
  }

  Future<void> deleteReminder(String id) async {
    _reminders.removeWhere((r) => r.id == id);
    await _save();
    
    // Cancel scheduled notification
    await LocalNotificationService.instance.cancelNotification(_notifId(id));
  }

  /// Check all reminders and fire real push notifications for due/overdue items.
  void checkDueReminders(NotificationProvider notificationProvider) {
    if (!notificationProvider.enabled) return;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notifService = LocalNotificationService.instance;
    
    for (var reminder in _reminders) {
      if (reminder.isPaid) continue;
      
      final reminderDate = DateTime(reminder.dueDate.year, reminder.dueDate.month, reminder.dueDate.day);
      final difference = reminderDate.difference(today).inDays;
      
      // Skip if already notified in-app this session
      final hasNotification = notificationProvider.notifications.any(
        (n) => n.title == 'Bill Reminder' && n.message.contains(reminder.billerName)
      );
      if (hasNotification) continue;

      if (difference <= 1) {
        String dueText;
        String notifTitle;
        if (difference < 0) {
          dueText = 'is overdue!';
          notifTitle = '🚨 Bill Overdue';
        } else if (difference == 0) {
          dueText = 'is due today!';
          notifTitle = '⚠️ Bill Due Today';
        } else {
          dueText = 'is due tomorrow!';
          notifTitle = '💸 Bill Reminder';
        }

        final body = 'Your bill for ${reminder.billerName} of ₹${reminder.amount.toStringAsFixed(2)} $dueText';

        // Fire REAL system push notification
        notifService.showNow(
          id: _notifId(reminder.id),
          title: notifTitle,
          body: body,
        );

        // Also add to in-app feed
        notificationProvider.addNotification(
          'Bill Reminder',
          body,
          type: 'system',
        );
      }
    }
  }
}

