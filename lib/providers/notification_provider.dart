import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/notification_model.dart';
import '../database/notification_db.dart';

/// A provider managing app notifications with persistence and undo support.
class NotificationProvider extends ChangeNotifier {
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
      debugPrint('Error fetching notifications: \$e');
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
      payload: payload, // <-- now correct type
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
