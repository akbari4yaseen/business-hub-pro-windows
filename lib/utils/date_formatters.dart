import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

String formatDateTime(String date) {
  DateTime parsedDate = DateTime.parse(date);
  return DateFormat('yyyy-MM-dd | hh:mm a', 'en').format(parsedDate);
}

String formatJalaliDate(String date) {
  DateTime gregorianDate = DateTime.parse(date);
  Jalali jalaliDate = Jalali.fromDateTime(gregorianDate);

  // Convert 24-hour format to 12-hour format with AM/PM
  int hour =
      gregorianDate.hour > 12 ? gregorianDate.hour - 12 : gregorianDate.hour;
  hour = hour == 0 ? 12 : hour; // Convert 00:00 to 12:00 AM
  String period = gregorianDate.hour >= 12 ? "ب.ظ" : "ق.ظ"; // Persian AM/PM
  String minute = gregorianDate.minute.toString().padLeft(2, '0');

  // Convert English numbers to Persian numbers
  String persianDate =
      '${jalaliDate.year}-${jalaliDate.month.toString().padLeft(2, '0')}-${jalaliDate.day.toString().padLeft(2, '0')}';
  String persianTime = '$hour:$minute $period';

  return '${replaceEnglishNumbers(persianDate)} | ${replaceEnglishNumbers(persianTime)}';
}

// Function to replace English digits with Persian digits
String replaceEnglishNumbers(String input) {
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

  for (int i = 0; i < english.length; i++) {
    input = input.replaceAll(english[i], persian[i]);
  }
  return input;
}

String formatLocalizedDate(BuildContext context, String date) {
  final localeCode = Localizations.localeOf(context).languageCode;
  if (localeCode.startsWith('fa')) {
    return formatJalaliDate(date);
  }
  return formatDateTime(date);
}

/// Extension on DateTime to simplify localized formatting directly on the object.
extension LocalizedDateExtension on String {
  /// Formats this date according to the current locale in [context].
  String localized(BuildContext context) => formatLocalizedDate(context, this);
}
