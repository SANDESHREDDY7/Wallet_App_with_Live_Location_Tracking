import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../repositories/preferences_repository.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/contact_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/note_provider.dart';
import '../providers/audit_log_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AccountRecoveryScreen extends StatefulWidget {
  const AccountRecoveryScreen({super.key});

  @override
  State<AccountRecoveryScreen> createState() => _AccountRecoveryScreenState();
}

class _AccountRecoveryScreenState extends State<AccountRecoveryScreen> {
  DateTime? _recoveryStart;
  String? _userName;
  String? _userEmail;

  Timer? _timer;
  Duration _timeToUnlock = Duration.zero; // Day 2 mark
  Duration _timeToAutoLogin = Duration.zero; // Day 7 mark
  bool _isUnlocked = false;

  @override
  void initState() {
    super.initState();
    _loadRecoveryData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadRecoveryData() async {
    final prefs = PreferencesRepository.instance;
    final startMs = await prefs.getRecoveryInitiatedAt();
    final name = await prefs.getRecoveryUserName();
    final email = await prefs.getRecoveryUserEmail();

    if (startMs != null) {
      setState(() {
        _recoveryStart = DateTime.fromMillisecondsSinceEpoch(startMs);
        _userName = name;
        _userEmail = email;
        _updateDurations();
      });

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _updateDurations();
      });
    }
  }

  void _updateDurations() {
    if (_recoveryStart == null) return;

    final now = DateTime.now();
    final unlockMark = _recoveryStart!.add(const Duration(days: 2));
    final autoLoginMark = _recoveryStart!.add(const Duration(days: 7));

    if (now.isAfter(unlockMark)) {
      _isUnlocked = true;
      _timeToUnlock = Duration.zero;
    } else {
      _isUnlocked = false;
      _timeToUnlock = unlockMark.difference(now);
    }

    if (now.isAfter(autoLoginMark)) {
      _timeToAutoLogin = Duration.zero;
      _timer?.cancel();
      // Auto-trigger automatic login!
      _triggerAutoLogin();
    } else {
      _timeToAutoLogin = autoLoginMark.difference(now);
    }
    setState(() {});
  }

  Future<void> _triggerAutoLogin() async {
    if (_userEmail == null || _userName == null) return;
    
    final prefs = PreferencesRepository.instance;
    final users = await prefs.getRegisteredUsers();
    final regUser = users.firstWhere((u) => u['email'] == _userEmail, orElse: () => {});
    final avatar = regUser['avatar'] ?? '';

    // Simulate login session
    await prefs.setUserName(_userName!);
    await prefs.setUserEmail(_userEmail!);
    await prefs.setAvatarUrl(avatar);

    // WIPE recovery locks
    await prefs.setRecoveryInitiatedAt(null);
    await prefs.setRecoveryUserEmail(null);
    await prefs.setRecoveryUserName(null);
    await prefs.setRecoveryAttempts(0);
    await prefs.setRecoveryBlockedUntil(null);
    await prefs.setRecoveryHasBeenBlocked(false);

    if (mounted) {
      context.read<AuditLogProvider>().logAction('Recovery', 'Auto-login security protocol completed after recovery timeline.');
      
      // Load user in AuthProvider and reload providers
      final auth = context.read<AuthProvider>();
      await auth.load();
      await Future.wait([
        context.read<WalletProvider>().load(),
        context.read<TransactionProvider>().fetchTransactions(),
        context.read<ContactProvider>().fetchContacts(),
        context.read<NotificationProvider>().load(),
        context.read<NoteProvider>().load(),
      ]);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    }
  }



  Future<void> _handleManualLoginRedirect() async {
    // Clear recovery session state so they can log in normally
    final prefs = PreferencesRepository.instance;
    await prefs.setRecoveryInitiatedAt(null);
    await prefs.setRecoveryUserEmail(null);
    await prefs.setRecoveryUserName(null);
    await prefs.setRecoveryAttempts(0);
    await prefs.setRecoveryBlockedUntil(null);
    await prefs.setRecoveryHasBeenBlocked(false);

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleIconColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Center(
          child: Text(
            'Security Recovery Console',
            style: TextStyle(color: titleIconColor, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              // Security Shield animation
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _isUnlocked 
                      ? AppTheme.accentGreen.withValues(alpha: 0.1)
                      : AppTheme.primaryPurple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isUnlocked ? AppTheme.accentGreen : AppTheme.primaryPurple, 
                      width: 1.5
                    ),
                  ),
                  child: Icon(
                    _isUnlocked ? LucideIcons.shieldCheck : LucideIcons.shieldAlert, 
                    size: 64, 
                    color: _isUnlocked ? AppTheme.accentGreen : AppTheme.primaryPurple
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                _isUnlocked ? 'Verification Succeeded' : 'Security Cooling-Off Period',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: titleIconColor),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _isUnlocked 
                    ? 'Your account recovery is validated! You may now sign in using your password, or wait for automatic login.'
                    : 'The forgot password request is approved. To prevent theft, this secure device cooling lock expires in 2 days.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textGrey, fontSize: 14, height: 1.5),
                ),
              ),
              const SizedBox(height: 48),

              // Countdown display
              if (!_isUnlocked) ...[
                // Lock Countdown
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'UNPINNING SECURITY LOCK IN', 
                        style: TextStyle(color: AppTheme.textGrey, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.5)
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildTimeBlock(_timeToUnlock.inDays, 'DAYS'),
                          _buildTimeBlock(_timeToUnlock.inHours % 24, 'HRS'),
                          _buildTimeBlock(_timeToUnlock.inMinutes % 60, 'MINS'),
                          _buildTimeBlock(_timeToUnlock.inSeconds % 60, 'SECS'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Auto login disclaimer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.zap, size: 14, color: AppTheme.textGrey),
                    const SizedBox(width: 6),
                    Text(
                      'Auto-Login: ${_timeToAutoLogin.inDays} days, ${_timeToAutoLogin.inHours % 24} hours remaining',
                      style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
                    ),
                  ],
                ),

              ] else ...[
                // Unlocked View
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    children: [
                      const Icon(LucideIcons.unlock, color: AppTheme.accentGreen, size: 36),
                      const SizedBox(height: 12),
                      const Text(
                        'ACCOUNT UNLOCKED', 
                        style: TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.5)
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _handleManualLoginRedirect,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentGreen,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Log In Normally', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: AppTheme.textGrey),
                      const SizedBox(height: 12),
                      Text(
                        'OR wait for automatic decryption in:\n${_timeToAutoLogin.inDays}d ${(_timeToAutoLogin.inHours % 24)}h ${(_timeToAutoLogin.inMinutes % 60)}m ${(_timeToAutoLogin.inSeconds % 60)}s',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textGrey, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),

              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeBlock(int value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace'),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 9, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
