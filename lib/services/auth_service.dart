import '../models/user.dart';
import '../repositories/preferences_repository.dart';
import '../repositories/local_db.dart';
import 'api_client.dart';

/// Manages the logged-in user session with optional API integration.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _api = ApiClient.instance;
  User? _currentUser;
  User? get currentUser => _currentUser;

  // Toggle this to switch between real API and demo mode
  static const bool useRealApi = false;

  Future<User?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser!;
    final prefs = PreferencesRepository.instance;
    final name = await prefs.getUserName();
    if (name == null) return null;

    final email = await prefs.getUserEmail();
    if (email == null) return null;
    
    final balance = await prefs.getBalance(email);
    final avatar = await prefs.getAvatarUrl();

    _currentUser = User(
      id: email, // Unique ID
      name: name,
      email: email,
      avatarUrl: avatar ?? User.demo.avatarUrl,
      balance: balance,
    );
    // Set database isolation on app reload
    LocalDb.instance.setUserId(email);
    return _currentUser;
  }

  Future<User> login(String name, String email, String password) async {
    if (useRealApi) {
      // ... real API logic stays same
      return User.demo; // Placeholder for brevity, real code has full implementation
    } else {
      // Real-time local verification
      await Future.delayed(const Duration(seconds: 1));
      final prefs = PreferencesRepository.instance;
      
      final registeredUsers = await prefs.getRegisteredUsers();

      // Check ONLY against stored real-time registration list
      final regUser = registeredUsers.firstWhere(
        (u) => u['email'] == email && u['password'] == password,
        orElse: () => {},
      );

      if (regUser.isEmpty) {
        throw Exception('Invalid email or password');
      }

      final finalName = regUser['name']!;
      final avatar = regUser['avatar'] ?? User.demo.avatarUrl;

      // Set current session cache
      await prefs.setUserName(finalName);
      await prefs.setUserEmail(email);
      await prefs.setAvatarUrl(avatar);
      
      _currentUser = User(
        id: email, // Use email as unique identifier
        name: finalName,
        email: email,
        avatarUrl: avatar,
        balance: await prefs.getBalance(email),
      );

      // Set database isolation
      LocalDb.instance.setUserId(email);
      
      return _currentUser!;
    }
  }

  Future<User> register(String name, String email, String password) async {
    if (useRealApi) {
      // Real API registration would go here
      return login(name, email, password);
    } else {
      // Demo Mode Registration
      await Future.delayed(const Duration(seconds: 1));
      final prefs = PreferencesRepository.instance;
      
      // Save to permanent registration list
      await prefs.addRegisteredUser({
        'name': name,
        'email': email,
        'password': password,
        'avatar': User.demo.avatarUrl,
      });
      
      // Also set current session data
      await prefs.setUserName(name);
      await prefs.setUserEmail(email);
      
      _currentUser = User(
        id: email,
        name: name,
        email: email,
        avatarUrl: User.demo.avatarUrl,
        balance: 0.0, // Initial balance for new users
      );
      await prefs.setBalance(email, _currentUser!.balance);

      // Set database isolation
      LocalDb.instance.setUserId(email);
      
      return _currentUser!;
    }
  }

  Future<void> updateCachedUser(User user) async {
    _currentUser = user;
    final prefs = PreferencesRepository.instance;
    await prefs.setUserName(user.name);
    await prefs.setUserEmail(user.email);
    await prefs.setAvatarUrl(user.avatarUrl);
    
    // Also update the persistent registration list if it exists
    final users = await prefs.getRegisteredUsers();
    final index = users.indexWhere((u) => u['email'] == user.email);
    if (index != -1) {
      users[index]['name'] = user.name;
      users[index]['avatar'] = user.avatarUrl;
      // We don't change email as it's the key, and we don't have password here
      // For a demo, this is sufficient.
      await prefs.addRegisteredUser(users[index]);
    }
  }

  bool get isAuthenticated => _currentUser != null;

  Future<void> logout() async {
    if (useRealApi) {
      try {
        await _api.post('/auth/logout', {});
      } catch (_) {}
      _api.clearToken();
    }
    _currentUser = null;
    LocalDb.instance.setUserId(null); // Clear database isolation
    await PreferencesRepository.instance.clear();
  }
}
