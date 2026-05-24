import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/cards_provider.dart';
import '../theme/app_theme.dart';

class CreditCardWidget extends StatefulWidget {
  final PaymentCard card;
  final bool isLocked;

  const CreditCardWidget({super.key, required this.card, this.isLocked = false});

  @override
  State<CreditCardWidget> createState() => _CreditCardWidgetState();
}

class _CreditCardWidgetState extends State<CreditCardWidget> {
  bool _isBackVisible = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        if (!widget.isLocked) {
          setState(() => _isBackVisible = !_isBackVisible);
        }
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: 0, end: _isBackVisible ? 180 : 0),
          builder: (context, value, child) {
            final isHalfway = value > 90;
            
            // Perspective matrix
            final matrix = Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateY(value * 3.1415927 / 180); // convert to radians

            return Transform(
              transform: matrix,
              alignment: Alignment.center,
              child: isHalfway
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(3.1415927), // Flip back side
                      child: _buildBack(),
                    )
                  : _buildFront(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFront() {
    if (widget.card.cardSubType == CardSubType.pan) {
      return _buildFrontPAN();
    } else if (widget.card.cardSubType == CardSubType.aadhaar) {
      return _buildFrontAadhaar();
    } else if (widget.card.cardSubType == CardSubType.drivingLicense) {
      return _buildFrontDL();
    }

    return Container(
      key: const ValueKey(false),
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.card.color,
            widget.card.color.withValues(alpha: 0.8),
            Colors.black.withValues(alpha: 0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Glass effect highlight
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.card.bankName.isNotEmpty)
                          Text(
                            widget.card.bankName.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.card.cardSubType == CardSubType.credit ? 'CREDIT' : 'DEBIT',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    _buildCardTypeIcon(),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                Text(
                  widget.card.cardNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    letterSpacing: 2,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CARD HOLDER', 
                          style: TextStyle(color: AppTheme.textGrey, fontSize: 10)),
                        const SizedBox(height: 4),
                        Text(widget.card.holderName, 
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('EXPIRES', 
                          style: TextStyle(color: AppTheme.textGrey, fontSize: 10)),
                        const SizedBox(height: 4),
                        Text(widget.card.expiryDate, 
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrontPAN() {
    return Container(
      key: const ValueKey('pan_front'),
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F5257),
            Color(0xFF0B3C40),
            Colors.black,
          ],
        ),
        border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: -30,
            left: -30,
            child: Icon(Icons.account_balance, size: 180, color: Colors.tealAccent.withValues(alpha: 0.03)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'INCOME TAX DEPARTMENT',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                        Text(
                          'GOVERNMENT OF INDIA',
                          style: TextStyle(color: Colors.tealAccent.withValues(alpha: 0.7), fontSize: 8, fontWeight: FontWeight.w500, letterSpacing: 1.0),
                        ),
                      ],
                    ),
                    const Icon(Icons.account_balance, color: AppTheme.accentYellow, size: 24),
                  ],
                ),
                
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Permanent Account Number', style: TextStyle(color: AppTheme.textGrey, fontSize: 8)),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              widget.card.cardNumber.toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.accentYellow,
                                fontSize: 18,
                                letterSpacing: 1.5,
                                fontFamily: 'Courier',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          const Text('HOLDER NAME', style: TextStyle(color: AppTheme.textGrey, fontSize: 7)),
                          Text(widget.card.holderName.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          
                          const Text("FATHER'S NAME", style: TextStyle(color: AppTheme.textGrey, fontSize: 7)),
                          Text(widget.card.cvv.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFFD700)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [BoxShadow(color: Colors.yellow.withValues(alpha: 0.2), blurRadius: 4)],
                            ),
                            child: const Icon(Icons.security, size: 20, color: Colors.black87),
                          ),
                          const SizedBox(height: 16),
                          const Text('DATE OF BIRTH', style: TextStyle(color: AppTheme.textGrey, fontSize: 7)),
                          Text(widget.card.expiryDate, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrontAadhaar() {
    return Container(
      key: const ValueKey('aadhaar_front'),
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E272C),
            Color(0xFF0F1416),
            Colors.black,
          ],
        ),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(LucideIcons.fingerprint, size: 140, color: AppTheme.accentOrange.withValues(alpha: 0.04)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'GOVERNMENT OF INDIA',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                        ),
                        Text(
                          'Unique Identification Authority of India',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 8),
                        ),
                      ],
                    ),
                    const Icon(LucideIcons.fingerprint, color: AppTheme.accentOrange, size: 24),
                  ],
                ),
                
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: const Icon(LucideIcons.user, color: AppTheme.accentOrange, size: 32),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('NAME', style: TextStyle(color: AppTheme.textGrey, fontSize: 7)),
                          Text(widget.card.holderName.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('DOB', style: TextStyle(color: AppTheme.textGrey, fontSize: 7)),
                                  Text(widget.card.expiryDate, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(width: 24),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('GENDER', style: TextStyle(color: AppTheme.textGrey, fontSize: 7)),
                                  Text(widget.card.cvv.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.card.cardNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        letterSpacing: 2.5,
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrontDL() {
    return Container(
      key: const ValueKey('dl_front'),
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F2C59),
            Color(0xFF071E3D),
            Colors.black,
          ],
        ),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            bottom: -30,
            child: Icon(LucideIcons.compass, size: 160, color: Colors.blueAccent.withValues(alpha: 0.03)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'UNION OF INDIA - DRIVING LICENSE',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                        ),
                        Text(
                          'MINISTRY OF ROAD TRANSPORT & HIGHWAYS',
                          style: TextStyle(color: Colors.blueAccent.withValues(alpha: 0.7), fontSize: 7, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const Icon(LucideIcons.compass, color: Colors.blueAccent, size: 24),
                  ],
                ),
                
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('LICENSE NUMBER', style: TextStyle(color: AppTheme.textGrey, fontSize: 8)),
                          Text(
                            widget.card.cardNumber.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              letterSpacing: 1.0,
                              fontFamily: 'Courier',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          
                          const Text('HOLDER NAME', style: TextStyle(color: AppTheme.textGrey, fontSize: 7)),
                          Text(widget.card.holderName.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('ISSUE DATE', style: TextStyle(color: AppTheme.textGrey, fontSize: 7)),
                                  Text(widget.card.cvv, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(width: 24),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('VALID UNTIL', style: TextStyle(color: AppTheme.textGrey, fontSize: 7)),
                                  Text(widget.card.expiryDate, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Container(
                            width: 36,
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE2E2E2), Color(0xFFC0C0C0), Color(0xFFE2E2E2)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(LucideIcons.cpu, size: 18, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    if (widget.card.cardSubType == CardSubType.pan) {
      return _buildBackPAN();
    } else if (widget.card.cardSubType == CardSubType.aadhaar) {
      return _buildBackAadhaar();
    } else if (widget.card.cardSubType == CardSubType.drivingLicense) {
      return _buildBackDL();
    }

    return Container(
      key: const ValueKey(true),
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: widget.card.color,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          Container(
            height: 50,
            width: double.infinity,
            color: Colors.black,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  height: 40,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.card.cvv,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'AUTHORIZED SIGNATURE',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackPAN() {
    return Container(
      key: const ValueKey('pan_back'),
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF0B3C40),
        border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.1), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'IN CASE OF ENQUIRY OR CHANGE, PLEASE CONTACT THE INCOME TAX OUTLET OR RESUBMIT ON THE GOVERNMENT NSDL PORTAL.',
              style: TextStyle(color: Colors.white60, fontSize: 8, height: 1.4),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Text(
                          'Sandesh Reddy',
                          style: TextStyle(fontFamily: 'Courier', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('AUTHORIZED SIGNATURE', style: TextStyle(color: AppTheme.textGrey, fontSize: 6)),
                  ],
                ),
                Icon(Icons.qr_code, size: 50, color: Colors.white.withValues(alpha: 0.6)),
              ],
            ),
            const Divider(color: Colors.white24, height: 1),
            const Center(
              child: Text(
                'Issued by the Income Tax Department, Government of India.',
                style: TextStyle(color: AppTheme.textGrey, fontSize: 7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackAadhaar() {
    return Container(
      key: const ValueKey('aadhaar_back'),
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF0F1416),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.1), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Aadhaar is a proof of identity, not of citizenship. It is generated using secure biometric collection methods.',
              style: TextStyle(color: Colors.white60, fontSize: 8, height: 1.4),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ADDRESS', style: TextStyle(color: AppTheme.textGrey, fontSize: 7)),
                    Text(
                      '12, Outer Ring Road, Tech Enclave,\nBangalore, Karnataka - 560103',
                      style: TextStyle(color: Colors.white, fontSize: 9, height: 1.3),
                    ),
                  ],
                ),
                Icon(Icons.qr_code_scanner, size: 50, color: Colors.white.withValues(alpha: 0.6)),
              ],
            ),
            const Divider(color: Colors.white24, height: 1),
            const Center(
              child: Text(
                'www.uidai.gov.in • Toll Free: 1947',
                style: TextStyle(color: AppTheme.textGrey, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackDL() {
    return Container(
      key: const ValueKey('dl_back'),
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF071E3D),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.1), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'AUTHORIZED VEHICLE CLASSES TO DRIVE:',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 8, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDLClassRow('MCWG', 'MOTORCYCLE WITH GEAR'),
                    const SizedBox(height: 6),
                    _buildDLClassRow('LMV', 'LIGHT MOTOR VEHICLE'),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('ISSUING AUTHORITY', style: TextStyle(color: AppTheme.textGrey, fontSize: 6)),
                    const Text('RTO DELHI', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Icon(Icons.qr_code, size: 36, color: Colors.white.withValues(alpha: 0.6)),
                  ],
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 1),
            const Center(
              child: Text(
                'If found, please return to the nearest Transport Authority Office.',
                style: TextStyle(color: AppTheme.textGrey, fontSize: 7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDLClassRow(String code, String desc) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(code, style: const TextStyle(color: Colors.blueAccent, fontSize: 8, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Text(desc, style: const TextStyle(color: Colors.white, fontSize: 8)),
      ],
    );
  }

  Widget _buildCardTypeIcon() {
    switch (widget.card.type) {
      case CardType.visa:
        return const Text('VISA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24, fontStyle: FontStyle.italic));
      case CardType.mastercard:
        return Row(
          children: [
            Container(width: 24, height: 24, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
            Transform.translate(offset: const Offset(-8, 0), child: Container(width: 24, height: 24, decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.8), shape: BoxShape.circle))),
          ],
        );
      case CardType.amex:
        return const Icon(LucideIcons.creditCard, color: Colors.blueAccent, size: 32);
      case CardType.idCard:
        if (widget.card.cardSubType == CardSubType.pan) {
          return const Icon(Icons.account_balance, color: AppTheme.accentYellow, size: 24);
        } else if (widget.card.cardSubType == CardSubType.aadhaar) {
          return const Icon(LucideIcons.fingerprint, color: AppTheme.accentOrange, size: 24);
        } else {
          return const Icon(LucideIcons.compass, color: Colors.blueAccent, size: 24);
        }
    }
  }
}
