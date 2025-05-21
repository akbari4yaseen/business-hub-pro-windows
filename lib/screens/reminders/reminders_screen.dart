import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../themes/app_theme.dart';

import 'add_reminder_sheet.dart';
import '../../models/reminder.dart';
import '../../database/reminder_db.dart';
import '../../widgets/search_bar.dart';
import '../../utils/date_formatters.dart';

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

    final body = r.description.isNotEmpty ? r.description : '';

    if (r.isRepeating && r.repeatInterval != null) {
      final match = r.repeatInterval == Duration(days: 7).inMilliseconds
          ? DateTimeComponents.dayOfWeekAndTime
          : DateTimeComponents.time;
      await _plugin.zonedSchedule(
        r.id!,
        r.title,
        body,
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
        body,
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
  List<Reminder> _filteredReminders = [];
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

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
      _applySearch(_searchController.text);
      _isLoading = false;
    });
  }

  void _applySearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredReminders = List.from(_reminders);
      });
      return;
    }
    setState(() {
      _filteredReminders = _reminders
          .where((r) =>
              r.title.toLowerCase().contains(query.toLowerCase()) ||
              r.description.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _addReminder(Reminder r) async {
    final id = await ReminderDB().insertReminder(r);
    r.id = id;
    await NotificationService.instance.schedule(r);
    await _fetchReminders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateReminder(Reminder r) async {
    await ReminderDB().updateReminder(r);
    await NotificationService.instance.cancel(r.id!);
    await NotificationService.instance.schedule(r);
    await _fetchReminders();
  }

  Future<void> _confirmDelete(Reminder r) async {
    final loc = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.deleteReminderTitle),
        content: Text(loc.deleteReminderConfirmation),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(loc.cancel)),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(loc.delete)),
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
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? CommonSearchBar(
                controller: _searchController,
                debounceDuration: const Duration(milliseconds: 400),
                isLoading: _isLoading,
                onChanged: (query) => _applySearch(query),
                onSubmitted: (query) => _applySearch(query),
                onCancel: () {
                  _isSearching = false;
                  _searchController.clear();
                  _applySearch('');
                },
                hintText: loc.search,
              )
            : Text(loc.remindersTitle),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _isSearching = true),
              tooltip: loc.search,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchReminders,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _filteredReminders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.alarm_off, size: 64),
                        const SizedBox(height: 16),
                        Text(loc.noRemindersYet,
                            style: const TextStyle(fontSize: 18)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredReminders.length,
                    itemBuilder: (ctx, i) {
                      final r = _filteredReminders[i];
                      final timeStr = formatLocalizedDateTime(
                          context, r.scheduledTime.toString());
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
                            '$timeStr${r.isRepeating ? ' • ${loc.repeats}' : ''}',
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
                              PopupMenuItem(
                                value: _MenuOption.edit,
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.edit,
                                    color: AppTheme.primaryColor,
                                  ),
                                  title: Text(loc.edit),
                                ),
                              ),
                              PopupMenuItem(
                                value: _MenuOption.delete,
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  title: Text(loc.delete),
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
        heroTag: 'reminders_add_fab',
        onPressed: () => _showAddSheet(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
