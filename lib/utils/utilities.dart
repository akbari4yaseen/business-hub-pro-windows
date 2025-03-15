import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';

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
