import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../models/stock_movement.dart';

extension MovementTypeLocalization on MovementType {
  String localized(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case MovementType.stockIn:
        return l10n.movementType_stockIn;
      case MovementType.stockOut:
        return l10n.movementType_stockOut;
      case MovementType.transfer:
        return l10n.movementType_transfer;
    }
  }
}
