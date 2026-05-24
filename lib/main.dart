import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/contact_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/cards_provider.dart';
import 'providers/bill_reminder_provider.dart';
import 'providers/audit_log_provider.dart';
import 'providers/note_provider.dart';
import 'providers/ticket_provider.dart';
import 'services/local_notification_service.dart';
import 'screens/login_screen.dart';
import 'repositories/preferences_repository.dart';
import 'services/biometric_service.dart';
import 'screens/account_recovery_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WalletApp());
}

class WalletApp extends StatelessWidget {
  const WalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => ContactProvider()..fetchContacts()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()..load()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CardsProvider()),
        ChangeNotifierProvider(create: (_) => BillReminderProvider()),
        ChangeNotifierProvider(create: (_) => AuditLogProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        ChangeNotifierProvider(create: (_) => TicketProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Wallet App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const _AppInitializer(),
          );
        },
      ),
    );
  }
}

/// Loads all data before rendering the home screen.
class _AppInitializer extends StatefulWidget {
  const _AppInitializer();

  @override
  State<_AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<_AppInitializer> {
  bool _initialized = false;
  bool _isLocked = false;
  bool _hasActiveRecovery = false;
  final _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final prefs = PreferencesRepository.instance;
      final recoveryStart = await prefs.getRecoveryInitiatedAt();
      if (recoveryStart != null) {
        final elapsed = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(recoveryStart));
        if (elapsed.inDays >= 7) {
          final email = await prefs.getRecoveryUserEmail();
          final name = await prefs.getRecoveryUserName();
          if (email != null && name != null) {
            final users = await prefs.getRegisteredUsers();
            final regUser = users.firstWhere((u) => u['email'] == email, orElse: () => {});
            final avatar = regUser['avatar'] ?? '';
            
            await prefs.setUserName(name);
            await prefs.setUserEmail(email);
            await prefs.setAvatarUrl(avatar);
            
            // Clear recovery state
            await prefs.setRecoveryInitiatedAt(null);
            await prefs.setRecoveryUserEmail(null);
            await prefs.setRecoveryUserName(null);
            await prefs.setRecoveryAttempts(0);
            await prefs.setRecoveryBlockedUntil(null);
            await prefs.setRecoveryHasBeenBlocked(false);
          }
        } else {
          setState(() {
            _hasActiveRecovery = true;
          });
        }
      }

      // Load authentication first so currentUser is available for other providers
      await context.read<AuthProvider>().load();
      
      // Load all other providers with a global safety timeout
      await Future.wait([
        LocalNotificationService.instance.init(),
        context.read<WalletProvider>().load(),
        context.read<TransactionProvider>().refresh(),
        context.read<TransactionProvider>().fetchTransactions(),
        context.read<ContactProvider>().fetchContacts(),
        context.read<NotificationProvider>().load(),
        context.read<BillReminderProvider>().load(),
        context.read<AuditLogProvider>().load(),
        context.read<CardsProvider>().load(),
        context.read<NoteProvider>().load(),
        context.read<TicketProvider>().load(),
      ]).timeout(const Duration(seconds: 30));

      // After loading, check for due reminders
      if (mounted) {
        context.read<BillReminderProvider>().checkDueReminders(context.read<NotificationProvider>());
      }

      // After transactions are loaded, calculate the initial stats
      if (mounted) {
        final txs = context.read<TransactionProvider>().transactions;
        context.read<WalletProvider>().calculateStats(txs);
      }      if (mounted) {
        context.read<AuditLogProvider>().logAction('System', 'Opened the wallet application');
      }

    } catch (e) {
      debugPrint('Bootstrap error (proceeding to login): $e');
    } finally {
      if (mounted) {
        final auth = context.read<AuthProvider>();
        if (auth.isAuthenticated) {
          final isBioEnabled = await PreferencesRepository.instance.getBiometricsEnabled();
          if (isBioEnabled) {
            setState(() {
              _initialized = true;
              _isLocked = true;
            });
            _authenticate();
            return;
          }
        }
        setState(() => _initialized = true);
      }
    }
  }

  Future<void> _authenticate() async {
    final success = await _biometricService.authenticate();
    if (success && mounted) {
      setState(() => _isLocked = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_initialized || _isLocked) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated logo / wordmark
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  _isLocked ? Icons.lock : Icons.account_balance_wallet,
                  color: Colors.white, 
                  size: 40
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isLocked ? 'Wallet Locked' : 'Wallet',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.5
                )
              ),
              const SizedBox(height: 32),
              if (_isLocked)
                TextButton.icon(
                  onPressed: _authenticate,
                  icon: const Icon(Icons.fingerprint, color: AppTheme.accentGreen),
                  label: const Text('Unlock Wallet', style: TextStyle(color: AppTheme.accentGreen)),
                )
              else
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                      color: AppTheme.accentGreen, strokeWidth: 2.5),
                ),
            ],
          ),
        ),
      );
    }
    final auth = context.watch<AuthProvider>();
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: _hasActiveRecovery
          ? const AccountRecoveryScreen(key: ValueKey('recovery'))
          : !auth.isAuthenticated 
              ? const LoginScreen(key: ValueKey('login')) 
              : const HomeScreen(key: ValueKey('home')),
    );
  }
}
