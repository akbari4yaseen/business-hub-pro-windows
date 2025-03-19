import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

String getCurrencyName(String currency) {
  const Map<String, String> currencyNames = {
    'USD': 'دالر',
    'TRY': 'لیره ترکیه',
    'SAR': 'ریال سعودی',
    'PKR': 'کلدار پاکستانی',
    'IRR': 'تومان',
    'INR': 'کلدار هندی',
    'GBP': 'پوند',
    'EUR': 'یورو',
    'CNY': 'ین چین',
    'CAD': 'دالر کانادایی',
    'AUD': 'دالر استرالیایی',
    'AFN': 'افغانی',
    'AED': 'درهم امارات',
    'MYR': 'رینگیت مالزی',
  };

  return currencyNames[currency] ?? currency;
}

String getLocalizedAccountType(BuildContext context, String type) {
  final localizations = AppLocalizations.of(context)!;

  switch (type) {
    case 'system':
      return localizations.system;
    case 'customer':
      return localizations.customer;
    case 'exchanger':
      return localizations.exchanger;
    case 'supplier':
      return localizations.supplier;
    default:
      return type; // Fallback in case of missing translation
  }
}

String getLocalizedSystemAccountName(BuildContext context, String type) {
  final localizations = AppLocalizations.of(context)!;

  switch (type) {
    case 'treasure':
      return localizations.treasure;
    case 'noTreasure':
      return localizations.noTreasure;
    case 'asset':
      return localizations.asset;
    case 'profit':
      return localizations.profit;
    case 'loss':
      return localizations.loss;
    case 'expenses':
      return localizations.expenses;
    default:
      return type; // Fallback in case of missing translation
  }
}

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
