import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ticket_item.dart';
import '../repositories/preferences_repository.dart';
import '../services/auth_service.dart';
import '../services/local_notification_service.dart';
import '../services/calendar_sync_service.dart';

class TicketProvider with ChangeNotifier {
  final PreferencesRepository _repo = PreferencesRepository.instance;
  final AuthService _auth = AuthService.instance;

  List<TicketItem> _tickets = [];
  bool _isLoading = false;

  List<TicketItem> get tickets => _tickets;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    final user = await _auth.getCurrentUser();
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    _tickets = await _repo.getTickets(user.email);

    // Hard-prune any legacy mock tickets from local storage for a completely empty state
    final originalCount = _tickets.length;
    _tickets.removeWhere((t) => 
        t.id.startsWith('cal_event_') || 
        t.id.startsWith('smart_sync_cal_') || 
        t.pnr == 'IND6E203' || 
        t.pnr == '2304918230' || 
        t.pnr == 'ZING9922' ||
        t.pnr == 'IND6E99' ||
        t.pnr == '4301948572' ||
        t.pnr == 'ZING77');
    if (_tickets.length != originalCount) {
      await _repo.saveTickets(user.email, _tickets);
    }

    // Perform Automatic Silent Background Calendar Sync during launch/load
    await _performSilentCalendarSync(user.email);

    _tickets.sort((a, b) => b.date.compareTo(a.date));

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _performSilentCalendarSync(String email) async {
    try {
      final realEvents = await CalendarSyncService.instance.fetchRealDeviceCalendarTickets();
      int importedCount = 0;

      for (var ev in realEvents) {
        // Prevent duplicate imports by verifying if PNR already exists
        final exists = _tickets.any((t) => t.pnr == ev.pnr);
        if (!exists) {
          final newTicket = ev.toTicketItem();
          _tickets.insert(0, newTicket);

          // Schedule journey alerts (2h, 1h, 30m) for this newly auto-synced ticket
          _scheduleTicketReminders(newTicket);

          // Log direct to SharedPreferences audit trails to remain fully safe & non-context dependent
          await _logAuditAction(
            email, 
            'CalendarSync', 
            'Automatically synced ticket ${ev.operatorName} from ${ev.sourceCalendar} (PNR: ${ev.pnr})'
          );
          importedCount++;
        }
      }

      if (importedCount > 0) {
        // Save the updated ticket list including the auto-synced bookings
        await _repo.saveTickets(email, _tickets);

        // Show a local notification informing the user that smart sync has imported new bookings!
        LocalNotificationService.instance.showNow(
          id: 9999,
          title: 'Smart Calendar Sync Active 🔄',
          body: 'Automatically imported $importedCount new travel bookings from your Google & Apple Calendars!',
        );
      }
    } catch (e) {
      debugPrint('[CalendarSync] Silent sync failed: $e');
    }
  }

  Future<void> _logAuditAction(String email, String action, String description) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'audit_logs_$email';
      List<Map<String, dynamic>> logs = [];

      final logsJson = prefs.getString(key);
      if (logsJson != null) {
        final List decoded = jsonDecode(logsJson);
        logs = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      logs.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'action': action,
        'description': description,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (logs.length > 100) {
        logs = logs.sublist(0, 100);
      }

      await prefs.setString(key, jsonEncode(logs));
    } catch (e) {
      debugPrint('[CalendarSync] Failed logging audit action: $e');
    }
  }

  Future<void> addTicket(TicketItem ticket) async {
    final user = await _auth.getCurrentUser();
    if (user == null) return;

    _tickets.insert(0, ticket);
    await _repo.saveTickets(user.email, _tickets);
    
    // Schedule 2 hours, 1 hour, and 30 minutes reminders
    _scheduleTicketReminders(ticket);
    
    notifyListeners();
  }

  Future<void> updateTicket(TicketItem updatedTicket) async {
    final user = await _auth.getCurrentUser();
    if (user == null) return;

    final index = _tickets.indexWhere((t) => t.id == updatedTicket.id);
    if (index != -1) {
      _tickets[index] = updatedTicket;
      await _repo.saveTickets(user.email, _tickets);

      // Cancel existing reminders first, then reschedule
      _cancelTicketReminders(updatedTicket.id);
      _scheduleTicketReminders(updatedTicket);

      notifyListeners();
    }
  }

  Future<void> deleteTicket(String id) async {
    final user = await _auth.getCurrentUser();
    if (user == null) return;

    _tickets.removeWhere((t) => t.id == id);
    await _repo.saveTickets(user.email, _tickets);

    // Cancel all scheduled alerts for this ticket
    _cancelTicketReminders(id);

    notifyListeners();
  }

  void clear() {
    _tickets = [];
    notifyListeners();
  }

  /// Helper to generate safe unique 32-bit notification IDs
  int _getNotificationId(String ticketId, int reminderType) {
    final hash = ticketId.hashCode & 0x03FFFFFF; // safe 26-bit hash (max 67,108,863)
    return hash * 10 + reminderType; // unique signed 32-bit int (max 671,088,633 < 2,147,483,647)
  }

  /// Schedules 3 notifications for travel journeys
  void _scheduleTicketReminders(TicketItem ticket) {
    final now = DateTime.now();
    final emoji = ticket.type == 'flight' ? '✈️' : (ticket.type == 'train' ? '🚆' : '🚌');
    final formattedTime = DateFormat('hh:mm a').format(ticket.date);
    
    // 1. Journey reminder 2 hours before
    final target2h = ticket.date.subtract(const Duration(hours: 2));
    if (target2h.isAfter(now)) {
      LocalNotificationService.instance.scheduleNotification(
        id: _getNotificationId(ticket.id, 1),
        title: '$emoji Journey in 2 hours!',
        body: 'Your ticket ${ticket.boardingPointName} ➔ ${ticket.destinationPointName} departs at $formattedTime.',
        scheduledDate: target2h,
      );
    }

    // 2. Journey reminder 1 hour before
    final target1h = ticket.date.subtract(const Duration(hours: 1));
    if (target1h.isAfter(now)) {
      LocalNotificationService.instance.scheduleNotification(
        id: _getNotificationId(ticket.id, 2),
        title: '$emoji Journey in 1 hour!',
        body: 'Prepare to board! PNR: ${ticket.pnr} | Seat: ${ticket.seatNumber}.',
        scheduledDate: target1h,
      );
    }

    // 3. Journey reminder 30 minutes before
    final target30m = ticket.date.subtract(const Duration(minutes: 30));
    if (target30m.isAfter(now)) {
      LocalNotificationService.instance.scheduleNotification(
        id: _getNotificationId(ticket.id, 3),
        title: '$emoji Journey in 30 minutes!',
        body: 'Time to verify details. Passenger: Sandesh Reddy. Tap to view ticket.',
        scheduledDate: target30m,
      );
    }
  }

  /// Cancels all scheduled alerts for a ticket
  void _cancelTicketReminders(String ticketId) {
    LocalNotificationService.instance.cancelNotification(_getNotificationId(ticketId, 1));
    LocalNotificationService.instance.cancelNotification(_getNotificationId(ticketId, 2));
    LocalNotificationService.instance.cancelNotification(_getNotificationId(ticketId, 3));
  }
}
