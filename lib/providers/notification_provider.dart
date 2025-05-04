import 'dart:collection';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../database/settings_db.dart';
import '../models/notification_model.dart';
import '../database/notification_db.dart';
import '../database/account_db.dart';

/// A provider managing app notifications with persistence and undo support.
class NotificationProvider extends ChangeNotifier {
  /// Checks last backup times and adds a notification if either backup is overdue (>7 days).
  /// Requires a BuildContext to access localized strings.
  Future<void> checkBackupNotifications(BuildContext context) async {
    // Use the actual current time in the device's local timezone:
    final now = DateTime.now();

    // Fetch last backup timestamps (stored as ISO-8601 strings)
    final lastOnlineStr =
        await SettingsDBHelper().getSetting('lastOnlineBackup');
    final lastOfflineStr =
        await SettingsDBHelper().getSetting('lastOfflineBackup');

    DateTime? lastOnline;
    DateTime? lastOffline;

    if (lastOnlineStr != null) {
      try {
        // Parse and convert to local time
        lastOnline = DateTime.parse(lastOnlineStr).toLocal();
      } catch (e) {
        // ignore parse errors
      }
    }

    if (lastOfflineStr != null) {
      try {
        lastOffline = DateTime.parse(lastOfflineStr).toLocal();
      } catch (e) {
        // ignore parse errors
      }
    }

    // Check if more than 7 days have passed since last backup
    bool onlineOverdue =
        lastOnline == null || now.difference(lastOnline) > Duration(days: 7);
    bool offlineOverdue =
        lastOffline == null || now.difference(lastOffline) > Duration(days: 7);

    final loc = AppLocalizations.of(context)!;

    // Helper to avoid duplicate unread notifications by title
    bool alreadyNotified(String title) =>
        _notifications.any((n) => n.title == title && !n.read);

    if (onlineOverdue && !alreadyNotified(loc.onlineBackupOverdueTitle)) {
      await addNotification(
        type: NotificationType.system,
        title: loc.onlineBackupOverdueTitle,
        message: loc.onlineBackupOverdueMessage,
      );
    }

    if (offlineOverdue && !alreadyNotified(loc.offlineBackupOverdueTitle)) {
      await addNotification(
        type: NotificationType.system,
        title: loc.offlineBackupOverdueTitle,
        message: loc.offlineBackupOverdueMessage,
      );
    }
  }

  /// Check for accounts with no transactions in the past [days] days,
  /// and push a notification for each one you haven’t already alerted on.
  Future<void> checkInactiveAccountNotifications(
    BuildContext context, {
    int days = 30,
  }) async {
    final loc = AppLocalizations.of(context)!;

    // 1) Find all accounts inactive since [days] ago:
    final inactiveAccounts =
        await AccountDBHelper().getAccountsNoTransactionsSince(days: days);

    // 2) Helper to avoid duplicate alerts per account:
    bool alreadyNotified(String accountId) => _notifications
        .any((n) => n.payload?['accountId'] == accountId && !n.read);

    // 3) For each stale account, add a notification if we haven’t yet:
    for (final acct in inactiveAccounts) {
      final accountId = acct['id'].toString();
      if (alreadyNotified(accountId)) continue;

      final accountName = acct['name'] as String? ?? 'Account #$accountId';
      final title = loc.accountInactiveTitle(accountName);
      final message = loc.accountInactiveMessage(days, accountName);

      await addNotification(
        type: NotificationType.system,
        title: title,
        message: message,
        routeName: "/accounts",
        payload: {'accountId': accountId},
      );
    }
  }

  final List<AppNotification> _notifications = [];
  final Uuid _uuid = Uuid();
  final NotificationDB _db = NotificationDB();

  bool _isLoading = false;
  AppNotification? _lastRemoved;
  int? _lastRemovedIndex;

  bool get isLoading => _isLoading;
  UnmodifiableListView<AppNotification> get notifications =>
      UnmodifiableListView(_notifications);
  int get unreadCount => _notifications.where((n) => !n.read).length;

  /// Fetch notifications from local DB.
  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final items = await _db.fetchAll();
      _notifications
        ..clear()
        ..addAll(items);
    } catch (e) {
      // debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new notification (persisted and in-memory).
  Future<void> addNotification({
    required NotificationType type,
    required String title,
    required String message,
    String? routeName,
    Map<String, dynamic>? payload,
  }) async {
    final notification = AppNotification(
      id: _uuid.v4(),
      type: type,
      title: title,
      message: message,
      timestamp: DateTime.now(),
      routeName: routeName,
      payload: payload,
    );
    await _db.insert(notification);
    _notifications.insert(0, notification);
    notifyListeners();
  }

  /// Mark a single notification as read (persisted).
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].read) {
      _notifications[index].read = true;
      await _db.updateRead(id, true);
      notifyListeners();
    }
  }

  /// Mark all notifications as read (persisted).
  Future<void> markAllAsRead() async {
    final toMark = _notifications.where((n) => !n.read).toList();
    for (var n in toMark) {
      n.read = true;
      await _db.updateRead(n.id, true);
    }
    if (toMark.isNotEmpty) notifyListeners();
  }

  /// Delete a notification and store it for undo (persisted).
  Future<void> deleteNotification(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _lastRemoved = _notifications.removeAt(index);
      _lastRemovedIndex = index;
      await _db.delete(id);
      notifyListeners();
    }
  }

  /// Count unread notifications directly from the database.
  Future<int> countUnread() async {
    try {
      return await _db.countUnread();
    } catch (e) {
      // debugPrint('Error counting unread notifications: $e');
      // Fallback to in-memory count if DB query fails
      return unreadCount;
    }
  }

  /// Restore the last removed notification (persisted).
  Future<void> restoreNotification(AppNotification notification) async {
    if (_lastRemoved != null &&
        _lastRemoved!.id == notification.id &&
        _lastRemovedIndex != null) {
      await _db.insert(notification);
      _notifications.insert(_lastRemovedIndex!, notification);
      _lastRemoved = null;
      _lastRemovedIndex = null;
      notifyListeners();
    }
  }

  /// Clear all notifications (persisted) and reset undo state.
  Future<void> clearAll() async {
    if (_notifications.isNotEmpty) {
      _notifications.clear();
      await _db.clearAll();
      _lastRemoved = null;
      _lastRemovedIndex = null;
      notifyListeners();
    }
  }
}
