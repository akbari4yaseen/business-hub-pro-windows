import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Map<String, String> getAccountTypes(AppLocalizations localizations) {
  return {
    'customer': localizations.customer,
    'supplier': localizations.supplier,
    'exchanger': localizations.exchanger,
    'bank': localizations.bank,
    'income': localizations.income,
    'expense': localizations.expense,
    'owner': localizations.owner,
  };
}
