import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/audit_log_provider.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';

class PayBillScreen extends StatefulWidget {
  const PayBillScreen({super.key});

  @override
  State<PayBillScreen> createState() => _PayBillScreenState();
}

class _PayBillScreenState extends State<PayBillScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _customBillerController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  int _selectedBillerIndex = 0;

  final List<Map<String, dynamic>> _billers = [
    {'name': 'Electricity', 'icon': Icons.bolt, 'category': TransactionCategory.utilities},
    {'name': 'Water', 'icon': Icons.water_drop, 'category': TransactionCategory.utilities},
    {'name': 'Internet', 'icon': Icons.wifi, 'category': TransactionCategory.utilities},
    {'name': 'Gas', 'icon': Icons.local_fire_department, 'category': TransactionCategory.utilities},
    {'name': 'Insurance', 'icon': Icons.shield, 'category': TransactionCategory.other},
    {'name': 'Rent', 'icon': Icons.home, 'category': TransactionCategory.other},
    {'name': 'Custom', 'icon': Icons.edit_note, 'category': TransactionCategory.other},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _customBillerController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountController.text.trim());
    final biller = _billers[_selectedBillerIndex];
    final billerName = biller['name'] == 'Custom' 
        ? _customBillerController.text.trim() 
        : biller['name'] as String;

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final walletProvider = context.read<WalletProvider>();
    final txProvider = context.read<TransactionProvider>();
    final audit = context.read<AuditLogProvider>();
    try {
      await walletProvider.payBill(
            billerName: billerName,
            amount: amount,
            note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
            audit: audit,
          );
      await txProvider.refresh();
      walletProvider.calculateStats(txProvider.transactions);
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text('$billerName bill of ₹${amount.toStringAsFixed(2)} paid!'),
          backgroundColor: AppTheme.accentGreen,
          behavior: SnackBarBehavior.floating,
        ));
        nav.pop();
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: const Text('Pay Bill', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Biller', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _billers.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, childAspectRatio: 1, crossAxisSpacing: 12, mainAxisSpacing: 12,
                ),
                itemBuilder: (context, i) {
                  final isSelected = _selectedBillerIndex == i;
                  return GestureDetector(
                    onTap: () {
                      context.read<AuditLogProvider>().logAction('Tap', 'Selected biller: ${_billers[i]['name']}');
                      setState(() => _selectedBillerIndex = i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.accentOrange.withValues(alpha: 0.2) : AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppTheme.accentOrange : Colors.transparent, width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_billers[i]['icon'] as IconData,
                              color: isSelected ? AppTheme.accentOrange : AppTheme.textGrey, size: 28),
                          const SizedBox(height: 8),
                          Text(_billers[i]['name'] as String,
                              style: TextStyle(
                                  fontSize: 11, color: isSelected ? Colors.white : AppTheme.textGrey)),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (_billers[_selectedBillerIndex]['name'] == 'Custom') ...[
                const SizedBox(height: 24),
                const Text('Bill Name', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _customBillerController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter bill name (e.g. Gym)',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    filled: true, fillColor: AppTheme.cardDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter bill name' : null,
                ),
              ],
              const SizedBox(height: 24),
              const Text('Amount', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  hintText: '0.00',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 28),
                  filled: true, fillColor: AppTheme.cardDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Enter a valid amount';
                  if (n > context.read<WalletProvider>().balance) return 'Insufficient balance';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text('Reference / Note', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Account number or note',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  filled: true, fillColor: AppTheme.cardDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () {
                    context.read<AuditLogProvider>().logAction('Tap', 'Initiated "Pay Now" for ${_billers[_selectedBillerIndex]['name']} bill (₹${_amountController.text})');
                    _submit();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentYellow, foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('Pay Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
