import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../models/bill_reminder.dart';
import '../providers/bill_reminder_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/audit_log_provider.dart';
import '../theme/app_theme.dart';

class BillRemindersScreen extends StatefulWidget {
  const BillRemindersScreen({super.key});

  @override
  State<BillRemindersScreen> createState() => _BillRemindersScreenState();
}

class _BillRemindersScreenState extends State<BillRemindersScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BillReminderProvider>();
    final reminders = provider.reminders;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Bill Reminders', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentGreen))
          : reminders.isEmpty
              ? const Center(
                  child: Text(
                    'No reminders set.',
                    style: TextStyle(color: AppTheme.textGrey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = reminders[index];
                    return _buildReminderCard(reminder, provider);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accentGreen,
        onPressed: () {
          context.read<AuditLogProvider>().logAction('Tap', 'Opened Add Bill Reminder sheet');
          _showAddReminderSheet(context, provider);
        },
        child: const Icon(LucideIcons.plus, color: Colors.black),
      ),
    );
  }

  Widget _buildReminderCard(BillReminder reminder, BillReminderProvider provider) {
    final now = DateTime.now();
    final difference = reminder.dueDate.difference(DateTime(now.year, now.month, now.day)).inDays;
    
    Color statusColor = AppTheme.textGrey;
    String statusText = '';
    
    if (reminder.isPaid) {
      statusColor = AppTheme.accentGreen;
      statusText = 'Paid';
    } else if (difference < 0) {
      statusColor = Colors.redAccent;
      statusText = 'Overdue';
    } else if (difference == 0) {
      statusColor = AppTheme.accentYellow;
      statusText = 'Due Today';
    } else {
      statusColor = Colors.blueAccent;
      statusText = 'Due in $difference days';
    }

    return Card(
      color: AppTheme.cardDark,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          reminder.billerName,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            decoration: reminder.isPaid ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('₹${reminder.amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 4),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.calendar, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat.yMMMd().add_jm().format(reminder.dueDate),
                        style: TextStyle(color: statusColor, fontSize: 12),
                      ),
                    ],
                  ),
                  Text('• $statusText', style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: reminder.isPaid,
              activeColor: AppTheme.accentGreen,
              onChanged: (val) {
                if (val != null) {
                  context.read<AuditLogProvider>().logAction('Tap', 'Marked bill as ${val ? "Paid" : "Unpaid"}: ${reminder.billerName}');
                  provider.updateReminder(reminder.copyWith(isPaid: val));
                }
              },
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 20),
              onPressed: () {
                context.read<AuditLogProvider>().logAction('Tap', 'Deleted bill reminder for: ${reminder.billerName}');
                provider.deleteReminder(reminder.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddReminderSheet(BuildContext context, BillReminderProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: const _AddReminderForm(),
      ),
    );
  }
}

class _AddReminderForm extends StatefulWidget {
  const _AddReminderForm();

  @override
  State<_AddReminderForm> createState() => _AddReminderFormState();
}

class _AddReminderFormState extends State<_AddReminderForm> {
  final _billerCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();

  DateTime get _finalDateTime => DateTime(
    _selectedDate.year,
    _selectedDate.month,
    _selectedDate.day,
    _selectedTime.hour,
    _selectedTime.minute,
  );

  void _showIosTimePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      builder: (BuildContext builder) {
        return SizedBox(
          height: 250,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done', style: TextStyle(color: AppTheme.accentGreen)),
                  )
                ],
              ),
              Expanded(
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: _finalDateTime,
                    onDateTimeChanged: (DateTime newDateTime) {
                      HapticFeedback.vibrate();
                      setState(() {
                        _selectedTime = TimeOfDay.fromDateTime(newDateTime);
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Add Reminder', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        TextField(
          controller: _billerCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Biller Name',
            labelStyle: const TextStyle(color: AppTheme.textGrey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _amountCtrl,
          style: const TextStyle(color: Colors.white),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Amount (₹)',
            labelStyle: const TextStyle(color: AppTheme.textGrey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Due Date', style: TextStyle(color: Colors.white70)),
            TextButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
              child: Text(
                DateFormat.yMMMd().format(_selectedDate),
                style: const TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Time', style: TextStyle(color: Colors.white70)),
            TextButton(
              onPressed: () => _showIosTimePicker(context),
              child: Text(
                _selectedTime.format(context),
                style: const TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              HapticFeedback.vibrate();
              final amount = double.tryParse(_amountCtrl.text.trim());
              final biller = _billerCtrl.text.trim();
              if (biller.isNotEmpty && amount != null && amount > 0) {
                final reminder = BillReminder(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  billerName: biller,
                  amount: amount,
                  dueDate: _finalDateTime,
                );
                final provider = context.read<BillReminderProvider>();
                context.read<AuditLogProvider>().logAction('Tap', 'Saved new bill reminder for $biller (₹$amount)');
                provider.addReminder(reminder);
                if (mounted) {
                  provider.checkDueReminders(context.read<NotificationProvider>());
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Save Reminder', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
