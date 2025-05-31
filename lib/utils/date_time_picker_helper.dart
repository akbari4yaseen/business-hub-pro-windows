import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:intl/intl.dart';

Future<DateTime?> pickLocalizedDateTime({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  final locale = Localizations.localeOf(context);
  DateTime? date;

  final DateTime resolvedFirstDate = firstDate ?? DateTime(2000);
  final DateTime resolvedLastDate =
      lastDate ?? DateTime.now().add(Duration(days: 2));

  if (locale.languageCode == 'fa') {
    final j = await showPersianDatePicker(
      context: context,
      initialDate: Jalali.fromDateTime(initialDate),
      firstDate: Jalali.fromDateTime(resolvedFirstDate),
      lastDate: Jalali.fromDateTime(resolvedLastDate),
    );
    if (j == null) return null;
    date = j.toDateTime();
  } else {
    date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: resolvedFirstDate,
      lastDate: resolvedLastDate,
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

Future<DateTime?> pickLocalizedDate({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  final locale = Localizations.localeOf(context);

  final DateTime resolvedFirstDate = firstDate ?? DateTime(2000);
  final DateTime resolvedLastDate =
      lastDate ?? DateTime.now().add(Duration(days: 2));

  if (locale.languageCode == 'fa') {
    final j = await showPersianDatePicker(
      context: context,
      initialDate: Jalali.fromDateTime(initialDate),
      firstDate: Jalali.fromDateTime(resolvedFirstDate),
      lastDate: Jalali.fromDateTime(resolvedLastDate),
    );
    if (j == null) return null;
    return j.toDateTime();
  } else {
    return await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: resolvedFirstDate,
      lastDate: resolvedLastDate,
    );
  }
}

String formatLocalizedDateTime(BuildContext context, DateTime dateTime) {
  final locale = Localizations.localeOf(context);

  if (locale.languageCode == 'en') {
    return DateFormat.yMd().add_jm().format(dateTime);
  } else {
    final j = Jalali.fromDateTime(dateTime);
    final time = TimeOfDay.fromDateTime(dateTime);
    return '${j.formatCompactDate()} ${time.format(context)}';
  }
}
