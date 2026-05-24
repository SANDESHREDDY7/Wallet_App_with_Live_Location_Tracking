enum TransactionType { credit, debit }

enum TransactionCategory {
  entertainment,
  shopping,
  transfer,
  food,
  utilities,
  loan,
  recharge,
  charity,
  bankTransfer,
  other,
}

extension TransactionCategoryX on TransactionCategory {
  String get label {
    switch (this) {
      case TransactionCategory.entertainment:
        return 'Entertainment';
      case TransactionCategory.shopping:
        return 'Shopping';
      case TransactionCategory.transfer:
        return 'Transfer';
      case TransactionCategory.food:
        return 'Food';
      case TransactionCategory.utilities:
        return 'Utilities';
      case TransactionCategory.loan:
        return 'Loan';
      case TransactionCategory.recharge:
        return 'Recharge';
      case TransactionCategory.charity:
        return 'Charity';
      case TransactionCategory.bankTransfer:
        return 'Bank Transfer';
      case TransactionCategory.other:
        return 'Other';
    }
  }

  String get iconKey {
    switch (this) {
      case TransactionCategory.entertainment:
        return 'music';
      case TransactionCategory.shopping:
        return 'shopping_cart';
      case TransactionCategory.transfer:
        return 'send';
      case TransactionCategory.food:
        return 'utensils';
      case TransactionCategory.utilities:
        return 'zap';
      case TransactionCategory.loan:
        return 'wallet';
      case TransactionCategory.recharge:
        return 'smartphone';
      case TransactionCategory.charity:
        return 'heart';
      case TransactionCategory.bankTransfer:
        return 'landmark';
      case TransactionCategory.other:
        return 'circle';
    }
  }
}

class WalletTransaction {
  final String id;
  final String userId;
  final String name;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final DateTime date;
  final String? note;
  final bool isCleared;
  final DateTime? clearedDate;

  const WalletTransaction({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.note,
    this.isCleared = false,
    this.clearedDate,
  });

  bool get isCredit => type == TransactionType.credit;

  String get formattedAmount =>
      '${isCredit ? '+' : '-'}₹${amount.toStringAsFixed(2)}';

  WalletTransaction copyWith({
    String? id,
    String? userId,
    String? name,
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
    DateTime? date,
    String? note,
    bool? isCleared,
    DateTime? clearedDate,
  }) {
    return WalletTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      isCleared: isCleared ?? this.isCleared,
      clearedDate: clearedDate ?? this.clearedDate,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'name': name,
        'amount': amount,
        'type': type.index,
        'category': category.index,
        'date': date.toIso8601String(),
        'note': note,
        'isCleared': isCleared ? 1 : 0,
        'clearedDate': clearedDate?.toIso8601String(),
      };

  factory WalletTransaction.fromMap(Map<String, dynamic> map) =>
      WalletTransaction(
        id: map['id'] as String,
        userId: map['userId'] as String? ?? 'demo',
        name: map['name'] as String,
        amount: (map['amount'] as num).toDouble(),
        type: TransactionType.values[map['type'] as int],
        category: TransactionCategory.values[map['category'] as int],
        date: DateTime.parse(map['date'] as String),
        note: map['note'] as String?,
        isCleared: map.containsKey('isCleared') ? (map['isCleared'] == 1) : false,
        clearedDate: map['clearedDate'] != null ? DateTime.parse(map['clearedDate'] as String) : null,
      );
}
