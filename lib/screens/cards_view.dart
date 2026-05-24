import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/cards_provider.dart';
import '../theme/app_theme.dart';
import '../providers/audit_log_provider.dart';
import '../widgets/credit_card_widget.dart';

import 'manual_card_entry_screen.dart';

class CardsView extends StatelessWidget {
  const CardsView({super.key});

  @override
  Widget build(BuildContext context) {
    final cardsProvider = context.watch<CardsProvider>();
    final cards = cardsProvider.cards;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            floating: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text('My Wallet', 
                style: TextStyle(color: Theme.of(context).textTheme.headlineLarge?.color, fontWeight: FontWeight.bold, fontSize: 24)),
            background: Container(color: Colors.transparent),
            ),
          ),
          
          if (cards.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('No cards added yet', style: TextStyle(color: AppTheme.textGrey)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final card = cards[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _SlidableCard(
                        key: ValueKey(card.id),
                        card: card,
                        onDelete: () {
                          cardsProvider.removeCard(card.id);
                          final cardName = _getCardName(card);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$cardName removed'),
                              backgroundColor: Colors.redAccent,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    );
                  },
                  childCount: cards.length,
                ),
              ),
            ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 88),
        child: FloatingActionButton(
          onPressed: () {
            context.read<AuditLogProvider>().logAction('Tap', 'Opened Manual Card Entry screen');
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManualCardEntryScreen()),
            );
          },
          backgroundColor: AppTheme.accentOrange,
          child: const Icon(LucideIcons.plus, color: Colors.white),
        ),
      ),
    );
  }


}

class _SlidableCard extends StatefulWidget {
  final PaymentCard card;
  final VoidCallback onDelete;

  const _SlidableCard({super.key, required this.card, required this.onDelete});

  @override
  State<_SlidableCard> createState() => _SlidableCardState();
}

class _SlidableCardState extends State<_SlidableCard> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _exitController;
  double _dragOffset = 0;
  final double _maxDragWidth = 80;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _exitController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isDeleting) return;
    setState(() {
      _dragOffset += details.primaryDelta!;
      if (_dragOffset > 0) _dragOffset = 0;
      if (_dragOffset < -_maxDragWidth * 1.5) _dragOffset = -_maxDragWidth * 1.5;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_isDeleting) return;
    if (_dragOffset < -_maxDragWidth / 2) {
      _snapTo(-_maxDragWidth);
    } else {
      _snapTo(0);
    }
  }

  void _snapTo(double target) {
    final start = _dragOffset;
    final animation = Tween<double>(begin: start, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.reset();
    animation.addListener(() {
      setState(() => _dragOffset = animation.value);
    });
    _controller.forward();
  }

  Future<void> _handleDelete() async {
    final audit = context.read<AuditLogProvider>();
    final cardName = _getCardName(widget.card);
    final cardNum = widget.card.cardNumber;
    final lastChars = cardNum.length >= 4 ? cardNum.substring(cardNum.length - 4) : cardNum;
    audit.logAction('Tap', 'Deleting $cardName ending in $lastChars');
    setState(() => _isDeleting = true);
    await _exitController.forward();
    widget.onDelete();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _exitController, curve: const Interval(0.4, 1.0, curve: Curves.easeInOut)),
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(parent: _exitController, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
        ),
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 0.8).animate(
            CurvedAnimation(parent: _exitController, curve: Curves.easeOut),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: _dragOffset == 0 ? 0.0 : 1.0,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: _isDeleting ? null : _handleDelete,
                          child: Container(
                            width: _maxDragWidth,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(LucideIcons.trash2, color: Colors.white, size: 28),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onHorizontalDragUpdate: _onHorizontalDragUpdate,
                onHorizontalDragEnd: _onHorizontalDragEnd,
                child: Transform.translate(
                  offset: Offset(_dragOffset, 0),
                  child: CreditCardWidget(
                    card: widget.card,
                    isLocked: _dragOffset != 0 || _isDeleting,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _getCardName(PaymentCard card) {
  switch (card.cardSubType) {
    case CardSubType.pan:
      return 'PAN Card';
    case CardSubType.aadhaar:
      return 'Aadhaar Card';
    case CardSubType.drivingLicense:
      return 'Driving License';
    case CardSubType.credit:
      return 'Credit Card';
    case CardSubType.debit:
      return 'Debit Card';
  }
}
