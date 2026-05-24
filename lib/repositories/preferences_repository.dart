import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_item.dart';
import '../models/bill_reminder.dart';
import '../models/ticket_item.dart';

/// Stores lightweight key/value data: balance, user profile, settings.
class PreferencesRepository {
  PreferencesRepository._();
  static final PreferencesRepository instance = PreferencesRepository._();

  static const _keyBalance = 'wallet_balance';
  static const _keyUserName = 'user_name';
  static const _keyUserEmail = 'user_email';
  static const _keyUserAvatar = 'user_avatar';
  
  // Multiple registration data (persists after logout)
  static const _keyRegisteredUsers = 'registered_users';
  
  static const _keyNotificationsEnabled = 'notifications_enabled';
  static const _keyUnreadCount = 'unread_count';
  static const _keyLastTab = 'last_nav_tab';
  static const _keyBiometricsEnabled = 'biometrics_enabled';
  static const _keyHasPromptedBiometrics = 'has_prompted_biometrics';

  // ---------------------------------------------------------------------------
  // Balance (User specific)
  // ---------------------------------------------------------------------------

  Future<double> getBalance(String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('${_keyBalance}_$userEmail') ?? 0.0;
  }

  Future<void> setBalance(String userEmail, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('${_keyBalance}_$userEmail', value);
  }

  // ---------------------------------------------------------------------------
  // User profile cache
  // ---------------------------------------------------------------------------

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name);
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  Future<void> setUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserEmail, email);
  }

  Future<String?> getAvatarUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserAvatar);
  }

  Future<void> setAvatarUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserAvatar, url);
  }

  // Multiple Registration persistence
  Future<List<Map<String, String>>> getRegisteredUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyRegisteredUsers);
    if (jsonString == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((u) => Map<String, String>.from(u)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, String>?> findUserForRecovery(String name, String phone) async {
    final users = await getRegisteredUsers();
    for (final u in users) {
      if (u['name']?.trim().toLowerCase() == name.trim().toLowerCase() &&
          u['email']?.trim() == phone.trim()) {
        return u;
      }
    }
    return null;
  }

  Future<void> addRegisteredUser(Map<String, String> user) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await getRegisteredUsers();
    
    // Update existing user if email matches, or add new one
    final index = users.indexWhere((u) => u['email'] == user['email']);
    if (index != -1) {
      users[index] = user;
    } else {
      users.add(user);
    }
    
    await prefs.setString(_keyRegisteredUsers, jsonEncode(users));
  }

  // ---------------------------------------------------------------------------
  // Cards (User specific)
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getCards(String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('cards_$userEmail');
    if (jsonString == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveCards(String userEmail, List<Map<String, dynamic>> cards) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cards_$userEmail', jsonEncode(cards));
  }

  // ---------------------------------------------------------------------------
  // App settings
  // ---------------------------------------------------------------------------

  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, value);
  }

  Future<List<Map<String, dynamic>>> getNotifications(String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('notifications_$userEmail');
    if (jsonString == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveNotifications(String userEmail, List<Map<String, dynamic>> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notifications_$userEmail', jsonEncode(notifications));
  }

  Future<int> getLastTab() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyLastTab) ?? 0;
  }

  Future<void> setLastTab(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastTab, index);
  }

  Future<bool> getBiometricsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometricsEnabled) ?? false;
  }

  Future<void> setBiometricsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricsEnabled, value);
  }

  Future<bool> getHasPromptedBiometrics() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasPromptedBiometrics) ?? false;
  }

  Future<void> setHasPromptedBiometrics(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasPromptedBiometrics, value);
  }

  // --- Notes Persistence ---
  Future<List<NoteItem>> getNotes(String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('notes_$userEmail') ?? [];
    return jsonList.map((s) => NoteItem.fromJson(s)).toList();
  }

  Future<void> saveNotes(String userEmail, List<NoteItem> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = notes.map((n) => n.toJson()).toList();
    await prefs.setStringList('notes_$userEmail', jsonList);
  }

  // --- Tickets Persistence ---
  Future<List<TicketItem>> getTickets(String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('tickets_$userEmail') ?? [];
    return jsonList.map((s) => TicketItem.fromJson(s)).toList();
  }

  Future<void> saveTickets(String userEmail, List<TicketItem> tickets) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = tickets.map((t) => t.toJson()).toList();
    await prefs.setStringList('tickets_$userEmail', jsonList);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserAvatar);
    await prefs.remove(_keyLastTab);
    // Note: We DO NOT remove registration data or balance
  }

  // --- Account Recovery Settings ---
  Future<int> getRecoveryAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('rec_attempts') ?? 0;
  }
  Future<void> setRecoveryAttempts(int val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('rec_attempts', val);
  }

  Future<int?> getRecoveryBlockedUntil() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('rec_blocked_until');
  }
  Future<void> setRecoveryBlockedUntil(int? val) async {
    final prefs = await SharedPreferences.getInstance();
    if (val == null) {
      await prefs.remove('rec_blocked_until');
    } else {
      await prefs.setInt('rec_blocked_until', val);
    }
  }

  Future<bool> getRecoveryHasBeenBlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('rec_has_blocked') ?? false;
  }
  Future<void> setRecoveryHasBeenBlocked(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rec_has_blocked', val);
  }

  Future<int?> getRecoveryInitiatedAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('rec_initiated_at');
  }
  Future<void> setRecoveryInitiatedAt(int? val) async {
    final prefs = await SharedPreferences.getInstance();
    if (val == null) {
      await prefs.remove('rec_initiated_at');
    } else {
      await prefs.setInt('rec_initiated_at', val);
    }
  }

  Future<String?> getRecoveryUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('rec_user_email');
  }
  Future<void> setRecoveryUserEmail(String? val) async {
    final prefs = await SharedPreferences.getInstance();
    if (val == null) {
      await prefs.remove('rec_user_email');
    } else {
      await prefs.setString('rec_user_email', val);
    }
  }

  Future<String?> getRecoveryUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('rec_user_name');
  }
  Future<void> setRecoveryUserName(String? val) async {
    final prefs = await SharedPreferences.getInstance();
    if (val == null) {
      await prefs.remove('rec_user_name');
    } else {
      await prefs.setString('rec_user_name', val);
    }
  }

  Future<void> eraseAllAccountsAndData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
