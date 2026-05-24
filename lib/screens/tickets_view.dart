import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../models/ticket_item.dart';
import '../providers/ticket_provider.dart';
import '../providers/audit_log_provider.dart';
import '../theme/app_theme.dart';
import 'add_ticket_screen.dart';
import 'note_detail_screen.dart'; // Reuse FullImageScreen and PdfViewerScreen
import '../services/calendar_sync_service.dart';
import 'live_journey_tracker.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  String _activeTab = 'all'; // 'all' | 'flight' | 'train' | 'bus'
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load tickets on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showCalendarSyncSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return _CalendarSyncBottomSheet(
          onSyncComplete: () {
            // Refresh parent state
            setState(() {});
          },
        );
      },
    );
  }

  List<TicketItem> _filterTickets(List<TicketItem> tickets) {
    final now = DateTime.now();
    return tickets.where((t) {
      // 1. Filter by active tab (History vs All)
      bool matchesTab = false;
      
      // Ticket transitions to History after the trip
      final isCompleted = t.isCompleted || now.isAfter(t.date);

      if (_activeTab == 'history') {
        matchesTab = isCompleted;
      } else {
        matchesTab = !isCompleted;
      }

      // 2. Filter by search query
      final matchesSearch = t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.boardingPointName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.destinationPointName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.pnr.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.passengerName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesTab && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleIconColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: titleIconColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('My Tickets & Bookings',
            style: TextStyle(color: titleIconColor, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.plus, color: titleIconColor),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTicketScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search tickets, operator, PNR...',
                hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black38),
                prefixIcon: const Icon(LucideIcons.search, color: AppTheme.textGrey, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, color: AppTheme.textGrey, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.08),
                    width: isDark ? 0 : 1,
                  ),
                ),
              ),
            ),
          ),

          // 2. Tab Selector
          _buildTabs(),
          const SizedBox(height: 16),

          // 3. Ticket List View
          Expanded(
            child: Consumer<TicketProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple));
                }

                final filteredList = _filterTickets(provider.tickets);

                if (filteredList.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  itemCount: filteredList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 24),
                  itemBuilder: (context, index) {
                    final ticket = filteredList[index];
                    return _buildTicketCard(ticket);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = [
      {'key': 'all', 'label': 'All'},
      {'key': 'history', 'label': 'History'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: tabs.map((t) {
          final isSelected = _activeTab == t['key'];
          Color color = AppTheme.primaryPurple;
          if (t['key'] == 'history') color = Colors.amberAccent;

          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _activeTab = t['key'] as String);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.15) : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? color.withValues(alpha: 0.4)
                        : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08)),
                  ),
                ),
                child: Text(
                  t['label'] as String,
                  style: TextStyle(
                    color: isSelected ? (isDark ? Colors.white : color) : AppTheme.textGrey,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTicketCard(TicketItem ticket) {
    Color transportColor = AppTheme.primaryPurple;
    IconData icon = LucideIcons.plane;
    String typeText = 'FLIGHT';
    if (ticket.type == 'train') {
      transportColor = Colors.redAccent;
      icon = LucideIcons.train;
      typeText = 'TRAIN';
    } else if (ticket.type == 'bus') {
      transportColor = Colors.greenAccent;
      icon = LucideIcons.bus;
      typeText = 'BUS';
    }

    final isPast = ticket.isCompleted || DateTime.now().isAfter(ticket.date);
    final dateStr = DateFormat('EEE, dd MMM yyyy').format(ticket.date);
    final timeStr = DateFormat('hh:mm a').format(ticket.date);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final dashedColor = isDark ? Colors.white12 : Colors.black12;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LiveJourneyTrackerScreen(ticket: ticket),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isPast ? Colors.amberAccent.withValues(alpha: 0.15) : transportColor.withValues(alpha: 0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: isPast ? Colors.amberAccent.withValues(alpha: 0.02) : transportColor.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Top Section (Boarding headers)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: isPast ? Colors.amberAccent.withValues(alpha: 0.05) : transportColor.withValues(alpha: 0.08),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isPast ? Colors.amberAccent.withValues(alpha: 0.1) : transportColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: isPast ? Colors.amberAccent : transportColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ticket.title,
                      style: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Unified single-badge design (Category for upcoming, checkmarked COMPLETED for past)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isPast 
                          ? Colors.amberAccent.withValues(alpha: 0.12) 
                          : transportColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: isPast 
                          ? Border.all(color: Colors.amberAccent.withValues(alpha: 0.25), width: 0.5)
                          : Border.all(color: transportColor.withValues(alpha: 0.2), width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isPast) ...[
                          const Icon(LucideIcons.checkCircle2, color: Colors.amberAccent, size: 10),
                          const SizedBox(width: 4),
                          const Text(
                            'COMPLETED',
                            style: TextStyle(
                              color: Colors.amberAccent, 
                              fontSize: 9, 
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ] else ...[
                          Text(
                            typeText,
                            style: TextStyle(
                              color: transportColor, 
                              fontSize: 9, 
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Middle Section (Locations)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ticket.boardingPointName,
                              style: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.w900, fontSize: 18),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 2),
                            const Text('Boarding', style: TextStyle(color: AppTheme.textGrey, fontSize: 10)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          Icon(LucideIcons.arrowRightLeft, color: transportColor, size: 16),
                          const SizedBox(height: 4),
                          Container(
                            height: 2,
                            width: 40,
                            color: transportColor.withValues(alpha: 0.2),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              ticket.destinationPointName,
                              style: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.w900, fontSize: 18),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 2),
                            const Text('Destination', style: TextStyle(color: AppTheme.textGrey, fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Divider (Dashed visual cutout)
                  Row(
                    children: List.generate(
                      150 ~/ 4,
                      (i) => Expanded(
                        child: Container(
                          color: i % 2 == 0 ? Colors.transparent : dashedColor,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Metadata details Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDetailItem('Passenger Name', ticket.passengerName, CrossAxisAlignment.start),
                      _buildDetailItem('PNR / Booking Ref', ticket.pnr, CrossAxisAlignment.end),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDetailItem('Departure Date', '$dateStr @ $timeStr', CrossAxisAlignment.start),
                      _buildDetailItem(
                        ticket.type == 'flight' ? 'Seat / Class' : (ticket.type == 'train' ? 'Coach/Berth' : 'Seat'),
                        ticket.seatNumber,
                        CrossAxisAlignment.end,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Barcode Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    children: List.generate(
                      150 ~/ 4,
                      (i) => Expanded(
                        child: Container(
                          color: i % 2 == 0 ? Colors.transparent : dashedColor,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildBarcode(ticket.pnr, transportColor),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Bottom Actions (Attachments & Delete)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: Colors.white.withValues(alpha: 0.02),
              child: Row(
                children: [
                  if (ticket.pdfPath != null)
                    _buildAttachmentButton(
                      icon: LucideIcons.fileText,
                      label: 'View Ticket PDF',
                      color: Colors.redAccent,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => PdfViewerScreen(pdfPath: ticket.pdfPath!)));
                      },
                    ),
                  if (ticket.imagePath != null)
                    _buildAttachmentButton(
                      icon: LucideIcons.image,
                      label: 'View Boarding Pass',
                      color: Colors.blueAccent,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => FullImageScreen(imagePath: ticket.imagePath!)));
                      },
                    ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(LucideIcons.edit3, color: AppTheme.textGrey, size: 18),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AddTicketScreen(ticket: ticket)));
                    },
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 18),
                    onPressed: () {
                      _showDeleteDialog(ticket);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildDetailItem(String label, String value, CrossAxisAlignment align) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 10, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildBarcode(String code, Color transportColor) {
    // Generate high fidelity simulated barcode columns
    final List<double> barWidths = [2, 4, 1.5, 3, 1, 5, 2, 1.5, 4, 3, 1, 2, 4, 1, 3, 5, 2, 1.5, 4, 3, 1, 2];

    return Column(
      children: [
        Container(
          height: 38,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              32,
              (index) {
                final width = barWidths[index % barWidths.length];
                final isSpace = index % 3 == 0;
                return Container(
                  width: width,
                  color: isSpace
                      ? Colors.transparent
                      : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          code,
          style: TextStyle(
            color: transportColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 4.0,
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.ticket, color: AppTheme.textGrey.withValues(alpha: 0.3), size: 48),
          const SizedBox(height: 16),
          Text(
            'No bookings found',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          const Text('Create tickets to easily view & show them', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTicketScreen()));
            },
            icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
            label: const Text('Add Your First Ticket', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(TicketItem ticket) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Booking?',
          style: TextStyle(
            color: Theme.of(ctx).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text('Are you sure you want to remove the ticket from ${ticket.boardingPointName} to ${ticket.destinationPointName}?',
            style: const TextStyle(color: AppTheme.textGrey)),
        actions: [
          TextButton(
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(ctx).brightness == Brightness.dark ? Colors.white54 : Colors.black54,
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () {
              context.read<TicketProvider>().deleteTicket(ticket.id);
              context.read<AuditLogProvider>().logAction('Booking', 'Deleted ticket PNR ${ticket.pnr}');
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ticket deleted successfully'),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CalendarSyncBottomSheet extends StatefulWidget {
  final VoidCallback onSyncComplete;
  const _CalendarSyncBottomSheet({required this.onSyncComplete});

  @override
  State<_CalendarSyncBottomSheet> createState() => _CalendarSyncBottomSheetState();
}

class _CalendarSyncBottomSheetState extends State<_CalendarSyncBottomSheet> {
  bool _isScanning = true;
  String _scanningStatus = 'Connecting to calendars...';
  List<CalendarEventItem> _events = [];
  final Map<String, bool> _selected = {};

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    // Stage 1: Connect
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _scanningStatus = 'Scanning Google Calendar (sandesh.reddy@gmail.com)...');

    // Stage 2: Apple Calendar
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _scanningStatus = 'Scanning Apple Calendar (iCloud Sync)...');

    // Stage 3: Extract
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _scanningStatus = 'Parsing ticket attachments & PNR references...');

    // Stage 4: Load
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    
    final allEvents = await CalendarSyncService.instance.fetchRealDeviceCalendarTickets(requestPermission: true);
    
    setState(() {
      _events = allEvents;
      for (var ev in allEvents) {
        _selected[ev.id] = true; // Checked by default
      }
      _isScanning = false;
    });
  }

  void _sync() {
    final provider = context.read<TicketProvider>();
    final audit = context.read<AuditLogProvider>();
    
    int importedCount = 0;
    for (var ev in _events) {
      if (_selected[ev.id] == true) {
        // Prevent duplicate sync based on PNR matching
        final exists = provider.tickets.any((t) => t.pnr == ev.pnr);
        if (!exists) {
          provider.addTicket(ev.toTicketItem());
          audit.logAction('CalendarSync', 'Auto-synced booking ${ev.operatorName} from ${ev.sourceCalendar} (PNR: ${ev.pnr})');
          importedCount++;
        }
      }
    }

    HapticFeedback.mediumImpact();
    Navigator.pop(context);
    widget.onSyncComplete();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(importedCount > 0 
            ? 'Successfully imported $importedCount new bookings from your calendar!' 
            : 'No new bookings to sync (already up-to-date)'),
        backgroundColor: AppTheme.primaryPurple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, 
        right: 24, 
        top: 16, 
        bottom: MediaQuery.of(context).viewInsets.bottom + 24
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.calendar, color: AppTheme.primaryPurple, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Smart Calendar Sync',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Automatically scrapes your linked calendars to import travel bookings directly into your wallet.',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
          ),
          const SizedBox(height: 24),

          // Scanning / Loading Area
          if (_isScanning)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryPurple,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _scanningStatus,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Discovered Events list
            if (_events.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      const Icon(LucideIcons.calendarX, color: AppTheme.textGrey, size: 40),
                      const SizedBox(height: 16),
                      const Text(
                        'No travel bookings discovered in calendars.',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ensure you have added travel events to your Google Calendar app and synced your phone.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textGrey, fontSize: 11),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SCAN DIAGNOSTICS',
                              style: TextStyle(color: AppTheme.primaryPurple, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                            ),
                            const SizedBox(height: 12),
                            _buildDiagnosticRow('Permissions Granted', CalendarSyncService.instance.permissionWasGranted ? 'Yes ✅' : 'No ❌'),
                            _buildDiagnosticRow('Calendars Scanned', '${CalendarSyncService.instance.calendarsScanned} accounts'),
                            if (CalendarSyncService.instance.scannedCalendarNames.isNotEmpty)
                              _buildDiagnosticRow('Scanned Accounts', CalendarSyncService.instance.scannedCalendarNames.join(', ')),
                            _buildDiagnosticRow('Events Evaluated', '${CalendarSyncService.instance.totalEventsEvaluated} events'),
                            if (CalendarSyncService.instance.lastError.isNotEmpty)
                              _buildDiagnosticRow('Last Error', CalendarSyncService.instance.lastError, isError: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              const Text('TRAVEL RESERVATIONS DETECTED', style: TextStyle(color: AppTheme.textGrey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, index) {
                    final ev = _events[index];
                    final isChecked = _selected[ev.id] == true;
                    
                    Color color = AppTheme.primaryPurple;
                    IconData icon = LucideIcons.plane;
                    if (ev.type == 'train') {
                      color = Colors.redAccent;
                      icon = LucideIcons.train;
                    } else if (ev.type == 'bus') {
                      color = Colors.greenAccent;
                      icon = LucideIcons.bus;
                    }

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isChecked,
                            activeColor: AppTheme.primaryPurple,
                            side: const BorderSide(color: Colors.white24, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (v) {
                              setState(() {
                                _selected[ev.id] = v ?? false;
                              });
                            },
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: color, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        ev.operatorName,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: ev.sourceCalendar == 'Google Calendar' 
                                            ? Colors.green.withValues(alpha: 0.15) 
                                            : Colors.blue.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        ev.sourceCalendar == 'Google Calendar' ? 'Google' : 'Apple',
                                        style: TextStyle(
                                          color: ev.sourceCalendar == 'Google Calendar' ? Colors.greenAccent : Colors.blueAccent, 
                                          fontSize: 9, 
                                          fontWeight: FontWeight.bold
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${ev.boardingPointName} ➔ ${ev.destinationPointName}  •  PNR: ${ev.pnr}',
                                  style: const TextStyle(color: AppTheme.textGrey, fontSize: 11),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('dd MMM yyyy, hh:mm a').format(ev.eventDate),
                                  style: const TextStyle(color: AppTheme.textGrey, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              
              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _sync,
                  icon: const Icon(LucideIcons.check, size: 18, color: Colors.black),
                  label: Text(
                    'Sync & Import Selected (${_selected.values.where((v) => v).length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDiagnosticRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(color: AppTheme.textGrey, fontSize: 11, fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isError ? Colors.redAccent : Colors.white70,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
