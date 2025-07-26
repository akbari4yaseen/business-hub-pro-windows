import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../models/reminder.dart';
import '../../utils/date_time_picker_helper.dart';
import '../../utils/date_formatters.dart' as dFormatter;

/// A Dialog widget for creating or editing a reminder.
class AddReminderDialog extends StatefulWidget {
  final Reminder? reminder;
  final ValueChanged<Reminder> onSave;

  const AddReminderDialog({Key? key, this.reminder, required this.onSave})
      : super(key: key);

  @override
  _AddReminderDialogState createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<AddReminderDialog> {
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
        _dateCtrl.text = dFormatter.formatLocalizedDateTime(
          context,
          _dateTime.toString(),
        );
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
    final initialDate =
        (_dateTime != null && _dateTime!.isAfter(now)) ? _dateTime! : now;

    final date = await pickLocalizedDateTime(
      context: context,
      initialDate: initialDate,
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
      _dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _dateCtrl.text = dFormatter.formatLocalizedDateTime(
        context,
        _dateTime.toString(),
      );
      _dateError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  widget.reminder == null
                      ? loc.newReminderTitle
                      : loc.editReminderTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleCtrl,
                  autofocus: true,
                  maxLength: 128,
                  decoration: InputDecoration(labelText: loc.titleLabel),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? loc.titleEmptyError
                      : null,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descCtrl,
                  maxLines: 4,
                  maxLength: 1024,
                  decoration: InputDecoration(labelText: loc.descriptionLabel),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _dateCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: loc.dateTimeLabel,
                    prefixIcon: const Icon(Icons.calendar_today),
                    errorText: _dateError,
                  ),
                  onTap: _pickDateTime,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text(loc.repeatLabel),
                  value: _isRepeating,
                  onChanged: (v) => setState(() => _isRepeating = v),
                ),
                if (_isRepeating)
                  DropdownButtonFormField<int>(
                    value: _repeatInterval,
                    decoration: InputDecoration(labelText: loc.intervalLabel),
                    items: [
                      DropdownMenuItem(
                        child: Text(loc.daily),
                        value: Duration(days: 1).inMilliseconds,
                      ),
                      DropdownMenuItem(
                        child: Text(loc.weekly),
                        value: Duration(days: 7).inMilliseconds,
                      ),
                    ],
                    onChanged: (v) => setState(() => _repeatInterval = v!),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(loc.cancel),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final form = _formKey.currentState!;
                          if (!form.validate()) return;
                          if (_dateTime == null) {
                            setState(() {
                              _dateError = loc.pickDateTimeError;
                            });
                            return;
                          }
                          final r = Reminder(
                            id: widget.reminder?.id,
                            title: _titleCtrl.text.trim(),
                            description: _descCtrl.text.trim(),
                            scheduledTime: _dateTime!,
                            isRepeating: _isRepeating,
                            repeatInterval:
                                _isRepeating ? _repeatInterval : null,
                          );
                          widget.onSave(r); // This will close the dialog and return the reminder
                        },
                        child: Text(loc.save),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
