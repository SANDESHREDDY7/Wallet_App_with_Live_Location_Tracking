class ExpenseData {
  final String day;
  final double amount;

  const ExpenseData({required this.day, required this.amount});

  Map<String, dynamic> toMap() => {'day': day, 'amount': amount};

  factory ExpenseData.fromMap(Map<String, dynamic> m) =>
      ExpenseData(day: m['day'] as String, amount: (m['amount'] as num).toDouble());
}
