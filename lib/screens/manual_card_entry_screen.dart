import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/cards_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/credit_card_widget.dart';

class ManualCardEntryScreen extends StatefulWidget {
  const ManualCardEntryScreen({super.key});

  @override
  State<ManualCardEntryScreen> createState() => _ManualCardEntryScreenState();
}

class _ManualCardEntryScreenState extends State<ManualCardEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _bankNameController = TextEditingController();

  String _cardNumber = '**** **** **** ****';
  String _holderName = 'HOLDER NAME';
  String _expiryDate = 'MM/YY';
  String _cvv = '***';
  CardType _cardType = CardType.visa;
  CardSubType _cardSubType = CardSubType.debit;

  @override
  void initState() {
    super.initState();
    _cardNumberController.addListener(() {
      setState(() {
        _cardNumber = _cardNumberController.text.isEmpty ? _getDefaultCardNumber() : _cardNumberController.text;
        if (_cardSubType == CardSubType.debit || _cardSubType == CardSubType.credit) {
          if (_cardNumber.startsWith('4')) {
            _cardType = CardType.visa;
          } else if (_cardNumber.startsWith('5')) {
            _cardType = CardType.mastercard;
          }
        }
      });
    });
    _holderNameController.addListener(() {
      setState(() => _holderName = _holderNameController.text.isEmpty ? _getDefaultHolderName() : _holderNameController.text.toUpperCase());
    });
    _expiryController.addListener(() {
      setState(() => _expiryDate = _expiryController.text.isEmpty ? _getDefaultExpiry() : _expiryController.text);
    });
    _cvvController.addListener(() {
      setState(() => _cvv = _cvvController.text.isEmpty ? _getDefaultCvv() : _cvvController.text.toUpperCase());
    });
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _holderNameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  String _getDefaultCardNumber() {
    switch (_cardSubType) {
      case CardSubType.pan:
        return 'ABCDE1234F';
      case CardSubType.aadhaar:
        return '0000 0000 0000';
      case CardSubType.drivingLicense:
        return 'DL-14 20110012345';
      default:
        return '**** **** **** ****';
    }
  }

  String _getDefaultHolderName() {
    return 'HOLDER NAME';
  }

  String _getDefaultExpiry() {
    switch (_cardSubType) {
      case CardSubType.pan:
      case CardSubType.aadhaar:
        return 'DD/MM/YYYY';
      case CardSubType.drivingLicense:
        return 'VAL: DD/MM/YYYY';
      default:
        return 'MM/YY';
    }
  }

  String _getDefaultCvv() {
    switch (_cardSubType) {
      case CardSubType.pan:
        return "FATHER'S NAME";
      case CardSubType.aadhaar:
        return 'GENDER';
      case CardSubType.drivingLicense:
        return 'ISSUE DATE';
      default:
        return '***';
    }
  }

  void _onCategoryChanged(CardSubType subType) {
    setState(() {
      _cardSubType = subType;
      _cardType = (subType == CardSubType.credit || subType == CardSubType.debit)
          ? CardType.visa
          : CardType.idCard;
          
      // Clear inputs to avoid mixing formats
      _cardNumberController.clear();
      _holderNameController.clear();
      _expiryController.clear();
      _cvvController.clear();
      _bankNameController.clear();
      
      // Reset preview strings to matching defaults
      _cardNumber = _getDefaultCardNumber();
      _holderName = _getDefaultHolderName();
      _expiryDate = _getDefaultExpiry();
      _cvv = _getDefaultCvv();
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final cardsProvider = context.read<CardsProvider>();
      
      Color cardColor;
      switch (_cardSubType) {
        case CardSubType.pan:
          cardColor = const Color(0xFF0F5257);
          break;
        case CardSubType.aadhaar:
          cardColor = const Color(0xFF1E272C);
          break;
        case CardSubType.drivingLicense:
          cardColor = const Color(0xFF0F2C59);
          break;
        default:
          cardColor = _cardType == CardType.visa ? const Color(0xFF1A1A1A) : const Color(0xFF2D3436);
          break;
      }

      final newCard = PaymentCard(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        cardNumber: _cardNumberController.text.trim(),
        holderName: _holderNameController.text.trim().toUpperCase(),
        expiryDate: _expiryController.text.trim(),
        cvv: _cvvController.text.trim().toUpperCase(),
        type: _cardType,
        color: cardColor,
        bankName: _isPaymentCard() 
            ? _bankNameController.text.trim()
            : _cardSubType == CardSubType.pan
                ? 'INCOME TAX DEPT'
                : _cardSubType == CardSubType.aadhaar
                    ? 'UNIQUE ID AUTHORITY'
                    : 'UNION OF INDIA',
        cardSubType: _cardSubType,
      );
      
      cardsProvider.addCard(newCard);
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_getSuccessMessage()} added successfully!'),
          backgroundColor: AppTheme.accentGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _getSuccessMessage() {
    switch (_cardSubType) {
      case CardSubType.pan:
        return 'PAN Card';
      case CardSubType.aadhaar:
        return 'Aadhaar Card';
      case CardSubType.drivingLicense:
        return 'Driving License';
      default:
        return 'Card';
    }
  }

  bool _isPaymentCard() {
    return _cardSubType == CardSubType.credit || _cardSubType == CardSubType.debit;
  }

  String _getCardNumberLabel() {
    switch (_cardSubType) {
      case CardSubType.pan:
        return 'PAN Number';
      case CardSubType.aadhaar:
        return 'Aadhaar Number';
      case CardSubType.drivingLicense:
        return 'Driving License Number';
      default:
        return 'Card Number';
    }
  }

  String _getCardNumberHint() {
    switch (_cardSubType) {
      case CardSubType.pan:
        return 'ABCDE1234F';
      case CardSubType.aadhaar:
        return '0000 0000 0000';
      case CardSubType.drivingLicense:
        return 'e.g. DL1420110012345';
      default:
        return '0000 0000 0000 0000';
    }
  }

  IconData _getCardNumberIcon() {
    switch (_cardSubType) {
      case CardSubType.pan:
        return Icons.account_balance;
      case CardSubType.aadhaar:
        return LucideIcons.fingerprint;
      case CardSubType.drivingLicense:
        return LucideIcons.compass;
      default:
        return LucideIcons.creditCard;
    }
  }

  TextInputType _getCardNumberKeyboardType() {
    if (_cardSubType == CardSubType.pan || _cardSubType == CardSubType.drivingLicense) {
      return TextInputType.text;
    }
    return TextInputType.number;
  }

  List<TextInputFormatter> _getCardNumberFormatters() {
    switch (_cardSubType) {
      case CardSubType.pan:
        return [
          LengthLimitingTextInputFormatter(10),
        ];
      case CardSubType.aadhaar:
        return [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(12),
          _AadhaarNumberFormatter(),
        ];
      case CardSubType.drivingLicense:
        return [
          LengthLimitingTextInputFormatter(16),
        ];
      default:
        return [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(16),
          _CardNumberFormatter(),
        ];
    }
  }

  String? Function(String?) _getCardNumberValidator() {
    return (v) {
      if (v == null || v.isEmpty) return 'Required';
      switch (_cardSubType) {
        case CardSubType.pan:
          final regex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
          if (!regex.hasMatch(v.toUpperCase())) return 'Invalid PAN format';
          break;
        case CardSubType.aadhaar:
          if (v.replaceAll(' ', '').length < 12) return 'Must be 12 digits';
          break;
        case CardSubType.drivingLicense:
          if (v.length < 10) return 'Invalid License Number';
          break;
        default:
          if (v.length < 19) return 'Invalid card number';
          break;
      }
      return null;
    };
  }

  String _getHolderNameLabel() {
    switch (_cardSubType) {
      case CardSubType.pan:
      case CardSubType.aadhaar:
      case CardSubType.drivingLicense:
        return 'Full Name';
      default:
        return 'Card Holder Name';
    }
  }

  String _getExpiryLabel() {
    switch (_cardSubType) {
      case CardSubType.pan:
      case CardSubType.aadhaar:
        return 'Date of Birth';
      case CardSubType.drivingLicense:
        return 'Valid Until';
      default:
        return 'Expiry Date';
    }
  }

  String _getExpiryHint() {
    switch (_cardSubType) {
      case CardSubType.pan:
      case CardSubType.aadhaar:
      case CardSubType.drivingLicense:
        return 'DD/MM/YYYY';
      default:
        return 'MM/YY';
    }
  }

  int _expiryInputLength() {
    switch (_cardSubType) {
      case CardSubType.pan:
      case CardSubType.aadhaar:
      case CardSubType.drivingLicense:
        return 8; // formatted to 10
      default:
        return 4; // formatted to 5
    }
  }

  TextInputFormatter _getExpiryFormatter() {
    switch (_cardSubType) {
      case CardSubType.pan:
      case CardSubType.aadhaar:
      case CardSubType.drivingLicense:
        return _DateFormatter();
      default:
        return _ExpiryDateFormatter();
    }
  }

  String? Function(String?) _getExpiryValidator() {
    return (v) {
      if (v == null || v.isEmpty) return 'Required';
      switch (_cardSubType) {
        case CardSubType.pan:
        case CardSubType.aadhaar:
        case CardSubType.drivingLicense:
          if (v.length < 10) return 'Use DD/MM/YYYY';
          break;
        default:
          if (v.length < 5) return 'Use MM/YY';
          break;
      }
      return null;
    };
  }

  String _getCvvLabel() {
    switch (_cardSubType) {
      case CardSubType.pan:
        return "Father's Name";
      case CardSubType.aadhaar:
        return 'Gender';
      case CardSubType.drivingLicense:
        return 'Date of Issue';
      default:
        return 'CVV';
    }
  }

  String _getCvvHint() {
    switch (_cardSubType) {
      case CardSubType.pan:
        return 'FATHER NAME';
      case CardSubType.aadhaar:
        return 'MALE / FEMALE';
      case CardSubType.drivingLicense:
        return 'DD/MM/YYYY';
      default:
        return '***';
    }
  }

  IconData _getCvvIcon() {
    switch (_cardSubType) {
      case CardSubType.pan:
        return LucideIcons.userCheck;
      case CardSubType.aadhaar:
        return Icons.people;
      case CardSubType.drivingLicense:
        return LucideIcons.calendarRange;
      default:
        return LucideIcons.lock;
    }
  }

  TextInputType _getCvvKeyboardType() {
    switch (_cardSubType) {
      case CardSubType.pan:
      case CardSubType.aadhaar:
        return TextInputType.text;
      case CardSubType.drivingLicense:
        return TextInputType.number;
      default:
        return TextInputType.number;
    }
  }

  List<TextInputFormatter> _getCvvFormatters() {
    switch (_cardSubType) {
      case CardSubType.pan:
      case CardSubType.aadhaar:
        return [];
      case CardSubType.drivingLicense:
        return [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(8),
          _DateFormatter(),
        ];
      default:
        return [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ];
    }
  }

  String? Function(String?) _getCvvValidator() {
    return (v) {
      if (v == null || v.isEmpty) return 'Required';
      switch (_cardSubType) {
        case CardSubType.drivingLicense:
          if (v.length < 10) return 'Use DD/MM/YYYY';
          break;
        case CardSubType.pan:
        case CardSubType.aadhaar:
          break;
        default:
          if (v.length < 3) return 'Invalid CVV';
          break;
      }
      return null;
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Add to Wallet', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.headlineMedium?.color)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live Preview
              CreditCardWidget(
                card: PaymentCard(
                  id: 'preview',
                  cardNumber: _cardNumber,
                  holderName: _holderName,
                  expiryDate: _expiryDate,
                  cvv: _cvv,
                  type: _cardType,
                  color: _cardSubType == CardSubType.pan 
                      ? const Color(0xFF0F5257)
                      : _cardSubType == CardSubType.aadhaar
                          ? const Color(0xFF1E272C)
                          : _cardSubType == CardSubType.drivingLicense
                              ? const Color(0xFF0F2C59)
                              : _cardType == CardType.visa 
                                  ? const Color(0xFF1A1A1A) 
                                  : const Color(0xFF2D3436),
                ),
              ),
              const SizedBox(height: 32),
              
              // Category Tabs Row
              _buildLabel('Document Type'),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryTab(CardSubType.debit, 'Debit', LucideIcons.wallet),
                      _buildCategoryTab(CardSubType.credit, 'Credit', LucideIcons.creditCard),
                      _buildCategoryTab(CardSubType.pan, 'PAN Card', Icons.account_balance),
                      _buildCategoryTab(CardSubType.aadhaar, 'Aadhaar', LucideIcons.fingerprint),
                      _buildCategoryTab(CardSubType.drivingLicense, 'License', LucideIcons.compass),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Input 1: Document/Card Number
              _buildLabel(_getCardNumberLabel()),
              TextFormField(
                controller: _cardNumberController,
                keyboardType: _getCardNumberKeyboardType(),
                textCapitalization: TextCapitalization.characters,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: _buildInputDecoration(_getCardNumberHint(), _getCardNumberIcon()),
                inputFormatters: _getCardNumberFormatters(),
                validator: _getCardNumberValidator(),
              ),
              const SizedBox(height: 20),

              // Input 2: Holder Name
              _buildLabel(_getHolderNameLabel()),
              TextFormField(
                controller: _holderNameController,
                textCapitalization: TextCapitalization.characters,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: _buildInputDecoration('FULL NAME AS PRINTED', LucideIcons.user),
                validator: (v) => v!.isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 20),

              // Inputs 3 & 4 (Expiry, CVV, Gender, Father Name, Issue Date, etc.)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(_getExpiryLabel()),
                        TextFormField(
                          controller: _expiryController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                          decoration: _buildInputDecoration(_getExpiryHint(), LucideIcons.calendar),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(_expiryInputLength()),
                            _getExpiryFormatter(),
                          ],
                          validator: _getExpiryValidator(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(_getCvvLabel()),
                        TextFormField(
                          controller: _cvvController,
                          keyboardType: _getCvvKeyboardType(),
                          textCapitalization: TextCapitalization.characters,
                          obscureText: _isPaymentCard(),
                          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                          decoration: _buildInputDecoration(_getCvvHint(), _getCvvIcon()),
                          inputFormatters: _getCvvFormatters(),
                          validator: _getCvvValidator(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              if (_isPaymentCard()) ...[
                const SizedBox(height: 20),
                _buildLabel('Bank Name'),
                TextFormField(
                  controller: _bankNameController,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: _buildInputDecoration('e.g. HDFC, SBI, ICICI', LucideIcons.landmark),
                  validator: (v) => v!.isEmpty ? 'Bank name required' : null,
                ),
              ],
              
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Add to Wallet', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppTheme.textGrey.withValues(alpha: 0.5)),
      prefixIcon: Icon(icon, color: AppTheme.accentOrange, size: 20),
      filled: true,
      fillColor: Theme.of(context).cardColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.all(16),
    );
  }

  Widget _buildCategoryTab(CardSubType category, String label, IconData icon) {
    final isSelected = _cardSubType == category;
    return GestureDetector(
      onTap: () => _onCategoryChanged(category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppTheme.textGrey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textGrey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonSpaceLength = i + 1;
      if (nonSpaceLength % 4 == 0 && nonSpaceLength != text.length) {
        buffer.write(' ');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class _AadhaarNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(' ', '');
    if (newValue.selection.baseOffset == 0) return newValue;
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonSpaceLength = i + 1;
      if (nonSpaceLength % 4 == 0 && nonSpaceLength != text.length) {
        buffer.write(' ');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonSpaceLength = i + 1;
      if (nonSpaceLength == 2 && nonSpaceLength != text.length) {
        buffer.write('/');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class _DateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll('/', '');
    if (text.length > 8) text = text.substring(0, 8);
    
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i == 1 || i == 3) && i != text.length - 1) {
        buffer.write('/');
      }
    }
    var string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
