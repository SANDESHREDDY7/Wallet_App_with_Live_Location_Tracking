import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/wallet_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/audit_log_provider.dart';
import '../theme/app_theme.dart';
import '../screens/loans_screen.dart';
import '../screens/partying_screen.dart';
import '../screens/tickets_view.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem(
        label: 'Recharge',
        icon: LucideIcons.smartphone,
        onTap: () => _showRechargeSheet(context),
      ),
      _ActionItem(
        label: 'Partying',
        icon: LucideIcons.music,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PartyingScreen())),
      ),
      _ActionItem(
        label: 'Loan',
        icon: LucideIcons.wallet,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoansScreen())),
      ),
      _ActionItem(
        label: 'Tickets',
        icon: LucideIcons.ticket,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TicketsScreen())),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Quick Action',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),

          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: actions
              .map((a) => _buildActionButton(context, a))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, _ActionItem action) {
    // Premium designer multi-stop gradient colors and matching glow lights
    List<Color> gradientColors;
    Color glowColor;
    
    if (action.label == 'Recharge') {
      gradientColors = [const Color(0xFF2193b0), const Color(0xFF6dd5ed)]; // Electric Cyan
      glowColor = const Color(0xFF2193b0);
    } else if (action.label == 'Partying') {
      gradientColors = [const Color(0xFF8A2387), const Color(0xFFE94057)]; // Cosmic Sunset
      glowColor = const Color(0xFFE94057);
    } else if (action.label == 'Loan') {
      gradientColors = [const Color(0xFFf857a6), const Color(0xFFff5858)]; // Velvet Pink-Orange
      glowColor = const Color(0xFFff5858);
    } else if (action.label == 'Tickets') {
      gradientColors = [const Color(0xFF11998e), const Color(0xFF38ef7d)]; // Emerald Mint
      glowColor = const Color(0xFF11998e);
    } else {
      gradientColors = [const Color(0xFF4e54c8), const Color(0xFF8f94fb)]; // Lavender Indigo
      glowColor = const Color(0xFF4e54c8);
    }

    return _PressableScale(
      onTap: () {
        context.read<AuditLogProvider>().logAction('Tap', 'Clicked on "${action.label}" quick action');
        action.onTap();
      },
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(21),
              child: Stack(
                children: [
                  // Frosty Glass Backdrop
                  Positioned.fill(
                    child: Container(
                      color: Theme.of(context).cardColor.withValues(alpha: 0.45),
                    ),
                  ),
                  // Blurred Ambient Radial Light Sphere
                  Positioned(
                    top: -12,
                    left: -12,
                    right: -12,
                    bottom: -12,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            glowColor.withValues(alpha: 0.25),
                            glowColor.withValues(alpha: 0.0),
                          ],
                          radius: 0.85,
                        ),
                      ),
                    ),
                  ),
                  // High-Contrast Premium Gradient Icon Orb
                  Center(
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: glowColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Icon(
                        action.icon,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            action.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.9),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }


  // ---------------------------------------------------------------------------
  // Bottom sheets for each quick action
  // ---------------------------------------------------------------------------

  void _showRechargeSheet(BuildContext context) {
    final amountCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    _showActionSheet(
      context: context,
      title: 'Recharge',
      accentColor: Colors.cyanAccent,
      fields: [
        _SheetField(controller: phoneCtrl, hint: 'Phone number', isNumeric: false),
        _SheetField(controller: amountCtrl, hint: 'Amount (₹)', isNumeric: true),
      ],
      onConfirm: () async {
        final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
        if (amount <= 0) return;
        final wallet = context.read<WalletProvider>();
        final tx = context.read<TransactionProvider>();
        final audit = context.read<AuditLogProvider>();
        await wallet.recharge(
              operator: 'Mobile',
              amount: amount,
              phone: phoneCtrl.text.trim(),
              audit: audit,
            );
        await tx.refresh();
        wallet.calculateStats(tx.transactions);
      },
      buttonLabel: 'Recharge Now',
      buttonColor: Colors.cyanAccent,
    );
  }

  void _showDonateSheet(BuildContext context) {
    final amountCtrl = TextEditingController();
    final causeCtrl = TextEditingController();
    _showActionSheet(
      context: context,
      title: 'Charity Donation',
      accentColor: Colors.pinkAccent,
      fields: [
        _SheetField(controller: causeCtrl, hint: 'Cause / Organisation', isNumeric: false),
        _SheetField(controller: amountCtrl, hint: 'Amount (₹)', isNumeric: true),
      ],
      onConfirm: () async {
        final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
        if (amount <= 0) return;
        final wallet = context.read<WalletProvider>();
        final tx = context.read<TransactionProvider>();
        final audit = context.read<AuditLogProvider>();
        await wallet.donate(
              cause: causeCtrl.text.trim().isEmpty ? 'Charity' : causeCtrl.text.trim(),
              amount: amount,
              audit: audit,
            );
        await tx.refresh();
        wallet.calculateStats(tx.transactions);
      },
      buttonLabel: 'Donate',
      buttonColor: Colors.pinkAccent,
    );
  }


  void _showBankTransferSheet(BuildContext context) {
    final amountCtrl = TextEditingController();
    final bankCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    _showActionSheet(
      context: context,
      title: 'Bank to Bank',
      accentColor: Colors.tealAccent,
      fields: [
        _SheetField(controller: bankCtrl, hint: 'Bank / Account name', isNumeric: false),
        _SheetField(controller: amountCtrl, hint: 'Amount (₹)', isNumeric: true),
        _SheetField(controller: noteCtrl, hint: 'Note (optional)', isNumeric: false),
      ],
      onConfirm: () async {
        final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
        if (amount <= 0) return;
        final wallet = context.read<WalletProvider>();
        final tx = context.read<TransactionProvider>();
        final audit = context.read<AuditLogProvider>();
        await wallet.bankTransfer(
              bankName: bankCtrl.text.trim().isEmpty ? 'Bank' : bankCtrl.text.trim(),
              amount: amount,
              note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
              audit: audit,
            );
        await tx.refresh();
        wallet.calculateStats(tx.transactions);
      },
      buttonLabel: 'Transfer',
      buttonColor: Colors.tealAccent,
    );
  }

  void _showActionSheet({
    required BuildContext context,
    required String title,
    required Color accentColor,
    required List<_SheetField> fields,
    required Future<void> Function() onConfirm,
    required String buttonLabel,
    required Color buttonColor,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4, height: 24,
                  decoration: BoxDecoration(
                      color: accentColor, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 12),
                Text(title,
                    style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold, 
                        color: Theme.of(context).textTheme.bodyLarge?.color)),
              ],
            ),
            const SizedBox(height: 20),
            ...fields.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextField(
                    controller: f.controller,
                    keyboardType: f.isNumeric
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.text,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: f.hint,
                      hintStyle: TextStyle(color: AppTheme.textGrey.withValues(alpha: 0.5)),
                      filled: true, 
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                    ),
                  ),
                )),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await onConfirm();
                    HapticFeedback.mediumImpact();
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('$title completed!'),
                        backgroundColor: accentColor.withValues(alpha: 0.8),
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(buttonLabel,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionItem({required this.label, required this.icon, required this.onTap});
}

class _SheetField {
  final TextEditingController controller;
  final String hint;
  final bool isNumeric;
  const _SheetField({required this.controller, required this.hint, required this.isNumeric});
}

class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableScale({required this.child, required this.onTap});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
