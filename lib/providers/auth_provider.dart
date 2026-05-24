import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _service = AuthService.instance;

  User? _user;
  bool _isLoading = false;

  User? get currentUser => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  Future<void> load() async {
    _isLoading = true;
    Future.microtask(() => notifyListeners());
    try {
      _user = await _service.getCurrentUser();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUser(User user) async {
    _user = user;
    await _service.updateCachedUser(user);
    notifyListeners();
  }

  Future<void> login(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _service.login(name, email, password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signup(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _service.register(name, email, password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _service.logout();
    _user = null;
    notifyListeners();
  }
}
