import 'dart:convert';

class BillReminder {
  final String id;
  final String billerName;
  final double amount;
  final DateTime dueDate;
  final bool isPaid;

  BillReminder({
    required this.id,
    required this.billerName,
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
  });

  BillReminder copyWith({
    String? id,
    String? billerName,
    double? amount,
    DateTime? dueDate,
    bool? isPaid,
  }) {
    return BillReminder(
      id: id ?? this.id,
      billerName: billerName ?? this.billerName,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'billerName': billerName,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'isPaid': isPaid,
    };
  }

  factory BillReminder.fromMap(Map<String, dynamic> map) {
    return BillReminder(
      id: map['id'],
      billerName: map['billerName'],
      amount: map['amount'],
      dueDate: DateTime.parse(map['dueDate']),
      isPaid: map['isPaid'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory BillReminder.fromJson(String source) => BillReminder.fromMap(json.decode(source));
}
