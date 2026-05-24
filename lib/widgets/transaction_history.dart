import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audit_log_provider.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';
import 'transaction_card.dart';
import '../screens/transactions_screen.dart';

class TransactionHistory extends StatelessWidget {
  const TransactionHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final recent = txProvider.transactions.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Transactions',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TransactionsScreen())),
              child: const Text('See all',
                  style: TextStyle(fontSize: 12, color: AppTheme.textGrey)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Removed blocking spinner to ensure the UI remains responsive
        if (recent.isEmpty && !txProvider.isLoading)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text('No transactions yet',
                  style: TextStyle(color: AppTheme.textGrey.withValues(alpha: 0.6))),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recent.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final tx = recent[index];
              return Dismissible(
                key: Key(tx.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                ),
                onDismissed: (_) {
                  txProvider.deleteTransaction(tx.id, context.read<AuditLogProvider>());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Transaction deleted'),
                    ),
                  );
                },
                child: TransactionCard(transaction: tx),
              );
            },
          ),
        if (txProvider.isLoading && recent.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentGreen))),
          ),
      ],
    );
  }
}
