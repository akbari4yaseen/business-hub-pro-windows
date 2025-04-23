import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';

class NotificationsScreen extends StatelessWidget {
  static const routeName = '/notifications';

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (ctx) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Notifications'),
            actions: [
              IconButton(
                icon: const Icon(Icons.done_all),
                tooltip: 'Mark all as read',
                onPressed: () {
                  final provider = Provider.of<NotificationProvider>(ctx, listen: false);
                  provider.markAllAsRead();
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: 'Clear all',
                onPressed: () => _showClearDialog(ctx),
              ),
            ],
          ),
          body: Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              final notifications = provider.notifications;
              if (notifications.isEmpty) {
                return const Center(child: Text('No notifications'));
              }
              return ListView.separated(
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final n = notifications[i];
                  return ListTile(
                    leading: Icon(_iconForType(n.type), color: n.read ? Colors.grey : Theme.of(context).colorScheme.primary),
                    title: Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.normal : FontWeight.bold)),
                    subtitle: Text(n.message),
                    trailing: n.read ? null : Icon(Icons.circle, color: Colors.redAccent, size: 10),
                    onTap: () => provider.markAsRead(n.id),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('Clear'),
            onPressed: () {
              context.read<NotificationProvider>().clearAll();
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.reminder:
        return Icons.notifications_active_outlined;
      case NotificationType.system:
        return Icons.settings;
      default:
        return Icons.notifications_none;
    }
  }
}
