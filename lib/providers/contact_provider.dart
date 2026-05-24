import 'package:flutter/foundation.dart';
import '../models/contact.dart';
import '../services/contact_service.dart';

class ContactProvider extends ChangeNotifier {
  final _service = ContactService.instance;

  List<Contact> _contacts = [];
  bool _isLoading = false;

  List<Contact> get contacts => List.unmodifiable(_contacts);
  bool get isLoading => _isLoading;

  Future<void> fetchContacts() async {
    _isLoading = true;
    Future.microtask(() => notifyListeners());
    try {
      _contacts = await _service.getContacts();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addContact({
    required String name,
    String avatarUrl = '',
    String? phone,
    String? email,
  }) async {
    final c = await _service.createContact(
        name: name, avatarUrl: avatarUrl, phone: phone, email: email);
    _contacts = [..._contacts, c];
    notifyListeners();
  }

  Future<void> removeContact(String id) async {
    await _service.removeContact(id);
    _contacts = _contacts.where((c) => c.id != id).toList();
    notifyListeners();
  }
}
