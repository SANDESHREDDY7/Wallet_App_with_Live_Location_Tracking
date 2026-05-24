import '../models/transaction.dart';
import '../repositories/local_db.dart';
import 'auth_service.dart';

/// Business logic for creating, reading, and categorising transactions.
class TransactionService {
  TransactionService._();
  static final TransactionService instance = TransactionService._();

  final _db = LocalDb.instance;
  final _auth = AuthService.instance;

  String _getUserEmail() {
    final email = _auth.currentUser?.email;
    if (email == null) throw StateError('User must be authenticated to perform transaction operations');
    return email;
  }

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  Future<List<WalletTransaction>> getTransactions() => _db.getAllTransactions();

  Future<List<WalletTransaction>> getRecentTransactions({int limit = 5}) async {
    final all = await _db.getAllTransactions();
    return all.take(limit).toList();
  }

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Record a money transfer (debit) to a contact.
  Future<WalletTransaction> sendMoney({
    required String contactName,
    required double amount,
    String? note,
  }) async {
    final tx = WalletTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      userId: _getUserEmail(),
      name: contactName,
      amount: amount,
      type: TransactionType.debit,
      category: TransactionCategory.transfer,
      date: DateTime.now(),
      note: note,
    );
    await _db.insertTransaction(tx);
    return tx;
  }

  /// Record a top-up (credit) transaction.
  Future<WalletTransaction> addMoney({
    required double amount,
    String source = 'Top Up',
  }) async {
    final tx = WalletTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      userId: _getUserEmail(),
      name: source,
      amount: amount,
      type: TransactionType.credit,
      category: TransactionCategory.transfer,
      date: DateTime.now(),
    );
    await _db.insertTransaction(tx);
    return tx;
  }

  /// Record a bill payment (debit).
  Future<WalletTransaction> payBill({
    required String billerName,
    required double amount,
    TransactionCategory category = TransactionCategory.utilities,
    String? note,
  }) async {
    final tx = WalletTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      userId: _getUserEmail(),
      name: billerName,
      amount: amount,
      type: TransactionType.debit,
      category: category,
      date: DateTime.now(),
      note: note,
    );
    await _db.insertTransaction(tx);
    return tx;
  }

  /// Record a recharge (debit).
  Future<WalletTransaction> recharge({
    required String operator,
    required double amount,
    String? phone,
  }) async {
    final tx = WalletTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      userId: _getUserEmail(),
      name: 'Recharge — $operator',
      amount: amount,
      type: TransactionType.debit,
      category: TransactionCategory.recharge,
      date: DateTime.now(),
      note: phone != null ? 'Phone: $phone' : null,
    );
    await _db.insertTransaction(tx);
    return tx;
  }

  /// Record a charity donation (debit).
  Future<WalletTransaction> donate({
    required String cause,
    required double amount,
  }) async {
    final tx = WalletTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      userId: _getUserEmail(),
      name: cause,
      amount: amount,
      type: TransactionType.debit,
      category: TransactionCategory.charity,
      date: DateTime.now(),
    );
    await _db.insertTransaction(tx);
    return tx;
  }

  /// Record a bank-to-bank transfer.
  Future<WalletTransaction> bankTransfer({
    required String bankName,
    required double amount,
    String? note,
  }) async {
    final tx = WalletTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      userId: _getUserEmail(),
      name: 'Bank Transfer — $bankName',
      amount: amount,
      type: TransactionType.debit,
      category: TransactionCategory.bankTransfer,
      date: DateTime.now(),
      note: note,
    );
    await _db.insertTransaction(tx);
    return tx;
  }

  /// Record a loan disbursement (credit).
  Future<WalletTransaction> receiveLoan({
    required double amount,
    required String provider,
  }) async {
    final tx = WalletTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      userId: _getUserEmail(),
      name: 'Loan — $provider',
      amount: amount,
      type: TransactionType.credit,
      category: TransactionCategory.loan,
      date: DateTime.now(),
    );
    await _db.insertTransaction(tx);
    return tx;
  }

  Future<void> clearLoan(String id) async {
    final all = await _db.getAllTransactions();
    final index = all.indexWhere((t) => t.id == id);
    if (index >= 0) {
      final updated = all[index].copyWith(isCleared: true, clearedDate: DateTime.now());
      await _db.insertTransaction(updated);
    }
  }

  Future<void> deleteTransaction(String id) => _db.deleteTransaction(id);
}
