import 'package:flutter/material.dart';
import '../repositories/preferences_repository.dart';
import '../services/auth_service.dart';

enum CardSubType { credit, debit, pan, aadhaar, drivingLicense }

class PaymentCard {
  final String id;
  final String cardNumber;
  final String holderName;
  final String expiryDate;
  final String cvv;
  final CardType type;
  final Color color;
  final String bankName;
  final CardSubType cardSubType;

  PaymentCard({
    required this.id,
    required this.cardNumber,
    required this.holderName,
    required this.expiryDate,
    required this.cvv,
    required this.type,
    required this.color,
    this.bankName = '',
    this.cardSubType = CardSubType.debit,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cardNumber': cardNumber,
      'holderName': holderName,
      'expiryDate': expiryDate,
      'cvv': cvv,
      'type': type.index,
      'color': color.value,
      'bankName': bankName,
      'cardSubType': cardSubType.index,
    };
  }

  factory PaymentCard.fromMap(Map<String, dynamic> map) {
    return PaymentCard(
      id: map['id'] as String,
      cardNumber: map['cardNumber'] as String,
      holderName: map['holderName'] as String,
      expiryDate: map['expiryDate'] as String,
      cvv: map['cvv'] as String,
      type: CardType.values[map['type'] as int],
      color: Color(map['color'] as int),
      bankName: map['bankName'] as String? ?? '',
      cardSubType: map['cardSubType'] != null
          ? CardSubType.values[map['cardSubType'] as int]
          : CardSubType.debit,
    );
  }
}

enum CardType { visa, mastercard, amex, idCard }

class CardsProvider with ChangeNotifier {
  List<PaymentCard> _cards = [];
  final _prefs = PreferencesRepository.instance;
  final _auth = AuthService.instance;

  List<PaymentCard> get cards => [..._cards];

  Future<void> load() async {
    final email = _auth.currentUser?.email;
    if (email == null) return;
    
    final cardsData = await _prefs.getCards(email);
    _cards = cardsData.map((e) => PaymentCard.fromMap(e)).toList();
    notifyListeners();
  }

  Future<void> _save() async {
    final email = _auth.currentUser?.email;
    if (email == null) return;
    
    final cardsData = _cards.map((e) => e.toMap()).toList();
    await _prefs.saveCards(email, cardsData);
  }

  void addCard(PaymentCard card) {
    _cards.add(card);
    _save();
    notifyListeners();
  }

  void removeCard(String id) {
    _cards.removeWhere((c) => c.id == id);
    _save();
    notifyListeners();
  }

  void clear() {
    _cards.clear();
    _save();
    notifyListeners();
  }
}
