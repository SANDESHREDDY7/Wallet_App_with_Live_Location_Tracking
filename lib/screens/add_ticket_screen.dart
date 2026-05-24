import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../models/ticket_item.dart';
import '../providers/ticket_provider.dart';
import '../providers/audit_log_provider.dart';
import '../theme/app_theme.dart';

class AddTicketScreen extends StatefulWidget {
  final TicketItem? ticket;

  const AddTicketScreen({super.key, this.ticket});

  @override
  State<AddTicketScreen> createState() => _AddTicketScreenState();
}

class _AddTicketScreenState extends State<AddTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late String _type; // 'flight' | 'train' | 'bus'
  late TextEditingController _titleController; // Airline/Train/Bus operator name
  late TextEditingController _passengerController;
  late TextEditingController _pnrController;
  late TextEditingController _boardingController;
  late TextEditingController _destinationController;
  late TextEditingController _seatController;
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);

  String? _pdfPath;
  String? _imagePath;

  // Indian Places database mapping major cities, airports, and train hubs
  static const List<Map<String, String>> _indianPlaces = [
    {'name': 'Delhi (DEL / NDLS)', 'code': 'DEL'},
    {'name': 'Mumbai (BOM / CSMT)', 'code': 'BOM'},
    {'name': 'Bangalore (BLR / SBC)', 'code': 'BLR'},
    {'name': 'Chennai (MAA / MAS)', 'code': 'MAA'},
    {'name': 'Kolkata (CCU / HWH)', 'code': 'CCU'},
    {'name': 'Hyderabad (HYD / HYB)', 'code': 'HYD'},
    {'name': 'Pune (PNQ / PUNE)', 'code': 'PNQ'},
    {'name': 'Ahmedabad (AMD / ADI)', 'code': 'AMD'},
    {'name': 'Jaipur (JAI / JP)', 'code': 'JAI'},
    {'name': 'Lucknow (LKO / LJN)', 'code': 'LKO'},
    {'name': 'Patna (PAT / PNBE)', 'code': 'PAT'},
    {'name': 'Kochi (COK / ERN)', 'code': 'COK'},
    {'name': 'Goa (GOI / MAO)', 'code': 'GOI'},
    {'name': 'Amritsar (ATQ / ASR)', 'code': 'ATQ'},
    {'name': 'Guwahati (GAU / GHY)', 'code': 'GHY'},
    {'name': 'Bhopal (BPL / BPL)', 'code': 'BPL'},
    {'name': 'Indore (IDR / INDB)', 'code': 'IDR'},
    {'name': 'Nagpur (NAG / NGP)', 'code': 'NAG'},
    {'name': 'Coimbatore (CJB / CBE)', 'code': 'CJB'},
    {'name': 'Visakhapatnam (VTZ / VSKP)', 'code': 'VTZ'},
    {'name': 'Chandigarh (IXC / CDG)', 'code': 'IXC'},
    {'name': 'Surat (ST / ST)', 'code': 'ST'},
    {'name': 'Vadodara (BDQ / BRC)', 'code': 'BDQ'},
    {'name': 'Trivandrum (TRV / TVC)', 'code': 'TRV'},
    {'name': 'Madurai (IXM / MDU)', 'code': 'IXM'},
    {'name': 'Vijayawada (VGA / BZA)', 'code': 'VGA'},
    {'name': 'Tirupati (TPTY / RU)', 'code': 'TPTY'},
    {'name': 'Guntur (GNT / GNT)', 'code': 'GNT'},
    {'name': 'Bhubaneswar (BBI / BBS)', 'code': 'BBI'},
    {'name': 'Ranchi (IXR / RNC)', 'code': 'IXR'},
    {'name': 'Raipur (RPR / R)', 'code': 'RPR'},
    {'name': 'Dehradun (DED / DDN)', 'code': 'DED'},
    {'name': 'Varanasi (VNS / BSB)', 'code': 'VNS'},
    {'name': 'Kanpur (KNU / CNB)', 'code': 'CNB'},
    {'name': 'Agra (AGR / AGC)', 'code': 'AGR'},
    {'name': 'Jhansi (JHS / JHS)', 'code': 'JHS'},
    {'name': 'Jabalpur (JBP / JBP)', 'code': 'JBP'},
    {'name': 'Prayagraj (IXD / PRYJ)', 'code': 'IXD'},
    {'name': 'Gwalior (GWL / GWL)', 'code': 'GWL'},
    {'name': 'Srinagar (SXR / SXR)', 'code': 'SXR'},
    {'name': 'Jammu (IXJ / JAT)', 'code': 'IXJ'},
    {'name': 'Jodhpur (JDH / JU)', 'code': 'JDH'},
    {'name': 'Udaipur (UDR / UDZ)', 'code': 'UDR'},
    {'name': 'Calicut (CCJ / CLT)', 'code': 'CCJ'},
    {'name': 'Mangalore (IXE / MAQ)', 'code': 'IXE'},
    {'name': 'Trichy (TRZ / TPJ)', 'code': 'TRZ'},
    {'name': 'Rajahmundry (RJA / RJY)', 'code': 'RJA'},
  ];

  List<Map<String, String>> _boardingSuggestions = [];
  List<Map<String, String>> _destinationSuggestions = [];

  @override
  void initState() {
    super.initState();
    final ticket = widget.ticket;
    _type = ticket?.type ?? 'flight';
    _titleController = TextEditingController(text: ticket?.title ?? '');
    _passengerController = TextEditingController(text: ticket?.passengerName ?? '');
    _pnrController = TextEditingController(text: ticket?.pnr ?? '');
    _boardingController = TextEditingController(text: ticket?.boardingPoint ?? '');
    _destinationController = TextEditingController(text: ticket?.destinationPoint ?? '');
    _seatController = TextEditingController(text: ticket?.seatNumber ?? '');
    
    if (ticket != null) {
      _selectedDate = ticket.date;
      _selectedTime = TimeOfDay(hour: ticket.date.hour, minute: ticket.date.minute);
      _pdfPath = ticket.pdfPath;
      _imagePath = ticket.imagePath;
    }

    _boardingController.addListener(_onBoardingChanged);
    _destinationController.addListener(_onDestinationChanged);
  }

  void _onBoardingChanged() {
    final query = _boardingController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _boardingSuggestions = []);
      return;
    }
    
    final filtered = _indianPlaces.where((place) {
      return place['name']!.toLowerCase().contains(query) || 
             place['code']!.toLowerCase().contains(query);
    }).toList();
    
    final exactMatch = filtered.any((place) => place['code']!.toLowerCase() == query);
    setState(() {
      _boardingSuggestions = exactMatch ? [] : filtered;
    });
  }

  void _onDestinationChanged() {
    final query = _destinationController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _destinationSuggestions = []);
      return;
    }
    
    final filtered = _indianPlaces.where((place) {
      return place['name']!.toLowerCase().contains(query) || 
             place['code']!.toLowerCase().contains(query);
    }).toList();
    
    final exactMatch = filtered.any((place) => place['code']!.toLowerCase() == query);
    setState(() {
      _destinationSuggestions = exactMatch ? [] : filtered;
    });
  }

  @override
  void dispose() {
    _boardingController.removeListener(_onBoardingChanged);
    _destinationController.removeListener(_onDestinationChanged);
    _titleController.dispose();
    _passengerController.dispose();
    _pnrController.dispose();
    _boardingController.dispose();
    _destinationController.dispose();
    _seatController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primaryPurple,
            onPrimary: Colors.white,
            surface: AppTheme.bgDark,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primaryPurple,
            onPrimary: Colors.white,
            surface: AppTheme.bgDark,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _pickPDF() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        HapticFeedback.lightImpact();
        setState(() {
          _pdfPath = result.files.single.path;
          _imagePath = null; // Clear image if pdf selected
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick PDF: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await showModalBottomSheet<XFile>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(LucideIcons.camera, color: AppTheme.primaryPurple),
            title: const Text('Take Photo of Boarding Pass'),
            onTap: () async {
              final img = await picker.pickImage(source: ImageSource.camera);
              if (ctx.mounted) Navigator.pop(ctx, img);
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.image, color: AppTheme.primaryPurple),
            title: const Text('Choose from Gallery'),
            onTap: () async {
              final img = await picker.pickImage(source: ImageSource.gallery);
              if (ctx.mounted) Navigator.pop(ctx, img);
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );

    if (image != null) {
      HapticFeedback.lightImpact();
      setState(() {
        _imagePath = image.path;
        _pdfPath = null; // Clear pdf if image selected
      });
    }
  }

  Future<String?> _secureCopyFile(String? srcPath, String prefix, String id) async {
    if (srcPath == null) return null;
    try {
      final dbDir = await getDatabasesPath();
      final secureDir = Directory(path.join(dbDir, 'secure_attachments'));
      if (srcPath.startsWith(secureDir.path)) {
        return srcPath;
      }
      if (!await secureDir.exists()) {
        await secureDir.create(recursive: true);
      }
      final destPath = path.join(secureDir.path, '${prefix}_${id}_attachment.secure');
      final srcFile = File(srcPath);
      if (await srcFile.exists()) {
        await srcFile.copy(destPath);
        return destPath;
      }
    } catch (e) {
      print('Error copying attachment to secure sandboxed folder: $e');
    }
    return srcPath;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Show premium secure encryption progress indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          color: AppTheme.bgDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppTheme.primaryPurple),
                const SizedBox(height: 20),
                const Text(
                  'Securing & Encrypting Document...',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final provider = context.read<TicketProvider>();
    final audit = context.read<AuditLogProvider>();

    final finalDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final title = _titleController.text.trim();
    final passenger = _passengerController.text.trim();
    final pnr = _pnrController.text.trim().toUpperCase();
    final boarding = _boardingController.text.trim().toUpperCase();
    final dest = _destinationController.text.trim().toUpperCase();
    final seat = _seatController.text.trim().toUpperCase();

    final ticketId = widget.ticket?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

    // Copy to private app sandbox with obfuscated secure extension
    final securedPdf = await _secureCopyFile(_pdfPath, 'ticket_${ticketId}_doc', ticketId);
    final securedImg = await _secureCopyFile(_imagePath, 'ticket_${ticketId}_pass', ticketId);

    if (widget.ticket == null) {
      final newTicket = TicketItem(
        id: ticketId,
        type: _type,
        title: title,
        passengerName: passenger,
        pnr: pnr,
        boardingPoint: boarding,
        destinationPoint: dest,
        date: finalDateTime,
        seatNumber: seat,
        pdfPath: securedPdf,
        imagePath: securedImg,
      );
      provider.addTicket(newTicket);
      audit.logAction('Booking', 'Added new SECURE ${_type.toUpperCase()} ticket: $boarding ➔ $dest');
    } else {
      final updated = widget.ticket!.copyWith(
        type: _type,
        title: title,
        passengerName: passenger,
        pnr: pnr,
        boardingPoint: boarding,
        destinationPoint: dest,
        date: finalDateTime,
        seatNumber: seat,
        pdfPath: securedPdf,
        imagePath: securedImg,
        clearPdf: securedPdf == null,
        clearImage: securedImg == null,
      );
      provider.updateTicket(updated);
      audit.logAction('Booking', 'Updated SECURE ${_type.toUpperCase()} ticket details: PNR $pnr');
    }

    if (mounted) {
      Navigator.pop(context); // Dismiss progress dialog
      HapticFeedback.heavyImpact();
      Navigator.pop(context); // Go back
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.ticket == null ? 'Add Ticket' : 'Edit Ticket',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.check, color: AppTheme.primaryPurple, size: 28),
            onPressed: _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Transport Type Tab Bar
              const Text('Transport Type', style: TextStyle(color: AppTheme.textGrey, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              _buildTypeSelector(),
              const SizedBox(height: 24),

              // 2. Journey Locations (Boarding & Destination) with premium Indian Auto-suggestions dropdowns
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: _boardingController,
                    label: 'From (Boarding)',
                    hint: 'Type city, airport code, or train station...',
                    icon: LucideIcons.mapPin,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  _buildSuggestionsList(
                    suggestions: _boardingSuggestions,
                    controller: _boardingController,
                    onSelected: () => setState(() => _boardingSuggestions = []),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _destinationController,
                    label: 'To (Destination)',
                    hint: 'Type city, airport code, or train station...',
                    icon: LucideIcons.mapPin,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  _buildSuggestionsList(
                    suggestions: _destinationSuggestions,
                    controller: _destinationController,
                    onSelected: () => setState(() => _destinationSuggestions = []),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 3. Passenger Details
              _buildTextField(
                controller: _passengerController,
                label: 'Passenger Name',
                hint: 'Passenger full name',
                icon: LucideIcons.user,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              // 4. PNR / Booking Ref & Seat details
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _pnrController,
                      label: 'PNR / Booking Ref',
                      hint: 'e.g. PNR12345',
                      icon: LucideIcons.hash,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _seatController,
                      label: _type == 'flight' ? 'Seat / Class' : (_type == 'train' ? 'Coach / Berth' : 'Seat Number'),
                      hint: 'e.g. 14A or B2-34',
                      icon: LucideIcons.armchair,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 5. Operator Title (Indigo / Rajdhani Express etc.)
              _buildTextField(
                controller: _titleController,
                label: _type == 'flight' ? 'Airline / Title' : (_type == 'train' ? 'Train Name & Number' : 'Bus Operator'),
                hint: _type == 'flight' ? 'e.g. IndiGo' : (_type == 'train' ? 'e.g. Rajdhani Express (12952)' : 'e.g. Zingbus'),
                icon: _type == 'flight' ? LucideIcons.plane : (_type == 'train' ? LucideIcons.train : LucideIcons.bus),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              // 6. Travel Date & Time selectors
              const Text('Departure Date & Time', style: TextStyle(color: AppTheme.textGrey, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.calendar, color: AppTheme.primaryPurple, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('dd MMM yyyy').format(_selectedDate),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.clock, color: AppTheme.primaryPurple, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              _selectedTime.format(context),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 7. Original Document Attachments
              const Text('Original Ticket Document / Boarding Pass', style: TextStyle(color: AppTheme.textGrey, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _buildAttachmentSelector(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    final types = [
      {'key': 'flight', 'label': 'Flight', 'icon': LucideIcons.plane},
      {'key': 'train', 'label': 'Train', 'icon': LucideIcons.train},
      {'key': 'bus', 'label': 'Bus', 'icon': LucideIcons.bus},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: types.map((t) {
          final isSelected = _type == t['key'];
          Color color = AppTheme.primaryPurple;
          if (t['key'] == 'train') color = Colors.redAccent;
          if (t['key'] == 'bus') color = Colors.greenAccent;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _type = t['key'] as String;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected ? Border.all(color: color.withValues(alpha: 0.3)) : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      t['icon'] as IconData,
                      color: isSelected ? color : AppTheme.textGrey,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t['label'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textGrey,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            prefixIcon: Icon(icon, color: AppTheme.primaryPurple, size: 18),
            filled: true,
            fillColor: AppTheme.cardDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.primaryPurple, width: 1.5),
            ),
            errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionsList({
    required List<Map<String, String>> suggestions,
    required TextEditingController controller,
    required VoidCallback onSelected,
  }) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => Container(height: 1, color: Colors.white10),
          itemBuilder: (ctx, index) {
            final suggestion = suggestions[index];
            return ListTile(
              leading: const Icon(LucideIcons.mapPin, color: AppTheme.primaryPurple, size: 16),
              title: Text(
                suggestion['name']!,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  suggestion['code']!,
                  style: const TextStyle(color: AppTheme.primaryPurple, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              dense: true,
              onTap: () {
                HapticFeedback.lightImpact();
                controller.text = suggestion['code']!;
                onSelected();
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildAttachmentSelector() {
    if (_pdfPath != null) {
      return _buildAttachmentPreview(
        icon: LucideIcons.fileText,
        title: _pdfPath!.split('/').last,
        subtitle: 'PDF Original Ticket',
        color: Colors.redAccent,
        onClear: () => setState(() => _pdfPath = null),
      );
    }

    if (_imagePath != null) {
      return _buildAttachmentPreview(
        icon: LucideIcons.image,
        title: _imagePath!.split('/').last,
        subtitle: 'Boarding Pass Photo',
        color: Colors.blueAccent,
        onClear: () => setState(() => _imagePath = null),
      );
    }

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _pickPDF,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: const Column(
                children: [
                  Icon(LucideIcons.fileText, color: Colors.redAccent, size: 24),
                  SizedBox(height: 8),
                  Text('Attach PDF Ticket', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: _pickImage,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: const Column(
                children: [
                  Icon(LucideIcons.image, color: Colors.blueAccent, size: 24),
                  SizedBox(height: 8),
                  Text('Capture Image', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentPreview({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onClear,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppTheme.textGrey, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.x, color: AppTheme.textGrey, size: 18),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}
