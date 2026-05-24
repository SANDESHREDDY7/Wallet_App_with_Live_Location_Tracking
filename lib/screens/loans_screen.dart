import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/audit_log_provider.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';

class LoansScreen extends StatelessWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Text('My Loans', style: TextStyle(color: Theme.of(context).textTheme.headlineMedium?.color, fontWeight: FontWeight.bold)),
          iconTheme: IconThemeData(color: Theme.of(context).textTheme.headlineMedium?.color),
          bottom: const TabBar(
            indicatorColor: Colors.purpleAccent,
            labelColor: Colors.purpleAccent,
            unselectedLabelColor: AppTheme.textGrey,
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/ptp_loan_bg_1778959614160.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
                      Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
                      Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.98),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Consumer<TransactionProvider>(
              builder: (context, txProvider, child) {
                final allLoans = txProvider.transactions.where((t) => t.category == TransactionCategory.loan).toList();
                final activeLoans = allLoans.where((t) => !t.isCleared).toList();
                final historyLoans = allLoans.where((t) => t.isCleared).toList();

                return TabBarView(
                  children: [
                    _buildLoansList(context, activeLoans, isActive: true),
                    _buildLoansList(context, historyLoans, isActive: false),
                  ],
                );
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.purpleAccent,
          onPressed: () {
            context.read<AuditLogProvider>().logAction('Tap', 'Opened Receive Loan sheet');
            _showLoanSheet(context);
          },
          icon: const Icon(LucideIcons.plus, color: Colors.white),
          label: const Text('Take Loan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildLoansList(BuildContext context, List<WalletTransaction> loans, {required bool isActive}) {
    return Column(
      children: [
        if (isActive)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purpleAccent.withValues(alpha: 0.8), Colors.deepPurpleAccent],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Debt', style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  '₹${loans.fold(0.0, (sum, item) => sum + item.amount).toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        Expanded(
          child: loans.isEmpty
              ? Center(
                  child: Text(
                    isActive ? 'You have no active loans! 🎉' : 'No loan history yet.',
                    style: const TextStyle(color: AppTheme.textGrey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: loans.length,
                  itemBuilder: (context, index) {
                    final loan = loans[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.purpleAccent.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(LucideIcons.landmark, color: isActive ? Colors.purpleAccent : Colors.grey),
                        ),
                        title: Text(
                          loan.name, 
                          style: TextStyle(
                            color: isActive 
                                ? Theme.of(context).textTheme.bodyLarge?.color 
                                : AppTheme.textGrey, 
                            fontWeight: FontWeight.bold,
                            decoration: isActive ? null : TextDecoration.lineThrough,
                          )
                        ),
                        subtitle: Text(
                          isActive 
                              ? DateFormat('MMM dd, yyyy').format(loan.date)
                              : 'Cleared on ${DateFormat('MMM dd, yyyy').format(loan.clearedDate ?? loan.date)}',
                          style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹${loan.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: isActive ? Colors.redAccent : AppTheme.textGrey, 
                                fontWeight: FontWeight.bold,
                                decoration: isActive ? null : TextDecoration.lineThrough,
                              ),
                            ),
                            if (isActive) ...[
                              const SizedBox(width: 8),
                              Checkbox(
                                value: false,
                                activeColor: AppTheme.accentGreen,
                                side: const BorderSide(color: AppTheme.textGrey),
                                onChanged: (val) async {
                                  if (val == true) {
                                    final txProvider = context.read<TransactionProvider>();
                                    final audit = context.read<AuditLogProvider>();
                                    audit.logAction('Tap', 'Initiated loan repayment for: ${loan.name}');
                                    await txProvider.clearLoan(loan.id, audit);
                                    
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Loan cleared successfully!'),
                                          backgroundColor: AppTheme.accentGreen,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                            if (!isActive) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.check_circle, color: AppTheme.accentGreen),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showLoanSheet(BuildContext context) {
    final amountCtrl = TextEditingController();
    final providerCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4, height: 24,
                  decoration: BoxDecoration(color: Colors.purpleAccent, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 12),
                Text('Receive Loan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: providerCtrl,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: 'Loan provider (e.g. Bank)',
                hintStyle: TextStyle(color: AppTheme.textGrey.withValues(alpha: 0.5)),
                filled: true, fillColor: Theme.of(context).scaffoldBackgroundColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: 'Loan amount (₹)',
                hintStyle: TextStyle(color: AppTheme.textGrey.withValues(alpha: 0.5)),
                filled: true, fillColor: Theme.of(context).scaffoldBackgroundColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
                  if (amount <= 0) return;
                  
                  final wallet = context.read<WalletProvider>();
                  final tx = context.read<TransactionProvider>();
                  final audit = context.read<AuditLogProvider>();
                  
                  try {
                    await wallet.receiveLoan(
                      amount: amount,
                      provider: providerCtrl.text.trim().isEmpty ? 'Bank' : providerCtrl.text.trim(),
                      audit: audit,
                    );
                    audit.logAction('Tap', 'Confirmed loan of ₹$amount from ${providerCtrl.text.trim().isEmpty ? "Bank" : providerCtrl.text.trim()}');
                    await tx.refresh();
                    wallet.calculateStats(tx.transactions);
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to add loan: $e'), backgroundColor: Colors.redAccent),
                      );
                    }
                    return;
                  }

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Loan added successfully'), backgroundColor: AppTheme.accentGreen),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Confirm Loan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
