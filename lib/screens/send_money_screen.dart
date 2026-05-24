import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/contact.dart' as model;
import '../providers/wallet_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/audit_log_provider.dart';
import '../theme/app_theme.dart';

class SendMoneyScreen extends StatefulWidget {
  final model.Contact? preselectedContact;

  const SendMoneyScreen({super.key, this.preselectedContact});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  List<Contact> _deviceContacts = [];
  bool _isLoading = false;
  bool _isFetchingContacts = false;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedContact != null) {
      _nameController.text = widget.preselectedContact!.name;
    }
    _checkPermissionAndFetch();
  }

  Future<void> _checkPermissionAndFetch() async {
    setState(() => _isFetchingContacts = true);
    final status = await Permission.contacts.request();
    if (status.isGranted) {
      setState(() => _hasPermission = true);
      try {
        final contacts = await FlutterContacts.getAll(
          properties: {ContactProperty.name, ContactProperty.phone},
        );
        if (mounted) {
          setState(() {
            _deviceContacts = contacts;
            _isFetchingContacts = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isFetchingContacts = false);
      }
    } else {
      if (mounted) setState(() => _isFetchingContacts = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a recipient name'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final amount = double.parse(_amountController.text.trim());
    setState(() => _isLoading = true);
    try {
      final walletProvider = context.read<WalletProvider>();
      final txProvider = context.read<TransactionProvider>();
      final audit = context.read<AuditLogProvider>();
      
      await walletProvider.sendMoney(
        contactName: name,
        amount: amount,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        audit: audit,
      );
      
      await txProvider.refresh();
      walletProvider.calculateStats(txProvider.transactions);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('₹${amount.toStringAsFixed(2)} successfully sent to $name'),
            backgroundColor: AppTheme.accentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send money: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
        title: const Text('Send Money',
            style: TextStyle(fontWeight: FontWeight.bold)),
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
              // Recipient Name with Autocomplete
              const Text('To', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
              const SizedBox(height: 8),
              Autocomplete<Contact>(
                displayStringForOption: (Contact option) => option.displayName ?? '',
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<Contact>.empty();
                  }
                  return _deviceContacts.where((Contact option) {
                    return (option.displayName ?? '')
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (Contact selection) {
                  context.read<AuditLogProvider>().logAction('Tap', 'Selected contact from search: ${selection.displayName ?? "Unknown"}');
                  _nameController.text = selection.displayName ?? '';
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  // Keep _nameController in sync with Autocomplete's internal controller
                  if (controller.text.isEmpty && _nameController.text.isNotEmpty) {
                    controller.text = _nameController.text;
                  }
                  controller.addListener(() {
                    if (_nameController.text != controller.text) {
                      _nameController.text = controller.text;
                    }
                  });
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter name or search contacts',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      filled: true,
                      fillColor: AppTheme.cardDark,
                      prefixIcon: const Icon(Icons.person_search, color: AppTheme.textGrey),
                      suffixIcon: _isFetchingContacts 
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentOrange)),
                            )
                          : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none),
                    ),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      color: AppTheme.cardDark,
                      elevation: 8,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: MediaQuery.of(context).size.width - 48,
                        constraints: const BoxConstraints(maxHeight: 250),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          separatorBuilder: (context, index) => Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                          itemBuilder: (BuildContext context, int index) {
                            final Contact option = options.elementAt(index);
                            final displayName = option.displayName ?? 'Unknown';
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.2),
                                child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?', style: const TextStyle(color: AppTheme.accentOrange)),
                              ),
                              title: Text(displayName,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  option.phones.isNotEmpty ? option.phones.first.number : 'No number',
                                  style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (!_hasPermission && !_isFetchingContacts)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Enable contact permission for better search.',
                        style: TextStyle(color: Colors.orangeAccent.withValues(alpha: 0.7), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),

              // Amount Section
              const Text('Amount to Send', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  hintText: '0.00',
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.1), fontSize: 42),
                  filled: true,
                  fillColor: AppTheme.cardDark,
                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none),
                ),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Please enter a valid amount';
                  final balance = context.read<WalletProvider>().balance;
                  if (n > balance) return 'Insufficient balance (Current: ₹${balance.toStringAsFixed(2)})';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Note
              const Text('Add a Note',
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Optional: Gift, Rent, Dinner...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                  filled: true,
                  fillColor: AppTheme.cardDark,
                  prefixIcon: const Icon(Icons.note_add_outlined, color: AppTheme.textGrey),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () {
                    context.read<AuditLogProvider>().logAction('Tap', 'Initiated "Send Money Now" for amount: ${_amountController.text}');
                    _submit();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                              strokeWidth: 3, color: Colors.white),
                        )
                      : const Text('Send Money Now',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
