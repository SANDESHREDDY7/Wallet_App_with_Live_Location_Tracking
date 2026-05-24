class Contact {
  final String id;
  final String userId;
  final String name;
  final String avatarUrl;
  final String? phone;
  final String? email;

  const Contact({
    required this.id,
    required this.userId,
    required this.name,
    required this.avatarUrl,
    this.phone,
    this.email,
  });

  Contact copyWith({
    String? id,
    String? userId,
    String? name,
    String? avatarUrl,
    String? phone,
    String? email,
  }) {
    return Contact(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'name': name,
        'avatarUrl': avatarUrl,
        'phone': phone,
        'email': email,
      };

  factory Contact.fromMap(Map<String, dynamic> map) => Contact(
        id: map['id'] as String,
        userId: map['userId'] as String? ?? 'demo',
        name: map['name'] as String,
        avatarUrl: map['avatarUrl'] as String,
        phone: map['phone'] as String?,
        email: map['email'] as String?,
      );

  /// Default seed contacts (removed as per user request)
  static List<Contact> seeds = [];
}
