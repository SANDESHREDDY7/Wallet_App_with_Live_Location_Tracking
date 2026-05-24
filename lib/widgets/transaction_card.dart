import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/audit_log_provider.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';

class TransactionCard extends StatelessWidget {
  final WalletTransaction transaction;
  final VoidCallback? onDelete;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onDelete,
  });

  IconData _iconForCategory(TransactionCategory cat) {
    switch (cat) {
      case TransactionCategory.entertainment: return LucideIcons.music;
      case TransactionCategory.shopping: return LucideIcons.shoppingCart;
      case TransactionCategory.transfer: return LucideIcons.send;
      case TransactionCategory.food: return LucideIcons.utensils;
      case TransactionCategory.utilities: return LucideIcons.zap;
      case TransactionCategory.loan: return LucideIcons.wallet;
      case TransactionCategory.recharge: return LucideIcons.smartphone;
      case TransactionCategory.charity: return LucideIcons.heart;
      case TransactionCategory.bankTransfer: return LucideIcons.landmark;
      case TransactionCategory.other: return LucideIcons.circle;
    }
  }

  Color _colorForCategory(TransactionCategory cat) {
    switch (cat) {
      case TransactionCategory.entertainment: return Colors.greenAccent;
      case TransactionCategory.shopping: return Colors.blueAccent;
      case TransactionCategory.transfer: return Colors.blue;
      case TransactionCategory.food: return Colors.orangeAccent;
      case TransactionCategory.utilities: return Colors.yellowAccent;
      case TransactionCategory.loan: return Colors.purpleAccent;
      case TransactionCategory.recharge: return Colors.cyanAccent;
      case TransactionCategory.charity: return Colors.pinkAccent;
      case TransactionCategory.bankTransfer: return Colors.tealAccent;
      case TransactionCategory.other: return AppTheme.textGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForCategory(transaction.category);
    
    Widget content = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Theme.of(context).brightness == Brightness.dark 
            ? Border.all(color: Theme.of(context).dividerColor) 
            : null,
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(_iconForCategory(transaction.category), color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM d, yyyy').format(transaction.date),
                  style: const TextStyle(fontSize: 11, color: AppTheme.textGrey),
                ),
              ],
            ),
          ),
          Text(
            transaction.formattedAmount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: transaction.isCredit ? AppTheme.accentGreen : Colors.redAccent,
            ),
          ),
        ],
      ),
    );

    if (onDelete != null) {
      return Dismissible(
        key: Key(transaction.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.redAccent),
        ),
        onDismissed: (_) {
          HapticFeedback.mediumImpact();
          onDelete!();
        },
        child: content,
      );
    }

    return GestureDetector(
      onTap: () {
        context.read<AuditLogProvider>().logAction('Tap', 'Viewed transaction details for: ${transaction.name}');
      },
      child: content,
    );
  }
}
