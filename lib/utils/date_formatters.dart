import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

/// --- Helpers ---

/// Parse input which can be either:
/// - String (ISO date)
/// - int (millisecondsSinceEpoch)
DateTime _parseToDateTime(dynamic input) {
  if (input is int) {
    return DateTime.fromMillisecondsSinceEpoch(input);
  } else if (input is String) {
    return DateTime.parse(input);
  } else if (input is DateTime) {
    return input;
  } else {
    throw ArgumentError('Unsupported date format: $input');
  }
}

/// Replace English digits with Persian digits
String replaceEnglishNumbers(String input) {
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  for (int i = 0; i < english.length; i++) {
    input = input.replaceAll(english[i], persian[i]);
  }
  return input;
}

/// --- Gregorian Formatters ---

String formatDateTime(dynamic date) {
  final parsedDate = _parseToDateTime(date);
  return DateFormat('yyyy-MM-dd • hh:mm a', 'en').format(parsedDate);
}

String formatDate(dynamic date) {
  final parsedDate = _parseToDateTime(date);
  return DateFormat('yyyy-MM-dd', 'en').format(parsedDate);
}

/// --- Jalali Formatters ---

String formatJalaliDateTime(dynamic date) {
  final gregorianDate = _parseToDateTime(date);
  final jalaliDate = Jalali.fromDateTime(gregorianDate);

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

String formatJalaliDate(dynamic date) {
  final gregorianDate = _parseToDateTime(date);
  final jalaliDate = Jalali.fromDateTime(gregorianDate);
  String persianDate =
      '${jalaliDate.year}-${jalaliDate.month.toString().padLeft(2, '0')}-${jalaliDate.day.toString().padLeft(2, '0')}';
  return replaceEnglishNumbers(persianDate);
}

/// --- Localized Wrappers ---

String formatLocalizedDateTime(BuildContext context, dynamic date) {
  final localeCode = Localizations.localeOf(context).languageCode;
  if (localeCode.startsWith('en')) return formatDateTime(date);
  return formatJalaliDateTime(date);
}

String formatLocalizedDate(BuildContext context, dynamic date) {
  final localeCode = Localizations.localeOf(context).languageCode;
  if (localeCode.startsWith('en')) return formatDate(date);
  return formatJalaliDate(date);
}

String formatLocalizedDateShort(BuildContext context, dynamic date) {
  final parsedDate = _parseToDateTime(date);
  final locale = Localizations.localeOf(context).languageCode;
  if (locale.startsWith('en')) {
    return DateFormat.Md(locale).format(parsedDate);
  } else {
    final j = Jalali.fromDateTime(parsedDate);
    return replaceEnglishNumbers('${j.month}/${j.day}');
  }
}

String formatLocalizedMonthDay(BuildContext context, dynamic date) {
  final parsedDate = _parseToDateTime(date);
  final locale = Localizations.localeOf(context).languageCode;
  if (locale.startsWith('en')) {
    return DateFormat.MMMd(locale).format(parsedDate);
  } else {
    final j = Jalali.fromDateTime(parsedDate);
    final farsiMonth = j.formatter.mNAf; // Persian month name
    return '${replaceEnglishNumbers(j.day.toString())} $farsiMonth';
  }
}

String formatLocalizedYear(BuildContext context, dynamic date) {
  final parsedDate = _parseToDateTime(date);
  final locale = Localizations.localeOf(context).languageCode;
  if (locale.startsWith('en')) {
    return DateFormat.y(locale).format(parsedDate);
  } else {
    final j = Jalali.fromDateTime(parsedDate);
    return replaceEnglishNumbers(j.year.toString());
  }
}
