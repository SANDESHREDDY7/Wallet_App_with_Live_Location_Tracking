import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../repositories/preferences_repository.dart';
import '../repositories/local_db.dart';
import '../theme/app_theme.dart';
import '../providers/audit_log_provider.dart';
import 'account_recovery_screen.dart';
import 'signup_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  int _attempts = 0;
  DateTime? _blockedUntil;
  bool _hasBeenBlocked = false;
  bool _isLoading = false;
  bool _isSelfDestructing = false;

  Timer? _cooldownTimer;
  Duration _remainingCooldown = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadRecoveryStatus();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRecoveryStatus() async {
    final prefs = PreferencesRepository.instance;
    final attempts = await prefs.getRecoveryAttempts();
    final blockedUntilMs = await prefs.getRecoveryBlockedUntil();
    final hasBlocked = await prefs.getRecoveryHasBeenBlocked();

    setState(() {
      _attempts = attempts;
      _hasBeenBlocked = hasBlocked;
      if (blockedUntilMs != null) {
        _blockedUntil = DateTime.fromMillisecondsSinceEpoch(blockedUntilMs);
        _startCooldownTimer();
      }
    });
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    if (_blockedUntil == null) return;

    _updateRemainingTime();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemainingTime();
    });
  }

  void _updateRemainingTime() {
    if (_blockedUntil == null) return;
    final now = DateTime.now();
    if (now.isAfter(_blockedUntil!)) {
      _cooldownTimer?.cancel();
      setState(() {
        _blockedUntil = null;
        _remainingCooldown = Duration.zero;
      });
      PreferencesRepository.instance.setRecoveryBlockedUntil(null);
    } else {
      setState(() {
        _remainingCooldown = _blockedUntil!.difference(now);
      });
    }
  }



  Future<void> _handleRecover() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name and mobile number')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = PreferencesRepository.instance;
      final matchedUser = await prefs.findUserForRecovery(name, phone);

      if (matchedUser != null) {
        // SUCCESS!
        await prefs.setRecoveryAttempts(0);
        await prefs.setRecoveryBlockedUntil(null);
        await prefs.setRecoveryHasBeenBlocked(false);
        await prefs.setRecoveryInitiatedAt(DateTime.now().millisecondsSinceEpoch);
        await prefs.setRecoveryUserEmail(matchedUser['email']);
        await prefs.setRecoveryUserName(matchedUser['name']);

        if (mounted) {
          context.read<AuditLogProvider>().logAction('Recovery', 'Successfully verified recovery parameters for user $name ($phone)');
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AccountRecoveryScreen()),
          );
        }
      } else {
        // FAILED!
        final nextAttempts = _attempts + 1;
        await prefs.setRecoveryAttempts(nextAttempts);
        setState(() => _attempts = nextAttempts);

        if (mounted) {
          context.read<AuditLogProvider>().logAction('Recovery', 'Failed recovery attempt $_attempts/3 for name: "$name" phone: "$phone"');
        }

        // Check if they failed while ALREADY having been blocked once (High Stakes Wipeout!)
        if (_hasBeenBlocked) {
          _triggerSelfDestructSequence();
          return;
        }

        if (nextAttempts >= 3) {
          final blockTime = DateTime.now().add(const Duration(hours: 1));
          await prefs.setRecoveryBlockedUntil(blockTime.millisecondsSinceEpoch);
          await prefs.setRecoveryHasBeenBlocked(true);
          
          setState(() {
            _blockedUntil = blockTime;
            _hasBeenBlocked = true;
          });
          _startCooldownTimer();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🚨 3 Failed attempts! Forgot password blocked for 1 hour.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Incorrect credentials. Attempt $nextAttempts of 3.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recovery validation failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _triggerSelfDestructSequence() async {
    setState(() {
      _isSelfDestructing = true;
      _isLoading = false;
    });

    if (mounted) {
      context.read<AuditLogProvider>().logAction('Recovery', '🚨 CRITICAL: Self-destruct tripped after subsequent wrong credentials.');
    }

    // Play highly dramatic countdown delay before deleting
    await Future.delayed(const Duration(seconds: 4));

    final prefs = PreferencesRepository.instance;
    await prefs.eraseAllAccountsAndData();
    await LocalDb.instance.clearAllData();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignupScreen()),
        (route) => false,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚨 SECURITY PROTOCOL TRIPPED: All local data permanently erased!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleIconColor = isDark ? Colors.white : const Color(0xFF0F172A);

    if (_isSelfDestructing) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E0808),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.redAccent, width: 2),
                  ),
                  child: const Icon(LucideIcons.shieldAlert, size: 64, color: Colors.redAccent),
                ),
                const SizedBox(height: 32),
                const Text(
                  'SECURITY BREACH',
                  style: TextStyle(color: Colors.redAccent, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Subsequent validation failure detected on locked account. Triggering ultimate self-destruct protocol...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(color: Colors.redAccent, strokeWidth: 3),
                ),
                const SizedBox(height: 24),
                const Text(
                  'ERASING LOCAL DEVICE DATA STORAGE Permanently...',
                  style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isBlocked = _blockedUntil != null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: titleIconColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Account Recovery', style: TextStyle(color: titleIconColor, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isBlocked ? LucideIcons.hourglass : LucideIcons.helpCircle, 
                        size: 48, 
                        color: AppTheme.primaryPurple
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      isBlocked ? 'Validation Locked' : 'Recover Account',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: titleIconColor),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        isBlocked 
                          ? 'Too many failed attempts. Cooldown period active. Please wait 1 hour.' 
                          : _hasBeenBlocked
                            ? '⚠️ HIGH STAKES PHASE: Please enter details carefully. One wrong attempt will permanently delete all data.'
                            : 'Enter your registered full name and mobile number to authenticate and unlock your account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _hasBeenBlocked ? Colors.orange : AppTheme.textGrey, 
                          fontSize: 14,
                          fontWeight: _hasBeenBlocked ? FontWeight.bold : FontWeight.normal
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  if (isBlocked) ...[
                    // Cooldown countdown clock
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            const Text('TRY AGAIN IN', style: TextStyle(color: AppTheme.textGrey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                            const SizedBox(height: 12),
                            Text(
                              '${_remainingCooldown.inMinutes.toString().padLeft(2, '0')}:${(_remainingCooldown.inSeconds % 60).toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.orange, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                    ),

                  ] else ...[
                    _buildTextField(
                      controller: _nameController,
                      hint: 'Full Name',
                      icon: LucideIcons.user,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _phoneController,
                      hint: 'Mobile Number',
                      icon: LucideIcons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _handleRecover,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text('Unlock Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    if (_attempts > 0) ...[
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'Failed Attempts: $_attempts/3',
                          style: TextStyle(
                            color: _hasBeenBlocked ? Colors.red : Colors.orange, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ],
                  ]
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryPurple),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.textGrey),
          prefixIcon: Icon(icon, color: AppTheme.textGrey, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
