import 'package:flutter/material.dart';
import '../models/note_item.dart';
import '../repositories/preferences_repository.dart';
import '../services/auth_service.dart';

class NoteProvider with ChangeNotifier {
  final PreferencesRepository _repo = PreferencesRepository.instance;
  final AuthService _auth = AuthService.instance;
  
  List<NoteItem> _notes = [];
  bool _isLoading = false;

  List<NoteItem> get notes => _notes;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    final user = await _auth.getCurrentUser();
    if (user == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    _notes = await _repo.getNotes(user.email);
    _notes.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addNote(NoteItem note) async {
    final user = await _auth.getCurrentUser();
    if (user == null) return;
    
    _notes.insert(0, note);
    await _repo.saveNotes(user.email, _notes);
    notifyListeners();
  }

  Future<void> updateNote(NoteItem updatedNote) async {
    final user = await _auth.getCurrentUser();
    if (user == null) return;
    
    final index = _notes.indexWhere((n) => n.id == updatedNote.id);
    if (index != -1) {
      _notes[index] = updatedNote;
      await _repo.saveNotes(user.email, _notes);
      notifyListeners();
    }
  }

  Future<void> deleteNote(String id) async {
    final user = await _auth.getCurrentUser();
    if (user == null) return;
    
    _notes.removeWhere((n) => n.id == id);
    await _repo.saveNotes(user.email, _notes);
    notifyListeners();
  }

  void clear() {
    _notes = [];
    notifyListeners();
  }
}
