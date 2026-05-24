import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/navigation_provider.dart';
import '../theme/app_theme.dart';
import '../providers/audit_log_provider.dart';
import '../screens/add_money_screen.dart';
import '../screens/send_money_screen.dart';
import '../screens/pay_bill_screen.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? [AppTheme.primaryPurple, AppTheme.bgDark, Colors.black]
              : [AppTheme.primaryPurple, const Color(0xFF4F46E5), const Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Balance',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          wallet.isLoading
              ? const SizedBox(
                  height: 44,
                  child: Center(child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)))
              : Text(
                  wallet.formattedBalance,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 36,
                    letterSpacing: -1,
                  ),
                ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildGlassButton(
                icon: Icons.add,
                label: 'Add Money',
                onTap: () {
                  context.read<AuditLogProvider>().logAction('Tap', 'Opened Add Money screen');
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMoneyScreen()));
                },
              ),
              _buildGlassButton(
                icon: Icons.swap_horiz,
                label: 'Transfer',
                onTap: () {
                  context.read<AuditLogProvider>().logAction('Tap', 'Opened Transfer (Send Money) screen');
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SendMoneyScreen()));
                },
              ),
              _buildGlassButton(
                icon: Icons.receipt_long,
                label: 'Pay Bill',
                onTap: () {
                  context.read<AuditLogProvider>().logAction('Tap', 'Opened Pay Bill screen');
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PayBillScreen()));
                },
              ),
              _buildGlassButton(
                icon: Icons.settings,
                label: 'Setting',
                onTap: () {
                  context.read<AuditLogProvider>().logAction('Tap', 'Navigated to Profile Settings via settings icon');
                  context.read<NavigationProvider>().setIndex(3);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
