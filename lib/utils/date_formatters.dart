import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

/// Format full date + time (like: 2025-06-23 • 04:30 PM)
String formatDateTime(String date) {
  DateTime parsedDate = DateTime.parse(date);
  return DateFormat('yyyy-MM-dd • hh:mm a', 'en').format(parsedDate);
}

String formatDate(String date) {
  DateTime parsedDate = DateTime.parse(date);
  return DateFormat('yyyy-MM-dd', 'en').format(parsedDate);
}

String formatJalaliDateTime(String date) {
  DateTime gregorianDate = DateTime.parse(date);
  Jalali jalaliDate = Jalali.fromDateTime(gregorianDate);

  int hour =
      gregorianDate.hour > 12 ? gregorianDate.hour - 12 : gregorianDate.hour;
  hour = hour == 0 ? 12 : hour;
  String period = gregorianDate.hour >= 12 ? "ب.ظ" : "ق.ظ";
  String minute = gregorianDate.minute.toString().padLeft(2, '0');

  String persianDate =
      '${jalaliDate.year}-${jalaliDate.month.toString().padLeft(2, '0')}-${jalaliDate.day.toString().padLeft(2, '0')}';
  String persianTime = '$hour:$minute $period';

  return '${replaceEnglishNumbers(persianDate)} • ${replaceEnglishNumbers(persianTime)}';
}

String formatJalaliDate(String date) {
  DateTime gregorianDate = DateTime.parse(date);
  Jalali jalaliDate = Jalali.fromDateTime(gregorianDate);
  String persianDate =
      '${jalaliDate.year}-${jalaliDate.month.toString().padLeft(2, '0')}-${jalaliDate.day.toString().padLeft(2, '0')}';
  return replaceEnglishNumbers(persianDate);
}

String replaceEnglishNumbers(String input) {
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  for (int i = 0; i < english.length; i++) {
    input = input.replaceAll(english[i], persian[i]);
  }
  return input;
}

/// Localized full date + time
String formatLocalizedDateTime(BuildContext context, String date) {
  final localeCode = Localizations.localeOf(context).languageCode;
  if (localeCode.startsWith('en')) return formatDateTime(date);
  return formatJalaliDateTime(date);
}

/// Localized date only
String formatLocalizedDate(BuildContext context, String date) {
  final localeCode = Localizations.localeOf(context).languageCode;
  if (localeCode.startsWith('en')) return formatDate(date);
  return formatJalaliDate(date);
}

/// Localized short day/month (like 6/23 or ۲/۳)
String formatLocalizedDateShort(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale.startsWith('en')) {
    return DateFormat.Md(locale).format(date);
  } else {
    final j = Jalali.fromDateTime(date);
    return replaceEnglishNumbers('${j.month}/${j.day}');
  }
}

/// Localized month + day (e.g., Jun 23 or حمل ۳)
String formatLocalizedMonthDay(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale.startsWith('en')) {
    return DateFormat.MMMd(locale).format(date);
  } else {
    final j = Jalali.fromDateTime(date);
    final farsiMonth = j.formatter.mNAf; // Month name in Persian
    return '${replaceEnglishNumbers(j.day.toString())} $farsiMonth';
  }
}

/// Localized year (e.g., 2025 or ۱۴۰۳)
String formatLocalizedYear(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale.startsWith('en')) {
    return DateFormat.y(locale).format(date);
  } else {
    final j = Jalali.fromDateTime(date);
    return replaceEnglishNumbers(j.year.toString());
  }
}
