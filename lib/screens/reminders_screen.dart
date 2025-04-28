import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder.dart';
import '../database/reminder_db.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({Key? key}) : super(key: key);

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  late Future<List<Reminder>> _remindersFuture;
  final _notifications = FlutterLocalNotificationsPlugin();

  // Define your channel once
  static const AndroidNotificationChannel _reminderChannel =
      AndroidNotificationChannel(
    'reminders_channel',
    'Reminders',
    description: 'Reminder notifications',
    importance: Importance.max,
  );

  @override
  void initState() {
    super.initState();

    // 1️⃣ Initialize IANA tz database
    tz.initializeTimeZones();

    // 2️⃣ Initialize notifications & permissions
    _initializeNotifications();

    // 3️⃣ Load existing reminders
    _loadReminders();
  }

  Future<void> _initializeNotifications() async {
    // a) Create channel & request any runtime perms on Android
    final androidImpl = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      // Create (or update) the channel
      await androidImpl.createNotificationChannel(_reminderChannel);

      // Android 13+ — request POST_NOTIFICATIONS
      final granted = await androidImpl.requestNotificationsPermission();
      if (granted == false) {
        debugPrint('❗️ Notification permission declined');
      }
    }

    // b) Finally initialize the plugin
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _notifications.initialize(initSettings);
  }

  void _loadReminders() {
    setState(() {
      _remindersFuture = ReminderDB().getReminders();
    });
  }

  Future<void> _scheduleNotification(Reminder r) async {
    if (r.scheduledTime.isBefore(DateTime.now())) return;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _reminderChannel.id,
        _reminderChannel.name,
        channelDescription: _reminderChannel.description,
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    if (r.isRepeating && r.repeatInterval != null) {
      final interval = (r.repeatInterval! == Duration(days: 7).inMilliseconds)
          ? RepeatInterval.weekly
          : RepeatInterval.daily;

      await _notifications.periodicallyShow(
        r.id!,
        r.title,
        r.description.isNotEmpty ? r.description : 'Time for your reminder!',
        interval,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } else {
      await _notifications.zonedSchedule(
        r.id!,
        r.title,
        r.description.isNotEmpty ? r.description : 'Time for your reminder!',
        tz.TZDateTime.from(r.scheduledTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> _cancelNotification(int id) => _notifications.cancel(id);

  Future<void> _showAddReminderDialog() async {
    final newR = await showDialog<Reminder>(
      context: context,
      builder: (_) => const AddReminderDialog(),
    );
    if (newR != null) {
      final id = await ReminderDB().insertReminder(newR);
      newR.id = id;
      await _scheduleNotification(newR);
      _loadReminders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: FutureBuilder<List<Reminder>>(
        future: _remindersFuture,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text('No reminders yet.'));
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, i) {
              final r = list[i];
              final dt = r.scheduledTime.toLocal();
              final repeatText = r.isRepeating ? ' (repeats)' : '';
              return ListTile(
                title: Text(r.title),
                subtitle: Text(
                  '${r.description}\n'
                  '${dt.toString()}$repeatText',
                ),
                isThreeLine: r.description.isNotEmpty,
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    await ReminderDB().deleteReminder(r.id!);
                    await _cancelNotification(r.id!);
                    _loadReminders();
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReminderDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddReminderDialog extends StatefulWidget {
  const AddReminderDialog({Key? key}) : super(key: key);
  @override
  State<AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<AddReminderDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _dateTime;
  bool _isRepeating = false;
  int _repeatInterval = Duration(days: 1).inMilliseconds;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() {
      _dateTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Reminder'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: Text(
                _dateTime == null
                    ? 'No date/time chosen'
                    : _dateTime.toString(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _pickDateTime,
            ),
          ]),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Repeat'),
            value: _isRepeating,
            onChanged: (v) => setState(() => _isRepeating = v),
          ),
          if (_isRepeating)
            DropdownButtonFormField<int>(
              value: _repeatInterval,
              decoration: const InputDecoration(labelText: 'Interval'),
              items: [
                DropdownMenuItem(
                  child: const Text('Daily'),
                  value: Duration(days: 1).inMilliseconds,
                ),
                DropdownMenuItem(
                  child: const Text('Weekly'),
                  value: Duration(days: 7).inMilliseconds,
                ),
              ],
              onChanged: (v) => setState(() => _repeatInterval = v!),
            ),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleCtrl.text.isEmpty || _dateTime == null) return;
            final r = Reminder(
              title: _titleCtrl.text,
              description: _descCtrl.text,
              scheduledTime: _dateTime!,
              isRepeating: _isRepeating,
              repeatInterval: _isRepeating ? _repeatInterval : null,
            );
            Navigator.pop(context, r);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
