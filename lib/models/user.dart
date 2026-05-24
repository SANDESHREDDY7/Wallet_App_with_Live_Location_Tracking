class User {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final double balance;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.balance,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    double? balance,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      balance: balance ?? this.balance,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
        'balance': balance,
      };

  factory User.fromMap(Map<String, dynamic> map) => User(
        id: map['id'] as String,
        name: map['name'] as String,
        email: map['email'] as String,
        avatarUrl: map['avatarUrl'] as String,
        balance: (map['balance'] as num).toDouble(),
      );

  /// Demo user used as the default logged-in account.
  static const User demo = User(
    id: 'user_001',
    name: 'James John',
    email: 'james@example.com',
    avatarUrl: '',
    balance: 0.0,
  );
}
