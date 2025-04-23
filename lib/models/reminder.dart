import 'package:flutter/material.dart';

class Reminder {
  int? id;
  String title;
  String? description;
  DateTime scheduledTime;
  bool isRepeating;
  String? repeatInterval; // e.g. 'daily', 'weekly', etc.

  Reminder({
    this.id,
    required this.title,
    this.description,
    required this.scheduledTime,
    this.isRepeating = false,
    this.repeatInterval,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'scheduledTime': scheduledTime.toIso8601String(),
      'isRepeating': isRepeating ? 1 : 0,
      'repeatInterval': repeatInterval,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      scheduledTime: DateTime.parse(map['scheduledTime']),
      isRepeating: map['isRepeating'] == 1,
      repeatInterval: map['repeatInterval'],
    );
  }
}
