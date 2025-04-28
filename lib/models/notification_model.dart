import 'dart:convert';

/// Defines the types of notifications in the app.
enum NotificationType { info, error, reminder, system }

/// Extension to convert NotificationType to/from a short string for serialization.
extension NotificationTypeExtension on NotificationType {
  /// Returns the enum value as a simple string (e.g. "info").
  String toShortString() => toString().split('.').last;

  /// Parses a short string back into a NotificationType, defaults to info.
  static NotificationType fromString(String type) {
    return NotificationType.values.firstWhere(
      (e) => e.toShortString() == type,
      orElse: () => NotificationType.info,
    );
  }
}

/// Model class representing an app notification, with persistence helpers.
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  bool read;
  final String? routeName;
  final Map<String, dynamic>? payload;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.read = false,
    this.routeName,
    this.payload,
  });

  /// Creates an AppNotification from a map (e.g., DB row).
  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      type: NotificationTypeExtension.fromString(map['type'] as String),
      title: map['title'] as String,
      message: map['message'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      read: (map['read'] as int) == 1,
      routeName: map['routeName'] as String?,
      payload: map['payload'] != null
          ? jsonDecode(map['payload'] as String) as Map<String, dynamic>
          : null,
    );
  }

  /// Converts this AppNotification into a map for persistence.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toShortString(),
      'title': title,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'read': read ? 1 : 0,
      'routeName': routeName,
      'payload': payload != null ? jsonEncode(payload) : null,
    };
  }
}
