import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class PartyingScreen extends StatefulWidget {
  const PartyingScreen({super.key});

  @override
  State<PartyingScreen> createState() => _PartyingScreenState();
}

class _PartyingScreenState extends State<PartyingScreen> {
  final _billController = TextEditingController();
  int _peopleCount = 2;
  double _tipPercentage = 10;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('party_split_history');
    if (data != null) {
      setState(() {
        _history = List<Map<String, dynamic>>.from(jsonDecode(data));
      });
    }
  }

  Future<void> _saveToHistory() async {
    final bill = double.tryParse(_billController.text) ?? 0;
    if (bill <= 0) return;

    final newItem = {
      'bill': bill,
      'people': _peopleCount,
      'perPerson': _perPersonAmount,
      'date': DateTime.now().toIso8601String(),
    };

    setState(() {
      _history.insert(0, newItem);
      if (_history.length > 20) _history = _history.sublist(0, 20);
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('party_split_history', jsonEncode(_history));
  }

  @override
  void dispose() {
    _billController.dispose();
    super.dispose();
  }

  double get _totalWithTip {
    final bill = double.tryParse(_billController.text) ?? 0;
    return bill + (bill * (_tipPercentage / 100));
  }

  double get _perPersonAmount {
    if (_peopleCount == 0) return 0;
    return _totalWithTip / _peopleCount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Party Splitter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/nightclub_vibrant_bg_1778959082761.png',
              fit: BoxFit.cover,
            ),
          ),
          // Dark Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.95),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildResultCard(),
                  const SizedBox(height: 32),
                  _buildInputSection(),
                  const SizedBox(height: 40),
                  _buildHistorySection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Each Person Pays',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 16),
          ),
          const SizedBox(height: 12),
          Text(
            '₹${_perPersonAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSmallStat('Total Bill', '₹${double.tryParse(_billController.text) ?? 0}'),
              _buildSmallStat('Total Tip', '₹${(_totalWithTip - (double.tryParse(_billController.text) ?? 0)).toStringAsFixed(1)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bill Amount', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(
          controller: _billController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Enter amount...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            prefixIcon: const Icon(LucideIcons.indianRupee, color: Colors.purpleAccent),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Number of People', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.bold)),
            Row(
              children: [
                _buildCircularButton(LucideIcons.minus, () {
                  if (_peopleCount > 1) {
                    HapticFeedback.lightImpact();
                    setState(() => _peopleCount--);
                  }
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('$_peopleCount', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                _buildCircularButton(LucideIcons.plus, () {
                  HapticFeedback.lightImpact();
                  setState(() => _peopleCount++);
                }),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text('Tip Percentage (${_tipPercentage.toInt()}%)', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.bold)),
        Slider(
          value: _tipPercentage,
          min: 0,
          max: 30,
          divisions: 6,
          activeColor: Colors.purpleAccent,
          inactiveColor: Colors.white.withValues(alpha: 0.1),
          onChanged: (v) {
            HapticFeedback.selectionClick();
            setState(() => _tipPercentage = v);
          },
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: () async {
              HapticFeedback.mediumImpact();
              await _saveToHistory();
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 8,
              shadowColor: Colors.purpleAccent.withValues(alpha: 0.5),
            ),
            child: const Text('Split & Save to History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    if (_history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Splits', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('party_split_history');
                setState(() => _history = []);
              },
              child: Text('Clear', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _history.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = _history[index];
            final date = DateTime.parse(item['date']);
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.purpleAccent.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(LucideIcons.users, color: Colors.purpleAccent, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('₹${item['perPerson'].toStringAsFixed(2)} / person',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          '${item['people']} people • Bill ₹${item['bill']}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(DateFormat('MMM dd').format(date), style: const TextStyle(color: Colors.white, fontSize: 12)),
                      Text(DateFormat('hh:mm a').format(date),
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCircularButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
