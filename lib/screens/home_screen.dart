import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/wallet_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/audit_log_provider.dart';
import '../providers/cards_provider.dart';
import '../providers/notification_provider.dart';
import 'dashboard_view.dart';
import 'transactions_view.dart';
import 'profile_view.dart';
import 'cards_view.dart';
import '../services/biometric_service.dart';
import '../repositories/preferences_repository.dart';
import 'package:local_auth/local_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load initial data (wallet & transactions) when the app starts
    _refreshData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometricsSuggestion();
    });
  }



  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    await Future.wait([
      context.read<WalletProvider>().load(),
      context.read<TransactionProvider>().fetchTransactions(),
      context.read<CardsProvider>().load(),
      context.read<NotificationProvider>().load(),
    ]);
  }

  Future<void> _checkBiometricsSuggestion() async {
    final prefs = PreferencesRepository.instance;
    final enabled = await prefs.getBiometricsEnabled();
    final prompted = await prefs.getHasPromptedBiometrics();

    if (!enabled && !prompted) {
      final bioService = BiometricService();
      final available = await bioService.isBiometricAvailable();
      if (available && mounted) {
        final types = await bioService.getAvailableBiometrics();
        bool hasFace = types.contains(BiometricType.face);
        bool hasFingerprint = types.contains(BiometricType.fingerprint) || types.contains(BiometricType.strong);

        String title = 'Secure Your Wallet';
        String description = 'Use biometric unlock to securely authenticate without typing passwords.';
        IconData icon = LucideIcons.fingerprint;
        String enableLabel = 'Enable Fingerprint';

        final platform = Theme.of(context).platform;
        if (platform == TargetPlatform.iOS) {
          if (hasFace) {
            title = 'Enable Face ID';
            description = 'Secure your financial credentials and sign in instantly using Face ID.';
            icon = LucideIcons.scan;
            enableLabel = 'Enable Face ID';
          } else {
            title = 'Enable Touch ID';
            description = 'Secure your financial credentials and sign in instantly using Touch ID.';
            icon = LucideIcons.fingerprint;
            enableLabel = 'Enable Touch ID';
          }
        } else {
          if (hasFace && !hasFingerprint) {
            title = 'Enable Face Unlock';
            description = 'Secure your financial credentials and sign in instantly using Face Unlock.';
            icon = LucideIcons.scan;
            enableLabel = 'Enable Face Unlock';
          } else {
            title = 'Secure with Fingerprint';
            description = 'Enable secure fingerprint verification to access your wallet seamlessly.';
            icon = LucideIcons.fingerprint;
            enableLabel = 'Enable Fingerprint';
          }
        }

        if (mounted) {
          _showBiometricPrompt(
            title: title,
            description: description,
            icon: icon,
            enableLabel: enableLabel,
            bioService: bioService,
            prefs: prefs,
          );
        }
      }
    }
  }

  void _showBiometricPrompt({
    required String title,
    required String description,
    required IconData icon,
    required String enableLabel,
    required BiometricService bioService,
    required PreferencesRepository prefs,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool isVerifying = false;
            bool isSuccess = false;
            String? errorMsg;

            Future<void> handleAuth() async {
              setModalState(() {
                isVerifying = true;
                errorMsg = null;
              });

              final success = await bioService.authenticate();
              
              if (success) {
                await prefs.setBiometricsEnabled(true);
                await prefs.setHasPromptedBiometrics(true);
                
                if (mounted) {
                  context.read<AuditLogProvider>().logAction('Biometrics', 'Successfully enabled biometric credential authentication.');
                }

                setModalState(() {
                  isSuccess = true;
                  isVerifying = false;
                });

                // Auto-close sheet after a brief success animation delay
                await Future.delayed(const Duration(milliseconds: 1200));
                if (mounted) {
                  Navigator.pop(context);
                }
              } else {
                setModalState(() {
                  isVerifying = false;
                  errorMsg = 'Verification failed. Please try again.';
                });
              }
            }

            Future<void> handleDismiss() async {
              await prefs.setHasPromptedBiometrics(true);
              if (mounted) {
                Navigator.pop(context);
              }
            }

            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle indicator bar
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.textGrey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Circular Biometric Icon with beautiful custom pulsing gradient shadow
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isSuccess 
                          ? AppTheme.accentGreen.withValues(alpha: 0.15) 
                          : AppTheme.primaryPurple.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSuccess ? AppTheme.accentGreen : AppTheme.primaryPurple.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      isSuccess ? LucideIcons.check : icon,
                      size: 48,
                      color: isSuccess ? AppTheme.accentGreen : AppTheme.primaryPurple,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Prompt Title
                  Text(
                    isSuccess ? 'Success!' : title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Prompt Description
                  Text(
                    isSuccess 
                        ? 'Biometrics enabled successfully. You can now use Face ID / Fingerprint to log in securely next time!'
                        : description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (errorMsg != null) ...[
                    Text(
                      errorMsg!,
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (isVerifying) ...[
                    const CircularProgressIndicator(color: AppTheme.primaryPurple),
                    const SizedBox(height: 16),
                    const Text('Awaiting authentication...', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                  ] else if (!isSuccess) ...[
                    // Verification and cancel CTA buttons
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: handleAuth,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Text(enableLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: TextButton(
                        onPressed: handleDismiss,
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.textGrey,
                        ),
                        child: const Text('Maybe Later', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 56), // spacer during success view
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  static const _navItems = [
    _NavItem(icon: LucideIcons.home, label: 'Home', index: 0),
    _NavItem(icon: LucideIcons.arrowLeftRight, label: 'Transactions', index: 1),
    _NavItem(icon: LucideIcons.creditCard, label: 'Cards', index: 2),
    _NavItem(icon: LucideIcons.user, label: 'Profile', index: 3),
  ];

  final List<Widget> _pages = [
    const DashboardView(key: PageStorageKey('dashboard')),
    const TransactionsView(key: PageStorageKey('transactions')),
    const CardsView(key: PageStorageKey('cards')),
    const ProfileView(key: PageStorageKey('profile')),
  ];

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final int currentIndex = nav.selectedIndex;
    
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: Container(
            key: ValueKey<int>(currentIndex),
            child: _pages[currentIndex],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(nav),
    );
  }

  Widget _buildBottomBar(NavigationProvider nav) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).padding.bottom + 16),
      height: 72,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withValues(
                alpha: isDark ? 0.45 : 0.75,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.4),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final tabWidth = totalWidth / _navItems.length;
                const double pillWidth = 58;
                const double pillHeight = 46;
                
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Sliding Liquid Indicator Pill
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutBack,
                      left: nav.selectedIndex * tabWidth + (tabWidth - pillWidth) / 2,
                      top: 13, // Vertically centered: (72 - 46) / 2
                      child: Container(
                        width: pillWidth,
                        height: pillHeight,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.primaryPurple.withValues(alpha: 0.25),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryPurple.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Navigation Tabs
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _navItems
                          .map((item) => _buildNavItem(nav, item))
                          .toList(),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(NavigationProvider nav, _NavItem item) {
    final isSelected = nav.selectedIndex == item.index;
    final String tabName = item.label == 'Home' ? 'Dashboard' : item.label;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (nav.selectedIndex != item.index) {
            nav.setIndex(item.index);
            context.read<AuditLogProvider>().logAction('Navigation', 'Opened the $tabName screen');
          }
        },
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Icon(
                  item.icon,
                  size: 20,
                  color: isSelected ? AppTheme.primaryPurple : AppTheme.textGrey,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryPurple : AppTheme.textGrey,
                  letterSpacing: 0.2,
                ),
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;
  const _NavItem({required this.icon, required this.label, required this.index});
}
