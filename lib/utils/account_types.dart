import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Returns a localized map of account types.
Map<String, String> getAccountTypes(AppLocalizations localizations) => {
      'customer': localizations.customer,
      'supplier': localizations.supplier,
      'exchanger': localizations.exchanger,
      'bank': localizations.bank,
      'income': localizations.income,
      'expense': localizations.expense,
      'owner': localizations.owner,
      'company': localizations.company,
      'employee': localizations.employee,
    };

/// A constant map of account type colors.
const Map<String, Color> getAccountTypeColors = {
  'system': Colors.pink,
  'customer': Colors.blue,
  'supplier': Colors.orange,
  'exchanger': Colors.teal,
  'bank': Colors.indigo,
  'income': Colors.green,
  'expense': Colors.red,
  'company': Colors.brown,
  'owner': Colors.lime,
  'employee': Colors.amber,
};
