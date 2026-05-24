import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';
import '../models/notification_item.dart';
import '../theme/app_theme.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (provider.hasUnread)
                  TextButton(
                    onPressed: () => provider.markAllRead(),
                    child: Text(
                      'Mark all as read',
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: notifications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      return _buildNotificationItem(context, item, provider);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(LucideIcons.bellOff, size: 64, color: AppTheme.textGrey.withValues(alpha: 0.3)),
        const SizedBox(height: 16),
        const Text(
          'All caught up!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          'No new notifications at the moment.',
          style: TextStyle(color: AppTheme.textGrey),
        ),
      ],
    );
  }

  Widget _buildNotificationItem(
      BuildContext context, NotificationItem item, NotificationProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: item.isRead 
            ? Colors.transparent 
            : Theme.of(context).cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: item.isRead
            ? Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.05))
            : Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2), width: 1.2),
        boxShadow: item.isRead ? null : [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        leading: _buildTypeIcon(item.type),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                  color: item.isRead 
                      ? Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.6) 
                      : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            if (!item.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.accentGreen,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              item.message,
              style: TextStyle(
                color: item.isRead 
                    ? AppTheme.textGrey 
                    : Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.8),
                fontSize: 13,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatTimestamp(item.timestamp),
              style: const TextStyle(color: AppTheme.textGrey, fontSize: 11),
            ),
          ],
        ),
        onTap: () => provider.markAsRead(item.id),
      ),
    );
  }

  Widget _buildTypeIcon(String type) {
    IconData icon;
    List<Color> gradient;

    switch (type) {
      case 'transaction':
        icon = LucideIcons.arrowDownLeft;
        gradient = [const Color(0xFF11998e), const Color(0xFF38ef7d)]; // Mint Teal
        break;
      case 'security':
        icon = LucideIcons.shieldAlert;
        gradient = [const Color(0xFFFF6B00), const Color(0xFFFFB800)]; // Neon Sunset
        break;
      case 'system':
        icon = LucideIcons.settings;
        gradient = [const Color(0xFF8A2387), const Color(0xFFE94057)]; // Cosmic Magenta
        break;
      default:
        icon = LucideIcons.bell;
        gradient = [const Color(0xFF7C3AED), const Color(0xFF6366F1)]; // Indigo Purple
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM dd').format(dt);
  }
}
