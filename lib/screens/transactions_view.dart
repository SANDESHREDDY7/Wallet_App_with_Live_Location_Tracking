import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../widgets/transaction_card.dart';
import '../providers/audit_log_provider.dart';

class TransactionsView extends StatefulWidget {
  const TransactionsView({super.key});

  @override
  State<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<TransactionsView> {
  @override
  void initState() {
    super.initState();
    // Ensure transactions are fetched when the view is first displayed
    final provider = context.read<TransactionProvider>();
    if (provider.transactions.isEmpty) {
      provider.fetchTransactions();
    }
  }
  String _searchQuery = '';
  TransactionType? _filterType;

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final filtered = txProvider.transactions.where((tx) {
      final matchesSearch = _searchQuery.isEmpty ||
          tx.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _filterType == null || tx.type == _filterType;
      return matchesSearch && matchesFilter;
    }).toList();

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Transactions', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              PopupMenuButton<TransactionType?>(
                icon: Icon(Icons.filter_list, color: isDark ? Colors.white : AppTheme.primaryPurple),
                color: isDark ? AppTheme.cardDark : Colors.white,
                onSelected: (v) => setState(() => _filterType = v),
                itemBuilder: (_) => [
                  PopupMenuItem(value: null, child: Text('All', style: TextStyle(color: isDark ? Colors.white : Colors.black))),
                  PopupMenuItem(value: TransactionType.credit, child: Text('Credits', style: TextStyle(color: isDark ? Colors.white : Colors.black))),
                  PopupMenuItem(value: TransactionType.debit, child: Text('Debits', style: TextStyle(color: isDark ? Colors.white : Colors.black))),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: TextField(
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Search transactions...',
              hintStyle: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3)),
              prefixIcon: const Icon(Icons.search, color: AppTheme.textGrey),
              filled: true, 
              fillColor: isDark ? AppTheme.cardDark : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16), 
                borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16), 
                borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
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
                          Icon(LucideIcons.inbox, size: 48, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2)),
                          const SizedBox(height: 12),
                          Text('No transactions found',
                              style: TextStyle(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4))),
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
                          return TransactionCard(
                            transaction: filtered[i],
                            onDelete: () => context.read<TransactionProvider>().deleteTransaction(filtered[i].id, context.read<AuditLogProvider>()),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
