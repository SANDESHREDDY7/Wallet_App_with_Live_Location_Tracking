import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/contact_provider.dart';
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';
import '../providers/audit_log_provider.dart';
import '../providers/note_provider.dart';

import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _handleSubmit() async {
    final auth = context.read<AuthProvider>();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all details')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await auth.login('User', phone, password);
      
      if (mounted) {
        context.read<AuditLogProvider>().logAction('Auth', 'Logged in securely with ${_phoneController.text.trim()}');
        // Force refresh all data for the new user session
        await Future.wait([
          context.read<WalletProvider>().load(),
          context.read<TransactionProvider>().fetchTransactions(),
          context.read<ContactProvider>().fetchContacts(),
          context.read<NotificationProvider>().load(),
          context.read<NoteProvider>().load(),
        ]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.wallet, size: 48, color: AppTheme.accentGreen),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      'Welcome Back',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                  const Center(
                    child: Text(
                      'Log in to your secure wallet',
                      style: TextStyle(color: AppTheme.textGrey, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 48),
                  _buildTextField(
                    controller: _phoneController,
                    hint: 'Mobile Number',
                    icon: LucideIcons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _passwordController,
                    hint: 'Password',
                    icon: LucideIcons.lock,
                    isPassword: true,
                    obscureText: _obscurePassword,
                    onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                        );
                      },
                      child: const Text('Forgot Password?', style: TextStyle(color: AppTheme.accentYellow)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGreen,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Log In',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        onTap: () {
                          debugPrint('Navigating to SignupScreen...');
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SignupScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: RichText(
                            text: const TextSpan(
                              text: 'Don\'t have an account? ',
                              style: TextStyle(color: AppTheme.textGrey),
                              children: [
                                TextSpan(
                                  text: 'Sign Up',
                                  style: TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: _showSecurityInstructions,
                      icon: const Icon(LucideIcons.info, size: 16, color: AppTheme.textGrey),
                      label: const Text(
                        'Security Instructions & Recovery Rules',
                        style: TextStyle(
                          color: AppTheme.textGrey,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.accentGreen),
              ),
            ),
        ],
      ),
    );
  }

  void _showSecurityInstructions() {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.82,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.bgDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Bottom Sheet Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.shieldCheck, color: AppTheme.accentGreen, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Security Console',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 24),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _buildInstructionSection(
                      icon: LucideIcons.userCheck,
                      iconColor: AppTheme.primaryPurple,
                      title: 'Credentials & Mobile Auth',
                      description:
                          'Your account is strictly tied to your Username and Mobile Number. Traditional email parameters are completely omitted to prevent hijacking, phishing, or spam.',
                    ),
                    _buildInstructionSection(
                      icon: LucideIcons.fingerprint,
                      iconColor: Colors.blueAccent,
                      title: 'Biometrics (Face ID & Touch ID)',
                      description:
                          'After your very first successful login, the app will prompt you to link biometrics (Face ID for iOS, Fingerprint/Face for Android) to instantly log in later without entering passwords.',
                    ),
                    _buildInstructionSection(
                      icon: LucideIcons.alertTriangle,
                      iconColor: AppTheme.accentYellow,
                      title: 'Recovery Attempts & Cooldown',
                      description:
                          'If you click "Forgot Password", entering either the username or mobile number incorrectly grants you exactly 3 attempts. Upon the 3rd failure, the console initiates a strict 1-hour retry cooldown block.',
                    ),
                    _buildInstructionSection(
                      icon: LucideIcons.trash2,
                      iconColor: Colors.redAccent,
                      title: 'Self-Destruct Protection',
                      description:
                          'If subsequent recovery attempts are made with incorrect credentials, the system permanently erases the user profile, transactions, audit logs, and secure database sandbox storage to safeguard your funds.',
                    ),
                    _buildInstructionSection(
                      icon: LucideIcons.timer,
                      iconColor: Colors.amberAccent,
                      title: 'The 2-Day Security holding timer',
                      description:
                          'Once you submit the correct Username and Mobile Number recovery details, a 2-day countdown timer begins as a security cooling period to prevent hijacking.',
                    ),
                    _buildInstructionSection(
                      icon: LucideIcons.refreshCw,
                      iconColor: AppTheme.accentGreen,
                      title: '7-Day Automatic Login',
                      description:
                          'After exactly 7 days from starting a recovery request, the application automatically logs you back into your session securely, resetting recovery lock states.',
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text('I Understand', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstructionSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                    height: 1.45,
                  ),
                ),
              ],
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
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
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
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.textGrey),
          prefixIcon: Icon(icon, color: AppTheme.textGrey, size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(obscureText ? LucideIcons.eyeOff : LucideIcons.eye, color: AppTheme.textGrey, size: 20),
                  onPressed: onToggleVisibility,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
