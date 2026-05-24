import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../repositories/preferences_repository.dart';
import '../services/biometric_service.dart';
import '../providers/navigation_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'bill_reminders_screen.dart';
import '../providers/audit_log_provider.dart';
import '../providers/cards_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/note_provider.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<AuthProvider>();
    final user = userProvider.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: () => _showAvatarPicker(context, userProvider),
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: AppTheme.accentOrange,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'J',
                            style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          if (user?.avatarUrl.isNotEmpty == true)
                            Image(
                              image: user!.avatarUrl.startsWith('assets')
                                  ? AssetImage(user.avatarUrl) as ImageProvider
                                  : (user.avatarUrl.startsWith('http') || user.avatarUrl.startsWith('blob') || kIsWeb
                                      ? NetworkImage(user.avatarUrl)
                                      : FileImage(File(user.avatarUrl))),
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: AppTheme.accentGreen, shape: BoxShape.circle),
                      child: const Icon(LucideIcons.camera, size: 20, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(user?.name ?? 'Loading...', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(user?.email ?? '', style: const TextStyle(color: AppTheme.textGrey)),
          const SizedBox(height: 40),
          _buildMenuItem(
            context: context,
            icon: LucideIcons.user,
            title: 'Personal Information',
            onTap: () => _showEditProfileDialog(context, userProvider),
          ),
          _buildMenuItem(
            context: context,
            icon: LucideIcons.shield,
            title: 'Security',
            onTap: () => _showSecurityDialog(context),
          ),
          _buildMenuItem(
            context: context,
            icon: LucideIcons.bell,
            title: 'Notifications',
            onTap: () => _showNotificationsDialog(context),
          ),
          _buildMenuItem(
            context: context,
            icon: LucideIcons.calendarClock,
            title: 'Bill Reminders',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BillRemindersScreen())),
          ),
          _buildMenuItem(
            context: context,
            icon: LucideIcons.helpCircle,
            title: 'Help & Support',
            onTap: () => _showHelpDialog(context),
          ),
          const SizedBox(height: 16),
          Consumer<ThemeProvider>(
            builder: (context, theme, child) => _buildMenuItem(
              context: context,
              icon: LucideIcons.palette,
              title: 'Theme Preference',
              trailing: Text(
                theme.themeMode == ThemeMode.system ? 'System' : (theme.themeMode == ThemeMode.dark ? 'Dark' : 'Light'),
                style: const TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold),
              ),
              onTap: () => _showThemeSelector(context, theme),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  final auth = context.read<AuthProvider>();
                  final nav = context.read<NavigationProvider>();
                  
                  await auth.logout();
                  nav.reset();
                  
                  if (context.mounted) {
                    context.read<TransactionProvider>().clear();
                    context.read<CardsProvider>().clear();
                    context.read<NoteProvider>().clear();
                    context.read<AuditLogProvider>().logAction('Auth', 'Securely logged out of account: ${user?.email ?? 'Unknown'}');
                  }
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logged out successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Logout failed: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                foregroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: () {
        context.read<AuditLogProvider>().logAction('Tap', 'Clicked on profile menu item: $title');
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 20),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
            const Spacer(),
            trailing ?? const Icon(LucideIcons.chevronRight, color: AppTheme.textGrey, size: 16),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthProvider provider) {
    final user = provider.currentUser;
    final nameController = TextEditingController(text: user?.name);
    final phoneController = TextEditingController(text: user?.email);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Edit Profile', style: TextStyle(color: Theme.of(context).textTheme.headlineMedium?.color)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: AppTheme.textGrey)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: const InputDecoration(labelText: 'Mobile Number', labelStyle: TextStyle(color: AppTheme.textGrey)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (user != null) {
                provider.updateUser(user.copyWith(
                  name: nameController.text.trim(),
                  email: phoneController.text.trim(),
                ));
              }
              Navigator.pop(ctx);
            },
            child: Text('Save', style: TextStyle(color: Theme.of(context).primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showSecurityDialog(BuildContext context) async {
    final prefs = PreferencesRepository.instance;
    final biometricService = BiometricService();
    bool isBiometricEnabled = await prefs.getBiometricsEnabled();
    final bool isHardwareSupported = await biometricService.isBiometricAvailable();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text('Security Settings', style: TextStyle(color: Theme.of(context).textTheme.headlineMedium?.color)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(LucideIcons.fingerprint, color: Theme.of(context).primaryColor),
                title: Text('Biometric Authentication', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                subtitle: !isHardwareSupported 
                  ? const Text('Not supported on this device', style: TextStyle(color: Colors.red, fontSize: 10))
                  : null,
                trailing: Switch(
                  value: isBiometricEnabled,
                  onChanged: !isHardwareSupported ? null : (val) async {
                    if (val) {
                      // Authenticate before enabling
                      final success = await biometricService.authenticate();
                      if (success) {
                        await prefs.setBiometricsEnabled(true);
                        setModalState(() => isBiometricEnabled = true);
                      }
                    } else {
                      await prefs.setBiometricsEnabled(false);
                      setModalState(() => isBiometricEnabled = false);
                    }
                  },
                  activeThumbColor: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final notificationProvider = context.watch<NotificationProvider>();
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text('Notifications', style: TextStyle(color: Theme.of(context).textTheme.headlineMedium?.color)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text('Push Notifications', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                subtitle: const Text('Receive alerts for transactions', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                value: notificationProvider.enabled,
                onChanged: (val) => notificationProvider.setEnabled(val),
                activeColor: Theme.of(context).primaryColor,
              ),
              ListTile(
                title: Text('Clear All Notifications', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                onTap: () {
                  notificationProvider.markAllRead();
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        );
      },
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(LucideIcons.helpCircle, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Text('Help & Support', style: TextStyle(color: Theme.of(context).textTheme.headlineMedium?.color)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('App Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                'Wallet App is a premium financial management tool designed for modern users to track spending, manage loans, and split expenses effortlessly.',
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14),
              ),
              const SizedBox(height: 20),
              const Text('Use Cases', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _buildBulletPoint(context, 'Track daily transactions and spending habits.'),
              _buildBulletPoint(context, 'Manage Peer-to-Peer loans with a professional interface.'),
              _buildBulletPoint(context, 'Split party and travel expenses among friends.'),
              _buildBulletPoint(context, 'Organize and secure digital payment cards.'),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Copyright & Ownership Notice',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryPurple),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This application, including its design, features, content, source code, and functionality, is the intellectual property of Sandesh Reddy. Unauthorized copying, modification, distribution, or misuse of this application or any part of it is strictly prohibited.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '© 2026 Sandesh Reddy. All Rights Reserved.',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textGrey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text('Version 2.5.0 • Support: support@walletapp.com', 
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 10)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it')),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13))),
        ],
      ),
    );
  }

  void _showAvatarPicker(BuildContext context, AuthProvider provider) {
    final List<String> avatars = [
      'assets/avatars/memoji_1.png',
      'assets/avatars/memoji_2.png',
      'assets/avatars/memoji_3.png',
      'assets/avatars/memoji_4.png',
      'assets/avatars/memoji_5.png',
      'assets/avatars/memoji_6.png',
      'assets/avatars/memoji_7.png',
      'assets/avatars/memoji_8.png',
      'assets/avatars/memoji_9.png',
      'assets/avatars/memoji_10.png',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Choose Avatar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.headlineMedium?.color)),
                  TextButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                      final currentUser = provider.currentUser;
                      if (image != null && currentUser != null) {
                        provider.updateUser(currentUser.copyWith(avatarUrl: image.path));
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    icon: Icon(LucideIcons.upload, size: 18, color: Theme.of(context).primaryColor),
                    label: Text('Upload', style: TextStyle(color: Theme.of(context).primaryColor)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: avatars.length,
                itemBuilder: (ctx, index) => GestureDetector(
                  onTap: () {
                    final user = provider.currentUser;
                    if (user != null) {
                      provider.updateUser(user.copyWith(avatarUrl: avatars[index]));
                    }
                    Navigator.pop(ctx);
                  },
                  child: ClipOval(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(LucideIcons.user, color: Colors.white24),
                        Image(
                          image: avatars[index].startsWith('assets') 
                              ? AssetImage(avatars[index]) as ImageProvider
                              : (avatars[index].startsWith('http') || avatars[index].startsWith('blob') || kIsWeb
                                  ? NetworkImage(avatars[index])
                                  : FileImage(File(avatars[index]))),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeSelector(BuildContext context, ThemeProvider theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Appearance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildThemeOption(context, theme, ThemeMode.system, 'System Default', LucideIcons.monitor),
            const SizedBox(height: 12),
            _buildThemeOption(context, theme, ThemeMode.light, 'Light Mode', LucideIcons.sun),
            const SizedBox(height: 12),
            _buildThemeOption(context, theme, ThemeMode.dark, 'Dark Mode', LucideIcons.moon),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, ThemeProvider theme, ThemeMode mode, String title, IconData icon) {
    final isSelected = theme.themeMode == mode;
    return GestureDetector(
      onTap: () {
        theme.setThemeMode(mode);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryPurple.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppTheme.primaryPurple : Theme.of(context).dividerColor.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primaryPurple : AppTheme.textGrey, size: 20),
            const SizedBox(width: 16),
            Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? AppTheme.primaryPurple : null)),
            const Spacer(),
            if (isSelected) const Icon(LucideIcons.check, color: AppTheme.primaryPurple, size: 18),
          ],
        ),
      ),
    );
  }
}
