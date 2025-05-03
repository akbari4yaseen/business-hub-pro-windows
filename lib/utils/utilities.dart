import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';

const Map<String, Map<String, String>> localizedCurrencyNames = {
  "AFN": {"en": "Afghani", "fa": "افغانی", "ps": "افغانۍ"},
  "USD": {"en": "US Dollar", "fa": "دالر آمریکا", "ps": "د امریکې ډالر"},
  "EUR": {"en": "Euro", "fa": "یورو", "ps": "یورو"},
  "PKR": {
    "en": "Pakistani Rupee",
    "fa": "روپیه پاکستان",
    "ps": "پاکستانۍ روپۍ"
  },
  "IRR": {"en": "Iranian Toman", "fa": "تومان ایران", "ps": "ایران تومان"},
  "TRY": {"en": "Turkish Lira", "fa": "لیر ترکیه", "ps": "ترک لیره"},
  "SAR": {"en": "Saudi Riyal", "fa": "ریال سعودی", "ps": "سعودي ریال"},
  "INR": {"en": "Indian Rupee", "fa": "روپیه هند", "ps": "هندي روپۍ"},
  "GBP": {"en": "British Pound", "fa": "پوند انگلیس", "ps": "برتانوي پونډ"},
  "CNY": {"en": "Chinese Yuan", "fa": "یوان چین", "ps": "چینایي یوان"},
  "CAD": {"en": "Canadian Dollar", "fa": "دالر کانادا", "ps": "د کاناډا ډالر"},
  "AUD": {
    "en": "Australian Dollar",
    "fa": "دالر استرالیا",
    "ps": "استرالیایي ډالر"
  },
  "AED": {"en": "Emirati Dirham", "fa": "درهم امارات", "ps": "د اماراتو درهم"},
  "MYR": {
    "en": "Malaysian Ringgit",
    "fa": "رینگیت مالزی",
    "ps": "مالیزیایي رینګت"
  }
};

String getLocalizedAccountType(BuildContext context, String type) {
  final localizations = AppLocalizations.of(context)!;

  switch (type) {
    case 'system':
      return localizations.system;
    case 'customer':
      return localizations.customer;
    case 'exchanger':
      return localizations.exchanger;
    case 'bank':
      return localizations.bank;
    case 'supplier':
      return localizations.supplier;
    case 'income':
      return localizations.income;
    case 'expense':
      return localizations.expense;
    case 'owner':
      return localizations.owner;
    case 'company':
      return localizations.company;
    case 'all':
      return localizations.all;
    default:
      return type; // Fallback in case of missing translation
  }
}

String getLocalizedSystemAccountName(BuildContext context, String name) {
  final localizations = AppLocalizations.of(context)!;

  switch (name) {
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
    default:
      return name; // Fallback in case of missing translation
  }
}

String getLocalizedTxType(BuildContext context, String type) {
  final localizations = AppLocalizations.of(context)!;

  switch (type) {
    case 'all':
      return localizations.all;
    case 'credit':
      return localizations.credit;
    case 'debit':
      return localizations.debit;
    default:
      return type; // Fallback in case of missing translation
  }
}

String getLocalizedAccountName(
    BuildContext context, int accountId, String? fallbackName) {
  final localizations = AppLocalizations.of(context)!;
  switch (accountId) {
    case 1:
      return localizations.treasure;
    case 2:
      return localizations.noTreasure;
    case 3:
      return localizations.asset;
    case 9:
      return localizations.profit;
    case 10:
      return localizations.loss;

    default:
      return fallbackName ?? '';
  }
}
