import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart';
import '../models/contact.dart';

// Conditionally import the web factory only on web

class LocalDb {
  LocalDb._();
  static final LocalDb instance = LocalDb._();

  Database? _db;
  bool _isWebStorage = false;
  Completer<void>? _initCompleter;
  
  // Current user isolation
  String? _userId;
  void setUserId(String? id) => _userId = id;
  String get _currentUserId => _userId ?? 'demo';

  // Web storage cache
  List<WalletTransaction> _webTransactions = [];
  List<Contact> _webContacts = [];

  Future<void> init() async {
    if (_db != null || _isWebStorage) return;
    if (_initCompleter != null) return _initCompleter!.future;

    _initCompleter = Completer<void>();

    try {
      if (kIsWeb) {
        // For web, use SharedPreferences as a reliable persistent "database"
        // This avoids WASM/Worker issues while maintaining persistence.
        _isWebStorage = true;
        await _loadWebStorage();
        _initCompleter!.complete();
        return;
      }

      // Native SQLite path
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'wallet.db');
      
      _db = await openDatabase(
        path, 
        version: 4, 
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ).timeout(const Duration(seconds: 5));
      
      _initCompleter!.complete();
    } catch (e) {
      // Fallback for any other environment issues
      _isWebStorage = true;
      _seedDemoData();
      _initCompleter!.complete();
    }
  }

  Future<void> _loadWebStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    final txJson = prefs.getString('web_db_transactions');
    if (txJson != null) {
      final List decoded = jsonDecode(txJson);
      _webTransactions = decoded.map((e) => WalletTransaction.fromMap(e)).toList();
    } else {
      _seedDemoData();
    }

    final contactJson = prefs.getString('web_db_contacts');
    if (contactJson != null) {
      final List decoded = jsonDecode(contactJson);
      _webContacts = decoded.map((e) => Contact.fromMap(e)).toList();
    } else if (txJson == null) {
      _webContacts = List.from(Contact.seeds);
    }
    
    await _saveWebStorage();
  }

  Future<void> _saveWebStorage() async {
    if (!kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('web_db_transactions', jsonEncode(_webTransactions.map((e) => e.toMap()).toList()));
    await prefs.setString('web_db_contacts', jsonEncode(_webContacts.map((e) => e.toMap()).toList()));
  }

  void _seedDemoData() {
    _webTransactions = [];
    _webContacts = List.from(Contact.seeds);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY, 
        userId TEXT NOT NULL,
        name TEXT NOT NULL, 
        amount REAL NOT NULL,
        type INTEGER NOT NULL, 
        category INTEGER NOT NULL,
        date TEXT NOT NULL, 
        note TEXT, 
        isCleared INTEGER NOT NULL DEFAULT 0,
        clearedDate TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE contacts (
        id TEXT PRIMARY KEY, 
        userId TEXT NOT NULL,
        name TEXT NOT NULL, 
        avatarUrl TEXT NOT NULL,
        phone TEXT, 
        email TEXT
      )
    ''');
    await _seed(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE transactions ADD COLUMN isCleared INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE transactions ADD COLUMN clearedDate TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE transactions ADD COLUMN userId TEXT NOT NULL DEFAULT "demo"');
      await db.execute('ALTER TABLE contacts ADD COLUMN userId TEXT NOT NULL DEFAULT "demo"');
    }
  }

  Future<void> _seed(Database db) async {
    final seeds = <WalletTransaction>[];
    for (final tx in seeds) {
      await db.insert('transactions', tx.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    for (final c in Contact.seeds) {
      await db.insert('contacts', c.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<List<WalletTransaction>> getAllTransactions() async {
    await init();
    if (_isWebStorage) {
      return List.unmodifiable(_webTransactions.where((t) => t.userId == _currentUserId));
    }
    final rows = await _db!.query(
      'transactions', 
      where: 'userId = ?', 
      whereArgs: [_currentUserId], 
      orderBy: 'date DESC'
    );
    return rows.map(WalletTransaction.fromMap).toList();
  }

  Future<void> insertTransaction(WalletTransaction tx) async {
    await init();
    if (_isWebStorage) {
      _webTransactions.removeWhere((t) => t.id == tx.id);
      _webTransactions.insert(0, tx);
      await _saveWebStorage();
      return;
    }
    await _db!.insert('transactions', tx.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteTransaction(String id) async {
    await init();
    if (_isWebStorage) {
      _webTransactions.removeWhere((t) => t.id == id);
      await _saveWebStorage();
      return;
    }
    await _db!.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Contact>> getAllContacts() async {
    await init();
    if (_isWebStorage) {
      return List.unmodifiable(_webContacts.where((c) => c.userId == _currentUserId));
    }
    final rows = await _db!.query(
      'contacts', 
      where: 'userId = ?', 
      whereArgs: [_currentUserId], 
      orderBy: 'name ASC'
    );
    return rows.map(Contact.fromMap).toList();
  }

  Future<void> insertContact(Contact c) async {
    await init();
    if (_isWebStorage) {
      _webContacts.removeWhere((x) => x.id == c.id);
      _webContacts.add(c);
      await _saveWebStorage();
      return;
    }
    await _db!.insert('contacts', c.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteContact(String id) async {
    await init();
    if (_isWebStorage) {
      _webContacts.removeWhere((c) => c.id == id);
      await _saveWebStorage();
      return;
    }
    await _db!.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllData() async {
    await init();
    if (_isWebStorage) {
      _webTransactions.clear();
      _webContacts.clear();
      await _saveWebStorage();
      return;
    }
    await _db!.delete('transactions');
    await _db!.delete('contacts');
  }
}
