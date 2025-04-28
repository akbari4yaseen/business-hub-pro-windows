import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../providers/notification_provider.dart';
import '../models/notification_model.dart';

class NotificationsScreen extends StatelessWidget {
  static const routeName = '/notifications';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.notificationsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: loc.markAllReadTooltip,
            onPressed: () async {
              await context.read<NotificationProvider>().markAllAsRead();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: loc.clearAllNotificationsTitle,
            onPressed: () => _showClearDialog(context, loc),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (ctx, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: provider.fetchNotifications,
            child: provider.notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.notifications_off,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          loc.noNotifications,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: provider.notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final n = provider.notifications[i];
                      return Dismissible(
                        key: ValueKey(n.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.redAccent,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (_) async {
                          await provider.deleteNotification(n.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(loc.notificationDeleted),
                              action: SnackBarAction(
                                label: loc.undo,
                                onPressed: () async {
                                  await provider.restoreNotification(n);
                                },
                              ),
                            ),
                          );
                        },
                        child: ListTile(
                          leading: Icon(
                            _iconForType(n.type),
                            color: n.read
                                ? Colors.grey
                                : Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(
                            n.title,
                            style: TextStyle(
                              fontWeight:
                                  n.read ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.message),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM dd, yyyy – hh:mm a')
                                    .format(n.timestamp.toLocal()),
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          onTap: () async {
                            await provider.markAsRead(n.id);
                            if (n.routeName != null) {
                              Navigator.pushNamed(
                                context,
                                n.routeName!,
                                arguments: n.payload,
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  void _showClearDialog(BuildContext context, AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.clearAllNotificationsTitle),
        content: Text(loc.clearAllNotificationsContent),
        actions: [
          TextButton(
            child: Text(loc.cancel),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: Text(loc.clear),
            onPressed: () async {
              await context.read<NotificationProvider>().clearAll();
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
