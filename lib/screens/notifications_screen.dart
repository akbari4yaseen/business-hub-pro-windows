import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../providers/notification_provider.dart';
import '../models/notification_model.dart';
import '../utils/date_formatters.dart';

class NotificationsScreen extends StatelessWidget {
  static const routeName = '/notifications';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.notificationsTitle),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: loc.markAllReadTooltip,
            onPressed: () =>
                context.read<NotificationProvider>().markAllAsRead(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
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
                ? _EmptyState(loc)
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    itemCount: provider.notifications.length,
                    itemBuilder: (context, i) {
                      final n = provider.notifications[i];
                      return _NotificationCard(notification: n);
                    },
                  ),
          );
        },
      ),
    );
  }

  void _showClearDialog(BuildContext context, AppLocalizations loc) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.clearAllNotificationsTitle,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Text(loc.clearAllNotificationsContent, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  child: Text(loc.cancel),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: Text(loc.clear),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    await context.read<NotificationProvider>().clearAll();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppLocalizations loc;
  const _EmptyState(this.loc);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(loc.noNotifications,
              style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<NotificationProvider>();
    final theme = Theme.of(context);
    final isUnread = !notification.read;
    final timestamp =
        formatLocalizedDateTime(context, notification.timestamp.toString());

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        await provider.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.notificationDeleted),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.undo,
              onPressed: () => provider.restoreNotification(notification),
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: isUnread ? 3 : 1,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isUnread
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : Colors.grey.shade200,
                child: Icon(
                  _iconForType(notification.type),
                  color: isUnread
                      ? theme.colorScheme.primary
                      : Colors.grey.shade600,
                ),
              ),
              if (isUnread)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            notification.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(notification.message, style: theme.textTheme.labelMedium),
              const SizedBox(height: 6),
              Text(timestamp, style: theme.textTheme.bodySmall),
            ],
          ),
          onTap: () async {
            await provider.markAsRead(notification.id);
            if (notification.routeName != null) {
              Navigator.pushNamed(context, notification.routeName!,
                  arguments: notification.payload);
            }
          },
        ),
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
