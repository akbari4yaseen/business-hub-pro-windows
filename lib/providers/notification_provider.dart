import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import 'package:uuid/uuid.dart';

class NotificationProvider extends ChangeNotifier {
  final List<AppNotification> _notifications = [];
  final _uuid = Uuid();

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.read).length;

  void addNotification({
    required NotificationType type,
    required String title,
    required String message,
  }) {
    final notification = AppNotification(
      id: _uuid.v4(),
      type: type,
      title: title,
      message: message,
      timestamp: DateTime.now(),
    );
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void markAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !_notifications[idx].read) {
      _notifications[idx].read = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (final n in _notifications) {
      n.read = true;
    }
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}
