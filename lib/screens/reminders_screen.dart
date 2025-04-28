import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

import '../models/reminder.dart';
import '../database/reminder_db.dart';
import '../utils/date_formatters.dart';

enum _MenuOption { edit, delete }

/// Centralized notification service for initialization and scheduling
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const _channel = AndroidNotificationChannel(
    'reminders_channel',
    'Reminders',
    description: 'Reminder notifications',
    importance: Importance.max,
  );

  Future<void> init() async {
    tz.initializeTimeZones();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(_channel);
      final granted = await android.requestNotificationsPermission();
      if (granted == false) debugPrint('Notification permission declined');
    }
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  Future<void> schedule(Reminder r) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        icon: 'ic_stat_notify',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
    final scheduled = tz.TZDateTime.from(r.scheduledTime, tz.local);

    if (r.isRepeating && r.repeatInterval != null) {
      final match = r.repeatInterval == Duration(days: 7).inMilliseconds
          ? DateTimeComponents.dayOfWeekAndTime
          : DateTimeComponents.time;
      await _plugin.zonedSchedule(
        r.id!,
        r.title,
        r.description.isNotEmpty ? r.description : 'Time for your reminder!',
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: match,
      );
    } else {
      if (r.scheduledTime.isBefore(DateTime.now())) return;
      await _plugin.zonedSchedule(
        r.id!,
        r.title,
        r.description.isNotEmpty ? r.description : 'Time for your reminder!',
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> cancel(int id) => _plugin.cancel(id);
}

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({Key? key}) : super(key: key);
  @override
  _RemindersScreenState createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<Reminder> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    NotificationService.instance.init();
    _fetchReminders();
  }

  Future<void> _fetchReminders() async {
    setState(() => _isLoading = true);
    final items = await ReminderDB().getReminders();
    setState(() {
      _reminders = items;
      _isLoading = false;
    });
  }

  Future<void> _addReminder(Reminder r) async {
    final id = await ReminderDB().insertReminder(r);
    r.id = id;
    await NotificationService.instance.schedule(r);
    await _fetchReminders();
  }

  Future<void> _updateReminder(Reminder r) async {
    await ReminderDB().updateReminder(r);
    await NotificationService.instance.cancel(r.id!);
    await NotificationService.instance.schedule(r);
    await _fetchReminders();
  }

  Future<void> _confirmDelete(Reminder r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: const Text('Are you sure you want to delete this reminder?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await ReminderDB().deleteReminder(r.id!);
      await NotificationService.instance.cancel(r.id!);
      await _fetchReminders();
    }
  }

  Future<void> _showAddSheet({Reminder? existing}) async {
    final newR = await showModalBottomSheet<Reminder>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: AddReminderSheet(
          reminder: existing,
          onSave: (r) => Navigator.pop(context, r),
        ),
      ),
    );
    if (newR != null) {
      if (existing == null) {
        await _addReminder(newR);
      } else {
        newR.id = existing.id;
        await _updateReminder(newR);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchReminders,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _reminders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.notifications_off, size: 64),
                        SizedBox(height: 16),
                        Text('No reminders yet!',
                            style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _reminders.length,
                    itemBuilder: (ctx, i) {
                      final r = _reminders[i];
                      final timeStr = DateFormat('MMM dd, yyyy – hh:mm a')
                          .format(r.scheduledTime.toLocal());
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(r.title,
                              style: const TextStyle(fontSize: 18)),
                          subtitle: Text(
                            '${r.description.isNotEmpty ? r.description + '\n' : ''}'
                            '$timeStr${r.isRepeating ? ' • Repeats' : ''}',
                          ),
                          trailing: PopupMenuButton<_MenuOption>(
                            onSelected: (opt) {
                              switch (opt) {
                                case _MenuOption.edit:
                                  _showAddSheet(existing: r);
                                  break;
                                case _MenuOption.delete:
                                  _confirmDelete(r);
                                  break;
                              }
                            },
                            itemBuilder: (ctx) => <PopupMenuEntry<_MenuOption>>[
                              const PopupMenuItem(
                                value: _MenuOption.edit,
                                child: ListTile(
                                  leading: Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  title: Text('Edit'),
                                ),
                              ),
                              const PopupMenuItem(
                                value: _MenuOption.delete,
                                child: ListTile(
                                  leading: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  title: Text('Delete'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddReminderSheet extends StatefulWidget {
  final Reminder? reminder;
  final ValueChanged<Reminder> onSave;
  const AddReminderSheet({this.reminder, required this.onSave, Key? key})
      : super(key: key);
  @override
  _AddReminderSheetState createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<AddReminderSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late final TextEditingController _dateCtrl;
  DateTime? _dateTime;
  String? _dateError;
  bool _isRepeating = false;
  int _repeatInterval = Duration(days: 1).inMilliseconds;

  @override
  void initState() {
    super.initState();
    final r = widget.reminder;

    _titleCtrl = TextEditingController(text: r?.title ?? '');
    _descCtrl = TextEditingController(text: r?.description ?? '');
    _dateCtrl = TextEditingController();

    if (r != null) {
      _dateTime = r.scheduledTime;
      _isRepeating = r.isRepeating;
      _repeatInterval = r.repeatInterval ?? _repeatInterval;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _dateCtrl.text = formatLocalizedDateTime(context, _dateTime.toString());
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _dateTime != null
          ? TimeOfDay.fromDateTime(_dateTime!)
          : TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _dateTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _dateCtrl.text = formatLocalizedDateTime(context, _dateTime.toString());
      _dateError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(widget.reminder == null ? 'New Reminder' : 'Edit Reminder',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleCtrl,
              autofocus: true,
              maxLength: 128,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (val) => (val == null || val.trim().isEmpty)
                  ? 'Please enter a title'
                  : null,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              maxLength: 512,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dateCtrl,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Date & Time',
                prefixIcon: const Icon(Icons.calendar_today),
                errorText: _dateError,
              ),
              onTap: _pickDateTime,
            ),
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
                      value: Duration(days: 1).inMilliseconds),
                  DropdownMenuItem(
                      child: const Text('Weekly'),
                      value: Duration(days: 7).inMilliseconds),
                ],
                onChanged: (v) => setState(() => _repeatInterval = v!),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final form = _formKey.currentState!;
                      if (!form.validate()) return;
                      if (_dateTime == null) {
                        setState(() {
                          _dateError = 'Please pick date & time';
                        });
                        return;
                      }
                      final r = Reminder(
                        id: widget.reminder?.id,
                        title: _titleCtrl.text.trim(),
                        description: _descCtrl.text.trim(),
                        scheduledTime: _dateTime!,
                        isRepeating: _isRepeating,
                        repeatInterval: _isRepeating ? _repeatInterval : null,
                      );
                      widget.onSave(r);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
