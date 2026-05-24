import '../models/expense_data.dart';
import '../models/income_stats.dart';
import '../repositories/preferences_repository.dart';
import 'auth_service.dart';

/// Business logic for wallet balance and financial stats.
class WalletService {
  WalletService._();
  static final WalletService instance = WalletService._();

  final _prefs = PreferencesRepository.instance;
  final _auth = AuthService.instance;

  String _getUserEmail() {
    final email = _auth.currentUser?.email;
    if (email == null) throw StateError('User must be authenticated to perform wallet operations');
    return email;
  }

  // ---------------------------------------------------------------------------
  // Balance
  // ---------------------------------------------------------------------------

  Future<double> getBalance() => _prefs.getBalance(_getUserEmail());

  /// Add money to the wallet. Returns the new balance.
  Future<double> addMoney(double amount) async {
    if (amount <= 0) throw ArgumentError('Amount must be positive');
    final email = _getUserEmail();
    final current = await _prefs.getBalance(email);
    final newBalance = current + amount;
    await _prefs.setBalance(email, newBalance);
    return newBalance;
  }

  /// Deduct money from the wallet. Returns the new balance.
  Future<double> deductMoney(double amount) async {
    if (amount <= 0) throw ArgumentError('Amount must be positive');
    final email = _getUserEmail();
    final current = await _prefs.getBalance(email);
    if (current < amount) throw StateError('Insufficient funds');
    final newBalance = current - amount;
    await _prefs.setBalance(email, newBalance);
    return newBalance;
  }

  // ---------------------------------------------------------------------------
  // Stats
  // ---------------------------------------------------------------------------

  /// Returns mock income stats. In production, call a real API here.
  Future<IncomeStats> getIncomeStats() async {
    return const IncomeStats(
      annualIncome: 0.0,
      growthPercent: 0.0,
      weeklyTotal: 0.0,
    );
  }

  /// Returns weekly expense bar-chart data calculated from current week.
  Future<List<ExpenseData>> getWeeklyExpenses() async {
    return const [
      ExpenseData(day: 'Sun', amount: 0),
      ExpenseData(day: 'Mon', amount: 0),
      ExpenseData(day: 'Tue', amount: 0),
      ExpenseData(day: 'Wed', amount: 0),
      ExpenseData(day: 'Thu', amount: 0),
      ExpenseData(day: 'Fri', amount: 0),
      ExpenseData(day: 'Sat', amount: 0),
    ];
  }
}
