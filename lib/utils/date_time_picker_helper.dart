import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:intl/intl.dart';

/// A utility function that shows a localized date and time picker.
/// Returns `null` if the user cancels.
Future<DateTime?> pickLocalizedDateTime({
  required BuildContext context,
  required DateTime initialDate,
}) async {
  final locale = Localizations.localeOf(context);
  DateTime? date;

  if (locale.languageCode == 'fa') {
    final j = await showPersianDatePicker(
      context: context,
      initialDate: Jalali.fromDateTime(initialDate),
      firstDate: Jalali(1390, 1),
      lastDate: Jalali.fromDateTime(DateTime.now().add(Duration(days: 2))),
    );
    if (j == null) return null;
    date = j.toDateTime();
  } else {
    date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(Duration(days: 2)),
    );
    if (date == null) return null;
  }

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initialDate),
  );
  if (time == null) return null;

  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

String formatLocalizedDateTime(BuildContext context, DateTime dateTime) {
  final locale = Localizations.localeOf(context);

  if (locale.languageCode == 'fa') {
    final j = Jalali.fromDateTime(dateTime);
    final time = TimeOfDay.fromDateTime(dateTime);
    return '${j.formatCompactDate()} ${time.format(context)}';
  } else {
    return DateFormat.yMd().add_jm().format(dateTime);
  }
}
