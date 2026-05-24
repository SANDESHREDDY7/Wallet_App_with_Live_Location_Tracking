import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../providers/audit_log_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _searchQuery = '';
  TransactionType? _filterType;

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
    final txProvider = context.watch<TransactionProvider>();
    final filtered = txProvider.transactions.where((tx) {
      final matchesSearch = _searchQuery.isEmpty ||
          tx.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _filterType == null || tx.type == _filterType;
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: const Text('All Transactions', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: const BackButton(),
        actions: [
          PopupMenuButton<TransactionType?>(
            icon: const Icon(Icons.filter_list),
            color: AppTheme.cardDark,
            onSelected: (v) => setState(() => _filterType = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: TransactionType.credit, child: Text('Credits', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: TransactionType.debit, child: Text('Debits', style: TextStyle(color: Colors.white))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textGrey),
                filled: true, fillColor: AppTheme.cardDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: txProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accentGreen))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.inbox, size: 48, color: Colors.white.withValues(alpha: 0.2)),
                            const SizedBox(height: 12),
                            Text('No transactions found',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppTheme.accentGreen,
                        onRefresh: txProvider.refresh,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final tx = filtered[i];
                            final color = _colorForCategory(tx.category);
                            return Dismissible(
                              key: Key(tx.id),
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
                              onDismissed: (_) => context.read<TransactionProvider>().deleteTransaction(tx.id, context.read<AuditLogProvider>()),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardDark,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15), shape: BoxShape.circle,
                                      ),
                                      child: Icon(_iconForCategory(tx.category), color: color, size: 20),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(tx.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 2),
                                          Text(
                                            DateFormat('MMM d, yyyy').format(tx.date),
                                            style: const TextStyle(fontSize: 11, color: AppTheme.textGrey),
                                          ),
                                          if (tx.note != null)
                                            Text(tx.note!, style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      tx.formattedAmount,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: tx.isCredit ? AppTheme.accentGreen : Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
