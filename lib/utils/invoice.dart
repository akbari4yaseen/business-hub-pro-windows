import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/invoice.dart';

extension InvoiceStatusExtension on InvoiceStatus {
  String localizedName(AppLocalizations loc) {
    switch (this) {
      case InvoiceStatus.draft:
        return loc.invoiceStatusDraft;
      case InvoiceStatus.finalized:
        return loc.invoiceStatusFinalized;
      case InvoiceStatus.partiallyPaid:
        return loc.invoiceStatusPartiallyPaid;
      case InvoiceStatus.paid:
        return loc.invoiceStatusPaid;
      case InvoiceStatus.cancelled:
        return loc.invoiceStatusCancelled;
    }
  }
}
