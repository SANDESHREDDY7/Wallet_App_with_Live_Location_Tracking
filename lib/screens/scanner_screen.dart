import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

import 'package:provider/provider.dart';
import '../providers/contact_provider.dart';
import '../providers/cards_provider.dart';
import '../models/contact.dart';
import 'send_money_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isFirstSideScanned = false;
  bool _isProcessing = false;
  bool _isAutoScanning = false;

  @override
  void initState() {
    super.initState();
    _startAutoScan();
  }

  void _startAutoScan() async {
    if (!mounted || _isAutoScanning) return;
    _isAutoScanning = true;
    
    // Simulate time taken to align the front side of the card
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    _handleScan();
    
    // Simulate time taken to flip and align the back side of the card
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;
    _handleScan();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          MobileScanner(
            controller: controller,
            errorBuilder: (context, error, child) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.cameraOff, color: Colors.red, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'Camera Error',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        error.errorCode == MobileScannerErrorCode.permissionDenied
                            ? 'Camera permission was denied. Please enable it in settings.'
                            : 'Could not initialize camera. If on web, ensure you are using HTTPS or localhost.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textGrey),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              );
            },
            onDetect: (capture) {
              if (_isProcessing) return;
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                _handleScan();
              }
            },
          ),

          // Overlay
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: _isFirstSideScanned ? AppTheme.accentYellow : AppTheme.accentGreen,
                borderRadius: 24,
                borderLength: 40,
                borderWidth: 10,
                cutOutWidth: 320,
                cutOutHeight: 200,
              ),
            ),
          ),

          // Top Bar
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                  child: IconButton(
                    icon: const Icon(LucideIcons.x, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isFirstSideScanned ? 'Scan Back Side' : 'Scan Front Side',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isFirstSideScanned ? 'Step 2 of 2' : 'Step 1 of 2',
                      style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
                    ),
                  ],
                ),
                CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                  child: IconButton(
                    icon: ValueListenableBuilder(
                      valueListenable: controller,
                      builder: (context, state, child) {
                        switch (state.torchState) {
                          case TorchState.off:
                            return const Icon(LucideIcons.zapOff, color: Colors.white);
                          case TorchState.on:
                            return const Icon(LucideIcons.zap, color: AppTheme.accentYellow);
                          default:
                            return Icon(LucideIcons.zapOff, color: Colors.white.withValues(alpha: 0.5));
                        }
                      },
                    ),
                    onPressed: () => controller.toggleTorch(),
                  ),
                ),
              ],
            ),
          ),

          // Scanning Animation (Central Line)
          if (!_isProcessing)
            Center(
              child: _ScanningLine(width: 300),
            ),

          // Bottom Hint
          Positioned(
            bottom: 60,
            left: 40,
            right: 40,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey(_isFirstSideScanned),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: _isFirstSideScanned ? AppTheme.accentYellow.withValues(alpha: 0.3) : Colors.transparent),
                ),
                child: Text(
                  _isFirstSideScanned 
                      ? 'Excellent! Now scan the second side' 
                      : 'Place the front side of your card inside the frame',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.8),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.accentGreen),
                    SizedBox(height: 24),
                    Text('Processing card details...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleScan() async {
    setState(() => _isProcessing = true);
    
    // Simulate processing time for realism
    await Future.delayed(const Duration(seconds: 1));

    if (!_isFirstSideScanned) {
      // First side done
      if (mounted) {
        setState(() {
          _isFirstSideScanned = true;
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Front side captured! Please flip the card.'),
            backgroundColor: AppTheme.accentGreen,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Second side done - open form to confirm details
      if (mounted) {
        setState(() => _isProcessing = false);
        _showCardDetailsForm();
      }
    }
  }

  void _showCardDetailsForm() {
    final cardNumberCtrl = TextEditingController();
    final holderNameCtrl = TextEditingController();
    final expiryCtrl = TextEditingController();
    final cvvCtrl = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Confirm Card Details', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Please verify or enter your card details below.', style: TextStyle(color: AppTheme.textGrey, fontSize: 14)),
            const SizedBox(height: 20),
            TextField(
              controller: cardNumberCtrl,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Card Number',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                filled: true, fillColor: AppTheme.bgDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: holderNameCtrl,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Cardholder Name',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                filled: true, fillColor: AppTheme.bgDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: expiryCtrl,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.datetime,
                    decoration: InputDecoration(
                      hintText: 'MM/YY',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      filled: true, fillColor: AppTheme.bgDark,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: cvvCtrl,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'CVV',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      filled: true, fillColor: AppTheme.bgDark,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (cardNumberCtrl.text.isEmpty || holderNameCtrl.text.isEmpty) return;

                  final cardsProvider = context.read<CardsProvider>();
                  
                  // Add a new card to the wallet
                  final newCard = PaymentCard(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    cardNumber: cardNumberCtrl.text.trim(),
                    holderName: holderNameCtrl.text.trim().toUpperCase(),
                    expiryDate: expiryCtrl.text.trim().isEmpty ? '12/28' : expiryCtrl.text.trim(),
                    cvv: cvvCtrl.text.trim(),
                    type: CardType.visa,
                    color: const Color(0xFF0F172A),
                  );
                  
                  cardsProvider.addCard(newCard);

                  Navigator.pop(ctx); // close bottom sheet
                  Navigator.pop(context); // close scanner screen
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Card successfully added to your wallet!'),
                      backgroundColor: AppTheme.accentGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Add Card', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanningLine extends StatefulWidget {
  final double width;
  const _ScanningLine({required this.width});

  @override
  State<_ScanningLine> createState() => _ScanningLineState();
}

class _ScanningLineState extends State<_ScanningLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -100 + (200 * _controller.value)),
          child: Container(
            width: widget.width,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentGreen.withValues(alpha: 0),
                  AppTheme.accentGreen,
                  AppTheme.accentGreen.withValues(alpha: 0),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentGreen.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Custom overlay shape for the scanner
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutWidth;
  final double cutOutHeight;

  const QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 1.0,
    this.overlayColor = const Color(0x88000000),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutWidth = 250,
    this.cutOutHeight = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height),
          Radius.circular(borderRadius)))
      ..close();
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRect(rect)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final center = rect.center;

    final cutOutRect = Rect.fromCenter(
      center: center,
      width: cutOutWidth,
      height: cutOutHeight,
    );

    final backgroundPaint = Paint()..color = overlayColor;
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()..addRRect(RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius))),
      ),
      backgroundPaint,
    );

    final path = Path();
    // Top Left
    path.moveTo(cutOutRect.left, cutOutRect.top + borderLength);
    path.lineTo(cutOutRect.left, cutOutRect.top + borderRadius);
    path.arcToPoint(Offset(cutOutRect.left + borderRadius, cutOutRect.top), radius: Radius.circular(borderRadius));
    path.lineTo(cutOutRect.left + borderLength, cutOutRect.top);

    // Top Right
    path.moveTo(cutOutRect.right - borderLength, cutOutRect.top);
    path.lineTo(cutOutRect.right - borderRadius, cutOutRect.top);
    path.arcToPoint(Offset(cutOutRect.right, cutOutRect.top + borderRadius), radius: Radius.circular(borderRadius));
    path.lineTo(cutOutRect.right, cutOutRect.top + borderLength);

    // Bottom Right
    path.moveTo(cutOutRect.right, cutOutRect.bottom - borderLength);
    path.lineTo(cutOutRect.right, cutOutRect.bottom - borderRadius);
    path.arcToPoint(Offset(cutOutRect.right - borderRadius, cutOutRect.bottom), radius: Radius.circular(borderRadius));
    path.lineTo(cutOutRect.right - borderLength, cutOutRect.bottom);

    // Bottom Left
    path.moveTo(cutOutRect.left + borderLength, cutOutRect.bottom);
    path.lineTo(cutOutRect.left + borderRadius, cutOutRect.bottom);
    path.arcToPoint(Offset(cutOutRect.left, cutOutRect.bottom - borderRadius), radius: Radius.circular(borderRadius));
    path.lineTo(cutOutRect.left, cutOutRect.bottom - borderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
