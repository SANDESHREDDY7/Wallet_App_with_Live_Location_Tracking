import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/navigation_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/balance_card.dart';
import '../widgets/quick_actions.dart';
import '../widgets/transaction_history.dart';
import '../widgets/notes_module.dart';

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/wallet_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/user.dart';
import 'notification_screen.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final notifications = context.watch<NotificationProvider>();

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          context.read<WalletProvider>().load(),
          context.read<TransactionProvider>().fetchTransactions(),
        ]);
      },
      color: AppTheme.primaryPurple,
      backgroundColor: Theme.of(context).cardColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _fadeIn(child: _buildHeader(context, user, notifications), delay: 0),
            const SizedBox(height: 24),
            _fadeIn(child: const BalanceCard(), delay: 100),
            const SizedBox(height: 32),
            _fadeIn(child: const QuickActions(), delay: 200),
            const SizedBox(height: 32),
            _fadeIn(child: const NotesModule(), delay: 300),
            const SizedBox(height: 32),
            _fadeIn(child: const TransactionHistory(), delay: 400),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _fadeIn({required Widget child, int delay = 0}) {
    return RepaintBoundary( // Prevent unnecessary repaints during animation
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: child,
          );
        },
        child: child,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, User? user, NotificationProvider notifications) {
    final String name = user?.name ?? 'Loading...';
    final String avatarUrl = user?.avatarUrl ?? '';

    return Row(
      children: [
        GestureDetector(
          onTap: () => context.read<NavigationProvider>().setIndex(3),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryPurple, AppTheme.accentOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryPurple.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'J',
                      style: const TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    if (avatarUrl.isNotEmpty)
                      Image(
                        image: avatarUrl.startsWith('assets')
                            ? AssetImage(avatarUrl) as ImageProvider
                            : (avatarUrl.startsWith('http') || avatarUrl.startsWith('blob') || kIsWeb
                                ? NetworkImage(avatarUrl)
                                : FileImage(File(avatarUrl))),
                        fit: BoxFit.cover,
                        width: 50,
                        height: 50,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back,', 
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textGrey : const Color(0xFF64748B), 
                fontSize: 12,
                fontWeight: FontWeight.w500,
              )
            ),
            Text(name,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        const Spacer(),
        Stack(
          children: [
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (context) => DraggableScrollableSheet(
                    initialChildSize: 0.9,
                    maxChildSize: 0.95,
                    minChildSize: 0.5,
                    builder: (context, scrollController) => const NotificationScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(LucideIcons.bell, size: 20),
              ),
            ),
            if (notifications.hasUnread)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                      color: Colors.redAccent, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      '${notifications.unreadCount}',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
