import '../models/contact.dart';
import '../repositories/local_db.dart';
import 'auth_service.dart';

/// Business logic for managing quick-transfer contacts.
class ContactService {
  ContactService._();
  static final ContactService instance = ContactService._();

  final _db = LocalDb.instance;
  final _auth = AuthService.instance;

  String _getUserEmail() {
    final email = _auth.currentUser?.email;
    if (email == null) throw StateError('User must be authenticated to perform contact operations');
    return email;
  }

  Future<List<Contact>> getContacts() => _db.getAllContacts();

  Future<void> addContact(Contact contact) => _db.insertContact(contact);

  Future<void> removeContact(String id) => _db.deleteContact(id);

  /// Create a new contact with a generated id.
  Future<Contact> createContact({
    required String name,
    String avatarUrl = '',
    String? phone,
    String? email,
  }) async {
    final c = Contact(
      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
      userId: _getUserEmail(),
      name: name,
      avatarUrl: avatarUrl,
      phone: phone,
      email: email,
    );
    await _db.insertContact(c);
    return c;
  }
}
