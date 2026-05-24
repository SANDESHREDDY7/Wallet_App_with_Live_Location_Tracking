import 'package:flutter/foundation.dart';
import '../models/expense_data.dart';
import '../models/income_stats.dart';
import '../models/transaction.dart';
import '../services/wallet_service.dart';
import '../services/transaction_service.dart';
import '../repositories/preferences_repository.dart';
import '../services/auth_service.dart';
import 'audit_log_provider.dart';

/// Central state for balance, income stats, and weekly expenses.
class WalletProvider extends ChangeNotifier {
  final _walletService = WalletService.instance;
  final _txService = TransactionService.instance;
  final _prefs = PreferencesRepository.instance;

  double _balance = 0;
  IncomeStats? _incomeStats;
  List<ExpenseData> _weeklyExpenses = [];
  bool _isLoading = false;
  String? _error;

  double get balance => _balance;
  IncomeStats? get incomeStats => _incomeStats;
  List<ExpenseData> get weeklyExpenses => _weeklyExpenses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get formattedBalance =>
      '₹${_balance.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    Future.microtask(() => notifyListeners());
    try {
      _balance = await _walletService.getBalance();
      _incomeStats = await _walletService.getIncomeStats();
      _weeklyExpenses = await _walletService.getWeeklyExpenses();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add money — updates balance and records a credit transaction.
  Future<void> addMoney({required double amount, required AuditLogProvider audit}) async {
    try {
      _balance = await _walletService.addMoney(amount);
      await _txService.addMoney(amount: amount);
      audit.logAction('Wallet', 'Topped up wallet balance by ₹$amount');
      _syncUserBalance();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Send money — deducts balance and records a debit transaction.
  Future<void> sendMoney({
    required String contactName,
    required double amount,
    required AuditLogProvider audit,
    String? note,
  }) async {
    try {
      _balance = await _walletService.deductMoney(amount);
      await _txService.sendMoney(
          contactName: contactName, amount: amount, note: note);
      audit.logAction('Wallet', 'Sent ₹$amount to $contactName${note != null ? " ($note)" : ""}');
      _syncUserBalance();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Pay a bill — deducts balance and records a debit transaction.
  Future<void> payBill({
    required String billerName,
    required double amount,
    required AuditLogProvider audit,
    String? note,
  }) async {
    try {
      _balance = await _walletService.deductMoney(amount);
      await _txService.payBill(billerName: billerName, amount: amount, note: note);
      audit.logAction('Wallet', 'Paid $billerName bill of ₹$amount');
      _syncUserBalance();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Recharge — deducts balance.
  Future<void> recharge({
    required String operator,
    required double amount,
    required AuditLogProvider audit,
    String? phone,
  }) async {
    try {
      _balance = await _walletService.deductMoney(amount);
      await _txService.recharge(
          operator: operator, amount: amount, phone: phone);
      audit.logAction('Wallet', 'Recharged $operator mobile ($phone) with ₹$amount');
      _syncUserBalance();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Charity donation — deducts balance.
  Future<void> donate({
    required String cause, 
    required double amount, 
    required AuditLogProvider audit
  }) async {
    try {
      _balance = await _walletService.deductMoney(amount);
      await _txService.donate(cause: cause, amount: amount);
      audit.logAction('Wallet', 'Donated ₹$amount to $cause');
      _syncUserBalance();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Bank transfer — deducts balance.
  Future<void> bankTransfer({
    required String bankName,
    required double amount,
    required AuditLogProvider audit,
    String? note,
  }) async {
    try {
      _balance = await _walletService.deductMoney(amount);
      await _txService.bankTransfer(
          bankName: bankName, amount: amount, note: note);
      audit.logAction('Wallet', 'Transferred ₹$amount to bank account: $bankName');
      _syncUserBalance();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Receive loan credit.
  Future<void> receiveLoan({
    required double amount, 
    required String provider, 
    required AuditLogProvider audit
  }) async {
    try {
      _balance = await _walletService.addMoney(amount);
      await _txService.receiveLoan(amount: amount, provider: provider);
      audit.logAction('Loan', 'Received loan of ₹$amount from $provider');
      _syncUserBalance();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _syncUserBalance() {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      _prefs.setBalance(user.email, _balance);
    }
  }

  void calculateStats(List<WalletTransaction> transactions) {
    // 1. Weekly Expenses (Last 7 days)
    final now = DateTime.now();
    final Map<String, double> dailyExpenses = {
      'Sun': 0, 'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0
    };
    
    double weeklyTotal = 0;
    final last7Days = now.subtract(const Duration(days: 7));

    for (final tx in transactions) {
      if (tx.date.isAfter(last7Days)) {
        if (tx.type == TransactionType.debit) {
          final dayName = _getDayName(tx.date);
          dailyExpenses[dayName] = (dailyExpenses[dayName] ?? 0) + tx.amount;
          weeklyTotal += tx.amount;
        }
      }
    }

    _weeklyExpenses = dailyExpenses.entries
        .map((e) => ExpenseData(day: e.key, amount: e.value))
        .toList();

    // 2. Income Stats
    double totalIncome = 0;
    for (final tx in transactions) {
      if (tx.type == TransactionType.credit) {
        totalIncome += tx.amount;
      }
    }

    double growthPercent = 0.0;
    if (totalIncome > 0) {
      growthPercent = double.parse(((weeklyTotal / totalIncome) * 100).toStringAsFixed(1));
    }

    _incomeStats = IncomeStats(
      annualIncome: totalIncome,
      growthPercent: growthPercent,
      weeklyTotal: weeklyTotal,
    );

    notifyListeners();
  }

  String _getDayName(DateTime date) {
    switch (date.weekday) {
      case 7: return 'Sun';
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      default: return '';
    }
  }
}
