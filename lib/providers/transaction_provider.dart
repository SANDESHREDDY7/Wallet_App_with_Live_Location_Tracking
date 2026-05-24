import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import 'audit_log_provider.dart';

class TransactionProvider extends ChangeNotifier {
  final _service = TransactionService.instance;

  List<WalletTransaction> _transactions = [];
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;

  List<WalletTransaction> get transactions => List.unmodifiable(_transactions);
  
  List<WalletTransaction> get filteredTransactions {
    if (_searchQuery.isEmpty) return transactions;
    return _transactions.where((t) {
      return t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             (t.note?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchTransactions() async {
    _isLoading = true;
    _error = null;
    Future.microtask(() => notifyListeners());
    try {
      _transactions = await _service.getTransactions();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Call after a new transaction is recorded to refresh the list.
  Future<void> refresh() => fetchTransactions();

  Future<void> clearLoan(String id, AuditLogProvider audit) async {
    await _service.clearLoan(id);
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index >= 0) {
      final tx = _transactions[index];
      _transactions[index] = tx.copyWith(isCleared: true, clearedDate: DateTime.now());
      audit.logAction('Loan', 'Marked a loan of ₹${tx.amount} from ${tx.name} as paid');
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String id, AuditLogProvider audit) async {
    await _service.deleteTransaction(id);
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index >= 0) {
      final tx = _transactions[index];
      _transactions.removeAt(index);
      audit.logAction('Transaction', 'Deleted a past transaction: ${tx.name} (₹${tx.amount})');
      notifyListeners();
    }
  }

  void clear() {
    _transactions = [];
    notifyListeners();
  }
}
