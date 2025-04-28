class Reminder {
  int? id;
  String title;
  String description;
  DateTime scheduledTime;
  bool isRepeating;
  int? repeatInterval;
  DateTime? createdAt;
  DateTime? updatedAt;

  Reminder({
    this.id,
    required this.title,
    this.description = '',
    required this.scheduledTime,
    this.isRepeating = false,
    this.repeatInterval,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'scheduled_at': scheduledTime.millisecondsSinceEpoch,
      'is_repeating': isRepeating ? 1 : 0,
      'repeat_interval': repeatInterval,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      scheduledTime:
          DateTime.fromMillisecondsSinceEpoch(map['scheduled_at'] as int),
      isRepeating: (map['is_repeating'] as int) == 1,
      repeatInterval: map['repeat_interval'] as int?,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : null,
    );
  }
}
